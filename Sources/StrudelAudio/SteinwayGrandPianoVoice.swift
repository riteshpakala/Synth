import Foundation

/// A synthesized approximation of a Steinway grand piano.
///
/// There are no samples here — it's additive synthesis tuned to read as
/// "grand piano":
///   • A stack of partials whose frequencies are stretched slightly sharp
///     (string *inharmonicity*) — the source of a piano's characteristic
///     shimmer and the reason a real piano is tuned with "stretch".
///   • Each partial decays exponentially, and higher partials die away faster,
///     so the tone begins bright and mellows as it rings.
///   • A near-instant hammer attack and no true sustain — the note always
///     decays, like a struck string.
///
/// All of the character lives in the parameters below, so future piano voicings
/// (a brighter concert grand, a darker upright, …) are just different values.
public struct SteinwayGrandPianoVoice: Voice {
    public let name: String
    /// Maximum number of partials (also capped by the Nyquist frequency).
    public var partialCount: Int
    /// String inharmonicity coefficient; stretches upper partials sharp.
    public var inharmonicity: Double
    /// Decay rate of the fundamental (larger = the note dies away sooner).
    public var decayRate: Double
    /// How much faster each successive partial decays than the one below it.
    public var decaySpread: Double
    /// Overall output level.
    public var level: Double

    public init(
        name: String = "Steinway Grand Piano",
        partialCount: Int = 24,
        inharmonicity: Double = 0.0004,
        decayRate: Double = 1.6,
        decaySpread: Double = 0.55,
        level: Double = 0.9
    ) {
        self.name = name
        self.partialCount = partialCount
        self.inharmonicity = inharmonicity
        self.decayRate = decayRate
        self.decaySpread = decaySpread
        self.level = level
    }

    public func render(
        frequency: Double,
        duration: TimeInterval,
        velocity: Double,
        sampleRate: Double
    ) -> [Float] {
        let frames = max(0, Int(duration * sampleRate))
        guard frames > 0 else { return [] }

        let nyquist = sampleRate * 0.5
        let invSampleRate = 1.0 / sampleRate
        // Harder strikes are brighter: this flattens the high-end rolloff.
        let brightness = 0.4 + 0.6 * max(0, min(1, velocity))

        // Build the partials that fit under Nyquist.
        var phases: [Double] = []
        var increments: [Double] = []
        var amplitudes: [Double] = []
        var decayPerSample: [Double] = []   // exp(-decay / sampleRate), applied each frame
        var amplitudeSum = 0.0

        for n in 1...partialCount {
            let stretch = (1.0 + inharmonicity * Double(n * n)).squareRoot()
            let freq = Double(n) * frequency * stretch
            if freq >= nyquist { break }

            let amplitude = 1.0 / pow(Double(n), 1.0 + (1.0 - brightness))
            let decay = decayRate * (1.0 + decaySpread * Double(n - 1))

            phases.append(0)
            increments.append(freq / sampleRate)
            amplitudes.append(amplitude)
            decayPerSample.append(exp(-decay * invSampleRate))
            amplitudeSum += amplitude
        }

        let count = amplitudes.count
        guard count > 0 else { return [Float](repeating: 0, count: frames) }

        let normalize = level / amplitudeSum * max(0, min(1, velocity))
        var decayValues = [Double](repeating: 1.0, count: count)

        let attackFrames = max(1, Int(0.003 * sampleRate))                 // ~3 ms hammer
        let releaseFrames = min(frames, max(1, Int(0.012 * sampleRate)))   // ~12 ms end fade
        let releaseStart = frames - releaseFrames

        var out = [Float](repeating: 0, count: frames)
        for i in 0..<frames {
            var sample = 0.0
            for p in 0..<count {
                sample += amplitudes[p] * decayValues[p] * SineTable.value(at: phases[p])
                phases[p] += increments[p]
                if phases[p] >= 1 { phases[p] -= 1 }
                decayValues[p] *= decayPerSample[p]
            }
            sample *= normalize

            if i < attackFrames {
                sample *= Double(i) / Double(attackFrames)
            }
            if i >= releaseStart {
                sample *= Double(frames - i) / Double(releaseFrames)
            }
            out[i] = Float(sample)
        }
        return out
    }
}

extension Voice where Self == SteinwayGrandPianoVoice {
    public static var steinwayGrand: SteinwayGrandPianoVoice { SteinwayGrandPianoVoice() }
}

/// A shared, linearly-interpolated sine lookup table. Additive synthesis calls
/// sine a lot; a table is far cheaper than `sin()` per partial per sample.
enum SineTable {
    private static let size = 8192
    private static let mask = size - 1
    private static let table: [Double] = (0..<size).map {
        sin(2.0 * .pi * Double($0) / Double(size))
    }

    /// `phase` in `[0, 1)`.
    static func value(at phase: Double) -> Double {
        let x = phase * Double(size)
        let i = Int(x)
        let frac = x - Double(i)
        let a = table[i & mask]
        let b = table[(i + 1) & mask]
        return a + (b - a) * frac
    }
}
