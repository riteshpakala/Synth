import Foundation

/// Renders a `Pattern` into mono floating-point PCM samples by delegating each
/// note to its `Voice`.
///
/// This is pure DSP with no audio-framework dependency, which makes it easy to
/// unit-test or render offline. `SequencePlayer` feeds the result to the
/// speaker.
public struct Synthesizer: Sendable {
    public let sampleRate: Double

    public init(sampleRate: Double = 44_100) {
        self.sampleRate = sampleRate
    }

    /// Renders the whole pattern to a contiguous buffer of mono samples in
    /// roughly `[-1, 1]`.
    public func render(_ pattern: Pattern) -> [Float] {
        let beatDuration = 60.0 / pattern.tempo
        var samples: [Float] = []
        samples.reserveCapacity(Int(pattern.duration * sampleRate) + 1)

        for step in pattern.steps {
            let seconds = step.value.beats * beatDuration
            let frames = max(0, Int(seconds * sampleRate))

            switch step.content {
            case .rest:
                samples.append(contentsOf: repeatElement(0, count: frames))

            case .tone(let keys, let velocity):
                let voice = step.voice ?? pattern.voice
                var mix = [Float](repeating: 0, count: frames)

                // Render each key with the voice, then sum and normalize so a
                // chord doesn't clip.
                for key in keys {
                    let rendered = voice.render(
                        frequency: key.frequency,
                        duration: seconds,
                        velocity: velocity,
                        sampleRate: sampleRate
                    )
                    for i in 0..<min(frames, rendered.count) {
                        mix[i] += rendered[i]
                    }
                }

                let normalize = Float(1.0 / Double(max(keys.count, 1)))
                if normalize != 1 {
                    for i in mix.indices { mix[i] *= normalize }
                }
                samples.append(contentsOf: mix)
            }
        }

        return samples
    }
}
