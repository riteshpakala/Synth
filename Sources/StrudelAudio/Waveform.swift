import Foundation

/// The timbre used to synthesize a tone.
///
/// `sample(phase:)` takes a phase in `[0, 1)` (one full cycle) and returns a
/// sample in roughly `[-1, 1]`. `.voice` is a simple additive stack of
/// harmonics — a starting point for the manual vocal-synth direction.
public enum Waveform: String, CaseIterable, Sendable {
    case sine
    case square
    case triangle
    case sawtooth
    case voice

    /// One sample of the waveform at the given phase (`0..<1`).
    public func sample(phase: Double) -> Double {
        switch self {
        case .sine:
            return sin(2.0 * .pi * phase)

        case .square:
            return phase < 0.5 ? 1.0 : -1.0

        case .triangle:
            return 4.0 * abs(phase - 0.5) - 1.0

        case .sawtooth:
            return 2.0 * phase - 1.0

        case .voice:
            // Additive harmonics with a vaguely vocal, formant-ish weighting.
            // Tweak these to sculpt vowels as the synth grows.
            let harmonics: [(harmonic: Double, amplitude: Double)] = [
                (1, 1.00), (2, 0.55), (3, 0.40), (4, 0.18), (5, 0.12), (6, 0.08),
            ]
            var value = 0.0
            for (harmonic, amplitude) in harmonics {
                value += amplitude * sin(2.0 * .pi * phase * harmonic)
            }
            let normalization = harmonics.reduce(0.0) { $0 + $1.amplitude }
            return value / normalization
        }
    }
}
