// Sounds.swift — the sound registry (superdough's soundMap equivalent).
// Semantics ported from Strudel <https://codeberg.org/uzu/strudel>
// (packages/superdough/synth.mjs, noise.mjs) — AGPL-3.0-or-later.

import Foundation
import StrudelCore

/// Parameters resolved from a hap's control map for rendering one sound.
public struct SoundParams {
    public var frequency: Double
    /// Seconds the note is held (before release).
    public var duration: Double
    /// ADSR resolved with the source's defaults.
    public var adsr: ADSRParams
    public var velocity: Double
    /// Sample index (`n`).
    public var n: Int
    /// Raw control map for sound-specific params (vib, fm, begin/end, …).
    public var value: ControlMap

    public struct ADSRParams {
        public var attack: Double?
        public var decay: Double?
        public var sustain: Double?
        public var release: Double?
    }
}

/// Something that can render a note into mono samples.
/// The returned buffer may be longer than duration (e.g. release tails).
public protocol SoundSource: Sendable {
    var name: String { get }
    /// Renders `params.duration + release` worth of samples.
    func render(params: SoundParams, sampleRate: Double) -> [Float]
}

/// The global sound registry: superdough's `soundMap`.
public final class SoundRegistry: @unchecked Sendable {
    public static let shared = SoundRegistry()
    private var sounds: [String: any SoundSource] = [:]
    private let lock = NSLock()

    private init() {
        registerDefaults()
    }

    public func register(_ sound: any SoundSource, as name: String? = nil) {
        lock.lock(); defer { lock.unlock() }
        sounds[(name ?? sound.name).lowercased()] = sound
    }

    public func get(_ name: String) -> (any SoundSource)? {
        lock.lock(); defer { lock.unlock() }
        // superdough getSound falls back to triangle
        return sounds[name.lowercased()] ?? sounds["triangle"]
    }

    public func exists(_ name: String) -> Bool {
        lock.lock(); defer { lock.unlock() }
        return sounds[name.lowercased()] != nil
    }

    public var names: [String] {
        lock.lock(); defer { lock.unlock() }
        return sounds.keys.sorted()
    }

    private func registerDefaults() {
        // Waveform synths + aliases (synth.mjs: waveforms + waveformAliases)
        for (name, wave) in [("sine", Waveform.sine), ("square", .square),
                             ("triangle", .triangle), ("sawtooth", .sawtooth)] {
            sounds[name] = SynthSound(name: name, waveform: wave)
        }
        sounds["sin"] = sounds["sine"]
        sounds["sqr"] = sounds["square"]
        sounds["tri"] = sounds["triangle"]
        sounds["saw"] = sounds["sawtooth"]
        // 'user' renders a custom additive waveform from .partials(...)
        sounds["user"] = SynthSound(name: "user", waveform: .triangle)
        // ZzFX micro-synth (zzfx.mjs)
        for z in ["zzfx", "z_sine", "z_sawtooth", "z_triangle", "z_square", "z_tan", "z_noise"] {
            sounds[z] = ZzfxSound(name: z)
        }
        // Noises (noise.mjs)
        for noise in ["white", "pink", "brown", "crackle"] {
            sounds[noise] = NoiseSound(name: noise)
        }
        // The classic voices ship as sounds too.
        sounds["steinway"] = VoiceSound(voice: SteinwayGrandPianoVoice())
        sounds["piano"] = sounds["steinway"]
        sounds["synthvoice"] = VoiceSound(voice: OscillatorVoice(name: "Synth Voice", waveform: .voice))
    }
}

// MARK: - Synth sound (synth.mjs oscillators)

/// Oscillator synth with vibrato, optional FM and noise mix.
/// ADSR defaults [0.001, 0.05, 0.6, 0.01] and the 0.3 gain factor come from
/// synth.mjs registerSynthSounds.
struct SynthSound: SoundSource {
    let name: String
    let waveform: Waveform

