// StrudelPlayer.swift — plays patterns through the speaker.
// The Swift equivalent of strudel's webaudio output: a Cyclist scheduler
// feeding sample-accurately scheduled buffers into AVAudioEngine.
// — AGPL-3.0-or-later.

import AVFoundation
import Foundation
import StrudelCore

/// Plays a strudel `Pattern` in real time (looping forever, like the REPL),
/// or renders it offline to PCM.
public final class StrudelPlayer: @unchecked Sendable {
    private let engine = AVAudioEngine()
    private let format: AVAudioFormat
    public let sampleRate: Double

    /// Pool of players for polyphonic voice scheduling. `inUse` is FIFO so
    /// the oldest voice can be stolen when the pool is exhausted.
    private var pool: [AVAudioPlayerNode] = []
    private var available: [AVAudioPlayerNode] = []
    private var inUse: [ObjectIdentifier: AVAudioPlayerNode] = [:]
    private var inUseOrder: [ObjectIdentifier] = []
    private let poolLock = NSLock()

    private var cyclist: Cyclist?
    /// Anchor pair taken from a valid render time at start: maps scheduler
    /// seconds to BOTH the host clock (for player scheduling) and the output
    /// sample timeline (for orbit ring writes) — one clock for everything.
    private var anchorHostTime: UInt64 = 0
    private var anchorSampleTime: AVAudioFramePosition = 0
    private var startHostSeconds: Double = 0

    /// mach host ticks per second (for host-time scheduling).
    private static let hostTicksPerSecond: Double = {
        var info = mach_timebase_info_data_t()
        mach_timebase_info(&info)
        return 1_000_000_000 * Double(info.denom) / Double(info.numer)
    }()

    /// LRU cache of rendered hap buffers — loops repeat the same haps every
    /// cycle, so steady-state scheduling costs ~nothing after cycle one.
    private var renderCache: [String: (buffer: AVAudioPCMBuffer, rendered: RenderedHap)] = [:]
    private var renderCacheOrder: [String] = []
    private let renderCacheLock = NSLock()
    private let renderCacheLimit = 192

    /// Shared per-orbit delay/reverb buses (superdough orbits).
    private var orbits: [Int: OrbitBus] = [:]
    private let orbitLock = NSLock()

    public init(sampleRate: Double = 44_100, voices: Int = 64) {
        self.sampleRate = sampleRate
        self.format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!
        for _ in 0..<voices {
            let node = AVAudioPlayerNode()
            engine.attach(node)
            engine.connect(node, to: engine.mainMixerNode, format: format)
            pool.append(node)
        }
        available = pool
        // Pre-create the default orbits so playback never reconfigures the
        // graph mid-stream; others attach lazily.
        _ = orbitBus(1)
        _ = orbitBus(2)
    }

    /// The shared effect buses for an orbit, created on demand.
    private func orbitBus(_ orbit: Int) -> OrbitBus {
        orbitLock.lock(); defer { orbitLock.unlock() }
        if let bus = orbits[orbit] { return bus }
        let bus = OrbitBus(orbit: orbit, sampleRate: sampleRate)
        engine.attach(bus.sourceNode)
        engine.connect(bus.sourceNode, to: engine.mainMixerNode, format: format)
        orbits[orbit] = bus
        return bus
    }

    // MARK: - Real-time playback

    /// Starts playing the pattern at the given tempo (cycles per second).
    public func play(_ pattern: StrudelCore.Pattern, cps: Double = 0.5) throws {
        hush()
        try startEngine()
        try captureAnchor()
        startHostSeconds = now()

        let cyclist = Cyclist(
            getTime: { [weak self] in (self?.now() ?? 0) - (self?.startHostSeconds ?? 0) },
            onTrigger: { [weak self] hap, _, duration, cps, targetTime in
                self?.trigger(hap: hap, duration: duration, cps: cps, targetTime: targetTime)
            }
        )
        cyclist.setCps(cps)
        cyclist.setPattern(pattern)
        self.cyclist = cyclist
        cyclist.start()
    }

    /// Swaps the playing pattern without stopping the clock.
    public func setPattern(_ pattern: StrudelCore.Pattern) {
        cyclist?.setPattern(pattern)
    }

    /// Master output volume (0–1) on the engine's main mixer.
    public var volume: Double {
        get { Double(engine.mainMixerNode.outputVolume) }
        set { engine.mainMixerNode.outputVolume = Float(min(max(newValue, 0), 1)) }
    }

