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

    /// Pool of players for polyphonic voice scheduling.
    private var pool: [AVAudioPlayerNode] = []
    private var available: [AVAudioPlayerNode] = []
    private let poolLock = NSLock()

    private var cyclist: Cyclist?
    /// Host-time anchor mapping scheduler seconds → engine sample time.
    private var anchorSampleTime: AVAudioFramePosition = 0
    private var startHostSeconds: Double = 0

    /// Shared per-orbit delay/reverb buses (superdough orbits).
    private var orbits: [Int: OrbitBus] = [:]
    private let orbitLock = NSLock()

    public init(sampleRate: Double = 44_100, voices: Int = 48) {
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
        stop()
        try startEngine()

        startHostSeconds = now()
        anchorSampleTime = engine.mainMixerNode.lastRenderTime?.sampleTime ?? 0

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

    /// Stops everything immediately.
    public func hush() {
        stop()
        for node in pool { node.stop() }
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
        guard let rendered = HapRenderer.render(value: hap.value, duration: duration,
                                                cps: cps, sampleRate: sampleRate),
              let buffer = makeBuffer(rendered) else { return }
        guard let node = takeNode() else { return }

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
        let when = AVAudioTime(sampleTime: sampleTime, atRate: sampleRate)
        node.scheduleBuffer(buffer, at: when) { [weak self] in self?.returnNode(node) }
        node.play()
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
            anchorSampleTime = engine.mainMixerNode.lastRenderTime?.sampleTime ?? 0
        }
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
        poolLock.lock(); defer { poolLock.unlock() }
        return available.popLast()
    }

    private func returnNode(_ node: AVAudioPlayerNode) {
        poolLock.lock(); defer { poolLock.unlock() }
        available.append(node)
    }
}
