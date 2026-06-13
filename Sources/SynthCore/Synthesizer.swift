import Foundation

/// Renders a `Pattern` into mono floating-point PCM samples.
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
                let waveform = step.waveform ?? pattern.waveform
                // Independent phase accumulators keep each note in a chord
                // free of discontinuities.
                var phases = [Double](repeating: 0, count: keys.count)
                let increments = keys.map { $0.frequency / sampleRate }
                let mix = 1.0 / Double(max(keys.count, 1))

                for frame in 0..<frames {
                    let env = pattern.envelope.amplitude(
                        atFrame: frame,
                        totalFrames: frames,
                        sampleRate: sampleRate
                    )
                    var value = 0.0
                    for index in keys.indices {
                        value += waveform.sample(phase: phases[index])
                        phases[index] += increments[index]
                        if phases[index] >= 1.0 { phases[index] -= 1.0 }
                    }
                    samples.append(Float(value * mix * velocity * env))
                }
            }
        }

        return samples
    }
}