    public func setCps(_ cps: Double) {
        cyclist?.setCps(cps)
    }

    public var isPlaying: Bool { cyclist?.started ?? false }

    /// Stops the scheduler (started players ring out).
    public func stop() {
        cyclist?.stop()
        cyclist = nil
    }

    /// Stops everything immediately: scheduler, every voice (including
    /// buffers scheduled but not yet started), and the orbit buses' pending
    /// send audio + effect state. Only audio already played decays naturally.
    public func hush() {
        stop()
        poolLock.lock()
        let playing = Array(inUse.values)
        inUse.removeAll()
        inUseOrder.removeAll()
        available = pool
        poolLock.unlock()
        for node in playing { node.stop() }
        orbitLock.lock()
        let buses = Array(orbits.values)
        orbitLock.unlock()
        for bus in buses { bus.clear() }
    }

    /// Fires a single hap value right now (GUI keyboard, one-shots).
    public func playOnce(_ value: PatternValue, duration: Double = 0.5) {
        try? startEngine()
        guard let rendered = HapRenderer.render(value: value, duration: duration,
                                                cps: cyclist?.currentCps ?? 0.5,
                                                sampleRate: sampleRate),
              let buffer = makeBuffer(rendered) else { return }
        if rendered.delaySend != nil || rendered.reverbSend != nil,
           let now = engine.mainMixerNode.lastRenderTime?.sampleTime {
            orbitBus(rendered.orbit).write(
                delaySend: rendered.delaySend,
                reverbSend: rendered.reverbSend,
                atSample: Int64(now) + Int64(0.05 * sampleRate),
                delayTime: rendered.delayTime,
                delayFeedback: rendered.delayFeedback,
                roomSize: rendered.roomSize
            )
        }
        guard let node = takeNode() else { return }
        node.scheduleBuffer(buffer, at: nil) { [weak self] in self?.returnNode(node) }
        node.play()
    }

    private func trigger(hap: Hap, duration: Double, cps: Double, targetTime: Double) {
        // custom triggers (.onTrigger/.log); dominant ones suppress audio
        if let custom = hap.context.onTrigger {
            custom(hap, 0, duration, cps, targetTime)
            if hap.context.dominantTrigger == true { return }
        }
        guard let (buffer, rendered) = renderedBuffer(value: hap.value, duration: duration, cps: cps),
              let node = takeNode() else { return }

        // One clock for everything: player buffers on the host timeline, orbit
        // ring writes on the sample timeline, both from the same anchor pair.
        let sampleTime = anchorSampleTime + AVAudioFramePosition(targetTime * sampleRate)
        if rendered.delaySend != nil || rendered.reverbSend != nil {
            orbitBus(rendered.orbit).write(
                delaySend: rendered.delaySend,
                reverbSend: rendered.reverbSend,
                atSample: Int64(sampleTime),
                delayTime: rendered.delayTime,
                delayFeedback: rendered.delayFeedback,
                roomSize: rendered.roomSize
            )
        }
        let hostTime = anchorHostTime
            + UInt64(max(0, targetTime) * StrudelPlayer.hostTicksPerSecond)
        node.scheduleBuffer(buffer, at: AVAudioTime(hostTime: hostTime)) { [weak self] in
            self?.returnNode(node)
        }
        node.play()
    }

    var engineForTesting: AVAudioEngine { engine }

    func renderedBufferForTesting(value: PatternValue, duration: Double,
                                  cps: Double) -> (AVAudioPCMBuffer, RenderedHap)? {
        renderedBuffer(value: value, duration: duration, cps: cps)
    }

    /// Renders a hap's buffer, memoized on (value, duration, cps).
    private func renderedBuffer(value: PatternValue, duration: Double,
                                cps: Double) -> (AVAudioPCMBuffer, RenderedHap)? {
        let key = "\(value)|\(duration)|\(cps)"
        renderCacheLock.lock()
        if let hit = renderCache[key] {
            renderCacheLock.unlock()
            return hit
        }
        renderCacheLock.unlock()

        guard let rendered = HapRenderer.render(value: value, duration: duration,
                                                cps: cps, sampleRate: sampleRate),
              let buffer = makeBuffer(rendered) else { return nil }

        renderCacheLock.lock()
        if renderCache[key] == nil {
            renderCache[key] = (buffer, rendered)
            renderCacheOrder.append(key)
            if renderCacheOrder.count > renderCacheLimit {
                let evicted = renderCacheOrder.removeFirst()
                renderCache.removeValue(forKey: evicted)
            }
        }
        renderCacheLock.unlock()
        return (buffer, rendered)
    }