    func render(params: SoundParams, sampleRate: Double) -> [Float] {
        let adsr = ADSR(attack: params.adsr.attack, decay: params.adsr.decay,
                        sustain: params.adsr.sustain, release: params.adsr.release,
                        defaults: (0.001, 0.05, 0.6, 0.01))
        let holdEnd = params.duration
        let total = holdEnd + adsr.release
        let frames = max(1, Int(total * sampleRate))
        var out = [Float](repeating: 0, count: frames)

        // vibrato (vib/vibmod)
        let vib = params.value["vib"]?.doubleValue ?? 0
        let vibmod = params.value["vibmod"]?.doubleValue ?? 0.5
        // simple 2-op FM (fmi = modulation index, fmh = harmonicity)
        let fmi = params.value["fmi"]?.doubleValue ?? params.value["fm"]?.doubleValue ?? 0
        let fmh = params.value["fmh"]?.doubleValue ?? 1
        // noise mix (noise control adds white noise)
        let noiseMix = params.value["noise"]?.doubleValue ?? 0
        // density for crackle-ish noise unused here

        // Custom additive waveform from partials/phases (synth.mjs waveformN):
        // PeriodicWave semantics: x(p) = Σ real[n]·cos(2πnp) + imag[n]·sin(2πnp).
        var customTable: [Double]? = nil
        let partialsValue = params.value["partials"] ?? (name == "user" ? params.value["n"] : nil)
        if let partials = partialsValue, name != "sine" {
            let mags: [Double]
            if let list = partials.listValue {
                mags = list.map { $0.doubleValue ?? 0 }
            } else if let count = partials.intValue, count > 0 {
                mags = [Double](repeating: 1, count: count)
            } else {
                mags = []
            }
            if !mags.isEmpty {
                let phases = params.value["phases"]?.listValue?.map { $0.doubleValue ?? 0 }
                customTable = SynthSound.buildWaveTable(type: name, partials: mags, phases: phases)
            }
        }

        var phase = 0.0
        var modPhase = 0.0
        var vibPhase = 0.0
        var rng = SystemRandomNumberGenerator()
        for i in 0..<frames {
            let t = Double(i) / sampleRate
            var freq = params.frequency
            if vib > 0 {
                // vibrato depth in semitones (vibmod)
                let mod = sin(2 * .pi * vibPhase) * vibmod
                freq *= pow(2, mod / 12)
                vibPhase += vib / sampleRate
            }
            if fmi > 0 {
                let modulator = sin(2 * .pi * modPhase)
                freq += modulator * fmi * params.frequency
                modPhase += (params.frequency * fmh) / sampleRate
                if modPhase >= 1 { modPhase -= 1 }
            }
            var sample: Double
            if let table = customTable {
                let x = phase * Double(table.count)
                let idx = Int(x) % table.count
                let frac = x - x.rounded(.down)
                let a = table[idx]
                let b = table[(idx + 1) % table.count]
                sample = a + (b - a) * frac
            } else {
                sample = waveform.sample(phase: phase)
            }
            if noiseMix > 0 {
                let noise = Double.random(in: -1...1, using: &rng)
                sample = sample * (1 - noiseMix) + noise * noiseMix
            }
            let env = adsr.level(at: t, holdEnd: holdEnd)
            out[i] = Float(sample * env * 0.3 * params.velocity)
            phase += freq / sampleRate
            if phase >= 1 { phase -= 1 }
            if phase < 0 { phase += 1 }
        }
        return out
    }

    /// Builds one cycle of the additive waveform described by partial
    /// magnitudes (and optional phases), per synth.mjs waveformN's
    /// per-type Fourier terms.
    static func buildWaveTable(type: String, partials: [Double], phases: [Double]?,
                               size: Int = 2048) -> [Double] {
        func terms(_ n: Double) -> (Double, Double) {
            switch type {
            case "sawtooth": return (0, -1 / n)
            case "square": return (0, Int(n) % 2 == 0 ? 0 : 1 / n)
            case "triangle": return (Int(n) % 2 == 0 ? (0, 0) : (1 / (n * n), 0))
            default: return (0, 1)  // "user"
            }
        }
        var real = [Double](repeating: 0, count: partials.count + 1)
        var imag = [Double](repeating: 0, count: partials.count + 1)
        for n in 0..<partials.count {
            let (r, i) = terms(Double(n + 1))
            var R = r * partials[n]
            var I = i * partials[n]
            let phase = phases?.indices.contains(n) == true ? phases![n] : 0
            if phase != 0 {
                let c = Foundation.cos(2 * .pi * phase)
                let sn = Foundation.sin(2 * .pi * phase)
                (R, I) = (c * R - sn * I, sn * R + c * I)
            }
            real[n + 1] = R
            imag[n + 1] = I
        }
        var table = [Double](repeating: 0, count: size)
        var peak = 0.0
        for i in 0..<size {
            let p = Double(i) / Double(size)
            var v = 0.0
            for n in 1..<real.count {
                let w = 2 * .pi * Double(n) * p
                v += real[n] * Foundation.cos(w) + imag[n] * Foundation.sin(w)
            }
            table[i] = v
            peak = Swift.max(peak, Swift.abs(v))
        }
        // WebAudio normalizes PeriodicWaves by default
        if peak > 0 {
            for i in 0..<size { table[i] /= peak }
        }
        return table
    }
}

