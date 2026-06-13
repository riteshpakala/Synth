import AVFoundation
import Foundation

/// Plays a `Pattern` through the default output device (the speaker).
///
/// The pattern is rendered offline to a single PCM buffer, then scheduled on an
/// `AVAudioPlayerNode`. Use `play(_:)` for fire-and-forget playback (the GUI),
/// or `playAndWait(_:)` to block until the sound finishes (the CLI).
public final class SequencePlayer {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let format: AVAudioFormat
    private let synthesizer: Synthesizer

    public init(sampleRate: Double = 44_100) {
        self.synthesizer = Synthesizer(sampleRate: sampleRate)
        self.format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
    }

    /// Renders the pattern into an audio buffer, or `nil` if it's empty.
    private func makeBuffer(for pattern: Pattern) -> AVAudioPCMBuffer? {
        let samples = synthesizer.render(pattern)
        guard !samples.isEmpty,
              let buffer = AVAudioPCMBuffer(
                pcmFormat: format,
                frameCapacity: AVAudioFrameCount(samples.count)
              )
        else { return nil }

        buffer.frameLength = AVAudioFrameCount(samples.count)
        let channel = buffer.floatChannelData![0]
        for index in samples.indices {
            channel[index] = samples[index]
        }
        return buffer
    }

    private func startEngineIfNeeded() throws {
        if !engine.isRunning {
            try engine.start()
        }
    }

    /// Schedules the pattern and returns immediately. Multiple calls queue up.
    public func play(_ pattern: Pattern) throws {
        guard let buffer = makeBuffer(for: pattern) else { return }
        try startEngineIfNeeded()
        player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        player.play()
    }

    /// Plays the pattern and blocks the calling thread until it has finished
    /// playing through the speaker.
    public func playAndWait(_ pattern: Pattern) throws {
        guard let buffer = makeBuffer(for: pattern) else { return }
        try startEngineIfNeeded()

        let finished = DispatchSemaphore(value: 0)
        player.scheduleBuffer(buffer, at: nil, options: [], completionCallbackType: .dataPlayedBack) { _ in
            finished.signal()
        }
        player.play()
        finished.wait()
        engine.stop()
    }

    /// Stops playback immediately.
    public func stop() {
        player.stop()
        engine.stop()
    }
}