    // MARK: - Offline rendering

    /// Renders `cycles` cycles of the pattern to interleaved stereo PCM.
    /// This is pure DSP (no audio hardware) — used by the CLI and tests.
    public func renderOffline(_ pattern: StrudelCore.Pattern, cycles: Double, cps: Double = 0.5) -> ([Float], [Float]) {
        let haps = pattern.queryArc(Fraction(0.0), Fraction(cycles),
                                    controls: ["_cps": .number(cps)])
        let totalSeconds = cycles / cps
        let capacity = Int(totalSeconds * sampleRate) + Int(sampleRate * 6)
        var left = [Float](repeating: 0, count: capacity)
        var right = left
        var maxFrame = Int(totalSeconds * sampleRate)

        // Per-orbit send tracks + param-change events, processed through the
        // shared streaming effects after the dry pass (bus semantics).
        struct OrbitTrack {
            var delayTrack: [Float]
            var reverbTrack: [Float]
            var events: [(sample: Int, delayTime: Double?, feedback: Double?, size: Double?)] = []
            var used = false
        }
        var orbitTracks: [Int: OrbitTrack] = [:]

        for hap in haps where hap.hasOnset() {
            guard let whole = hap.whole else { continue }
            if let custom = hap.context.onTrigger {
                custom(hap, 0, hap.duration.doubleValue / cps, cps, whole.begin.doubleValue / cps)
                if hap.context.dominantTrigger == true { continue }
            }
            let onset = whole.begin.doubleValue / cps
            let duration = hap.duration.doubleValue / cps
            guard let rendered = HapRenderer.render(value: hap.value, duration: duration,
                                                    cps: cps, sampleRate: sampleRate) else { continue }
            let start = Int(onset * sampleRate)
            for i in 0..<rendered.frames {
                let j = start + i
                if j >= left.count { break }
                left[j] += rendered.left[i]
                right[j] += rendered.right[i]
                if j > maxFrame { maxFrame = j }
            }
            if rendered.delaySend != nil || rendered.reverbSend != nil {
                var track = orbitTracks[rendered.orbit]
                    ?? OrbitTrack(delayTrack: [Float](repeating: 0, count: capacity),
                                  reverbTrack: [Float](repeating: 0, count: capacity))
                track.used = true
                track.events.append((sample: start,
                                     delayTime: rendered.delaySend != nil ? rendered.delayTime : nil,
                                     feedback: rendered.delaySend != nil ? rendered.delayFeedback : nil,
                                     size: rendered.reverbSend != nil ? rendered.roomSize : nil))
                if let send = rendered.delaySend {
                    for i in send.indices where start + i < capacity {
                        track.delayTrack[start + i] += send[i]
                    }
                }
                if let send = rendered.reverbSend {
                    for i in send.indices where start + i < capacity {
                        track.reverbTrack[start + i] += send[i]
                    }
                }
                orbitTracks[rendered.orbit] = track
            }
        }

        // Run each orbit's sends through its shared buses, ringing out tails.
        if !orbitTracks.isEmpty {
            let tailFrames = Int(sampleRate * 5)
            maxFrame = min(max(maxFrame + tailFrames, maxFrame), capacity - 1)
            for (_, track) in orbitTracks where track.used {
                let delay = StreamingDelay(sampleRate: sampleRate)
                let reverbL = StreamingFreeverb(sampleRate: sampleRate)
                let reverbR = StreamingFreeverb(sampleRate: sampleRate, stereoSpread: 23)
                let events = track.events.sorted { $0.sample < $1.sample }
                var eventIndex = 0
                for i in 0..<capacity {
                    while eventIndex < events.count && events[eventIndex].sample <= i {
                        let e = events[eventIndex]
                        if let t = e.delayTime { delay.setTime(t) }
                        if let f = e.feedback { delay.feedback = f }
                        if let sz = e.size { reverbL.setSize(sz); reverbR.setSize(sz) }
                        eventIndex += 1
                    }
                    let delayed = delay.process(track.delayTrack[i])
                    let revL = reverbL.process(track.reverbTrack[i])
                    let revR = reverbR.process(track.reverbTrack[i])
                    left[i] += delayed + revL
                    right[i] += delayed + revR
                }
            }
        }
        let end = min(maxFrame + 1, left.count)
        return (Array(left[..<end]), Array(right[..<end]))
    }