// MARK: - Noise sound (noise.mjs)

struct NoiseSound: SoundSource {
    let name: String

    func render(params: SoundParams, sampleRate: Double) -> [Float] {
        let adsr = ADSR(attack: params.adsr.attack, decay: params.adsr.decay,
                        sustain: params.adsr.sustain, release: params.adsr.release,
                        defaults: (0.001, 0.05, 0.6, 0.01))
        let holdEnd = params.duration
        let frames = max(1, Int((holdEnd + adsr.release) * sampleRate))
        var out = [Float](repeating: 0, count: frames)

        var rng = SeededGenerator(seed: 0x9E3779B97F4A7C15 &+ UInt64(params.n))
        var b: [Double] = Array(repeating: 0, count: 7)  // pink state
        var brown = 0.0
        // crackle density (superdough: density default 0.03)
        let density = params.value["density"]?.doubleValue ?? 0.03

        for i in 0..<frames {
            let t = Double(i) / sampleRate
            let white = Double.random(in: -1...1, using: &rng)
            let sample: Double
            switch name {
            case "pink":
                // Paul Kellet's pink noise filter
                b[0] = 0.99886 * b[0] + white * 0.0555179
                b[1] = 0.99332 * b[1] + white * 0.0750759
                b[2] = 0.96900 * b[2] + white * 0.1538520
                b[3] = 0.86650 * b[3] + white * 0.3104856
                b[4] = 0.55000 * b[4] + white * 0.5329522
                b[5] = -0.7616 * b[5] - white * 0.0168980
                let pink = b[0] + b[1] + b[2] + b[3] + b[4] + b[5] + b[6] + white * 0.5362
                b[6] = white * 0.115926
                sample = pink * 0.11
            case "brown":
                brown = (brown + 0.02 * white) / 1.02
                sample = brown * 3.5
            case "crackle":
                sample = Double.random(in: 0...1, using: &rng) < density ? white : 0
            default:  // white
                sample = white
            }
            let env = adsr.level(at: t, holdEnd: holdEnd)
            out[i] = Float(sample * env * 0.3 * params.velocity)
        }
        return out
    }
}

/// Deterministic RNG so renders are reproducible.
struct SeededGenerator: RandomNumberGenerator {
    var state: UInt64
    init(seed: UInt64) { state = seed == 0 ? 0xdeadbeef : seed }
    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}

// MARK: - Voice adapter (classic SynthCore voices as sounds)

/// Wraps a `Voice` (additive piano, oscillator presets, future vocal voices)
/// as a registry sound.
public struct VoiceSound: SoundSource {
    public let voice: any Voice
    public var name: String { voice.name.lowercased().replacingOccurrences(of: " ", with: "") }

    public init(voice: any Voice) {
        self.voice = voice
    }

    public func render(params: SoundParams, sampleRate: Double) -> [Float] {
        // Voices render their own envelope; give them hold + a short tail.
        let release = params.adsr.release ?? 0.01
        return voice.render(
            frequency: params.frequency,
            duration: params.duration + release,
            velocity: params.velocity,
            sampleRate: sampleRate
        )
    }
}

/// Registers a custom sound, superdough-style.
public func registerSound(_ name: String, _ sound: any SoundSource) {
    SoundRegistry.shared.register(sound, as: name)
}