    /// Renders the pattern offline and plays it back, blocking until done.
    /// The CLI uses this for exact, glitch-free output.
    public func renderAndPlay(_ pattern: StrudelCore.Pattern, cycles: Double, cps: Double = 0.5) throws {
        let (left, right) = renderOffline(pattern, cycles: cycles, cps: cps)
        guard !left.isEmpty,
              let buffer = AVAudioPCMBuffer(pcmFormat: format,
                                            frameCapacity: AVAudioFrameCount(left.count)) else { return }
        buffer.frameLength = AVAudioFrameCount(left.count)
        buffer.floatChannelData![0].update(from: left, count: left.count)
        buffer.floatChannelData![1].update(from: right, count: right.count)

        try startEngine()
        guard let node = takeNode() else { return }
        let finished = DispatchSemaphore(value: 0)
        node.scheduleBuffer(buffer, at: nil, options: [],
                            completionCallbackType: .dataPlayedBack) { _ in
            finished.signal()
        }
        node.play()
        finished.wait()
        returnNode(node)
    }

    /// Writes an offline render to a WAV file.
    public func renderToFile(_ pattern: StrudelCore.Pattern, cycles: Double, cps: Double = 0.5,
                             url: URL) throws {
        let (left, right) = renderOffline(pattern, cycles: cycles, cps: cps)
        let file = try AVAudioFile(forWriting: url, settings: [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: sampleRate,
            AVNumberOfChannelsKey: 2,
            AVLinearPCMBitDepthKey: 16,
        ])
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format,
                                            frameCapacity: AVAudioFrameCount(left.count)) else { return }
        buffer.frameLength = AVAudioFrameCount(left.count)
        buffer.floatChannelData![0].update(from: left, count: left.count)
        buffer.floatChannelData![1].update(from: right, count: right.count)
        try file.write(from: buffer)
    }

    // MARK: - Internals

    private func now() -> Double {
        Double(DispatchTime.now().uptimeNanoseconds) / 1_000_000_000
    }

    private func startEngine() throws {
        if !engine.isRunning {
            try engine.start()
        }
    }

    /// Waits (briefly) for the engine to produce a valid render time, then
    /// stores the (hostTime, sampleTime) anchor pair that maps scheduler
    /// second 0 onto both clocks.
    private func captureAnchor() throws {
        var renderTime: AVAudioTime? = engine.mainMixerNode.lastRenderTime
        var waited = 0.0
        while (renderTime == nil || renderTime?.isSampleTimeValid != true
               || renderTime?.isHostTimeValid != true), waited < 0.5 {
            usleep(5_000)
            waited += 0.005
            renderTime = engine.mainMixerNode.lastRenderTime
        }
        guard let rt = renderTime, rt.isSampleTimeValid, rt.isHostTimeValid else {
            throw NSError(domain: "StrudelPlayer", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "audio engine produced no render time",
            ])
        }
        anchorHostTime = rt.hostTime
        anchorSampleTime = rt.sampleTime
    }

    private func makeBuffer(_ rendered: RenderedHap) -> AVAudioPCMBuffer? {
        guard rendered.frames > 0,
              let buffer = AVAudioPCMBuffer(pcmFormat: format,
                                            frameCapacity: AVAudioFrameCount(rendered.frames)) else {
            return nil
        }
        buffer.frameLength = AVAudioFrameCount(rendered.frames)
        buffer.floatChannelData![0].update(from: rendered.left, count: rendered.frames)
        buffer.floatChannelData![1].update(from: rendered.right, count: rendered.frames)
        return buffer
    }

    private func takeNode() -> AVAudioPlayerNode? {
        poolLock.lock()
        if let node = available.popLast() {
            let id = ObjectIdentifier(node)
            inUse[id] = node
            inUseOrder.append(id)
            poolLock.unlock()
            return node
        }
        // Pool exhausted: steal the oldest playing voice rather than
        // dropping the new note.
        guard let oldestId = inUseOrder.first, let node = inUse[oldestId] else {
            poolLock.unlock()
            return nil
        }
        inUseOrder.removeFirst()
        inUseOrder.append(oldestId)
        poolLock.unlock()
        node.stop()
        return node
    }

    private func returnNode(_ node: AVAudioPlayerNode) {
        poolLock.lock(); defer { poolLock.unlock() }
        let id = ObjectIdentifier(node)
        guard inUse.removeValue(forKey: id) != nil else { return }
        inUseOrder.removeAll { $0 == id }
        available.append(node)
    }
}
