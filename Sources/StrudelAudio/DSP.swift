// DSP.swift — filters, waveshaping, delay, reverb.
// Semantics ported from Strudel's superdough <https://codeberg.org/uzu/strudel>
// (WebAudio biquads, vowel.mjs formant bank, dirt-style shape/crush/coarse)
// — AGPL-3.0-or-later.

import Foundation
import StrudelCore

// MARK: - Biquad (Audio EQ Cookbook, matching WebAudio BiquadFilterNode)

struct Biquad {
    var b0: Double = 1, b1: Double = 0, b2: Double = 0
    var a1: Double = 0, a2: Double = 0
    private var x1: Double = 0, x2: Double = 0
    private var y1: Double = 0, y2: Double = 0

    enum Kind { case lowpass, highpass, bandpass }

    static func make(_ kind: Kind, frequency: Double, q: Double, sampleRate: Double) -> Biquad {
        var f = Biquad()
        f.configure(kind, frequency: frequency, q: q, sampleRate: sampleRate)
        return f
    }

    mutating func configure(_ kind: Kind, frequency: Double, q: Double, sampleRate: Double) {
        let freq = max(10, min(frequency, sampleRate * 0.49))
        let w0 = 2 * Double.pi * freq / sampleRate
        let cosw = cos(w0), sinw = sin(w0)
        let qq = max(q, 0.0001)
        let alpha = sinw / (2 * qq)
        let a0: Double
        switch kind {
        case .lowpass:
            b0 = (1 - cosw) / 2; b1 = 1 - cosw; b2 = (1 - cosw) / 2
            a0 = 1 + alpha; a1 = -2 * cosw; a2 = 1 - alpha
        case .highpass:
            b0 = (1 + cosw) / 2; b1 = -(1 + cosw); b2 = (1 + cosw) / 2
            a0 = 1 + alpha; a1 = -2 * cosw; a2 = 1 - alpha
        case .bandpass:
            b0 = alpha; b1 = 0; b2 = -alpha
            a0 = 1 + alpha; a1 = -2 * cosw; a2 = 1 - alpha
        }
        b0 /= a0; b1 /= a0; b2 /= a0; a1 /= a0; a2 /= a0
    }

    mutating func process(_ x: Double) -> Double {
        let y = b0 * x + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
        x2 = x1; x1 = x
        y2 = y1; y1 = y
        return y
    }

    mutating func processBuffer(_ samples: inout [Float]) {
        for i in samples.indices {
            samples[i] = Float(process(Double(samples[i])))
        }
    }
}

// MARK: - ADSR

/// Linear ADSR matching superdough's getADSRValues clamping.
struct ADSR {
    var attack: Double
    var decay: Double
    var sustain: Double
    var release: Double

    /// superdough getADSRValues: nil params fall back per source type.
    init(attack: Double?, decay: Double?, sustain: Double?, release: Double?,
         defaults: (Double, Double, Double, Double)) {
        let envmin = 0.001
        let releaseMin = 0.01
        let envmax = 1.0
        if attack == nil && decay == nil && sustain == nil && release == nil {
            (self.attack, self.decay, self.sustain, self.release) = defaults
            return
        }
        let sus = sustain ?? ((attack != nil && decay == nil) || (attack == nil && decay == nil) ? envmax : envmin)
        self.attack = max(attack ?? 0, envmin)
        self.decay = max(decay ?? 0, envmin)
        self.sustain = min(sus, envmax)
        self.release = max(release ?? 0, releaseMin)
    }

    /// Envelope level at time t for a note held `holdEnd` seconds; total
    /// length is holdEnd + release.
    func level(at t: Double, holdEnd: Double) -> Double {
        if t < 0 { return 0 }
        let sustained: Double
        if t < attack {
            sustained = attack > 0 ? t / attack : 1
        } else if t < attack + decay {
            let p = (t - attack) / decay
            sustained = 1 - (1 - sustain) * min(p, 1)
        } else {
            sustained = sustain
        }
        if t <= holdEnd { return sustained }
        // release phase from wherever the envelope was at holdEnd
        let atHold: Double
        if holdEnd < attack {
            atHold = attack > 0 ? holdEnd / attack : 1
        } else if holdEnd < attack + decay {
            let p = (holdEnd - attack) / decay
            atHold = 1 - (1 - sustain) * min(p, 1)
        } else {
            atHold = sustain
        }
        let p = release > 0 ? (t - holdEnd) / release : 1
        return atHold * max(0, 1 - p)
    }
}

// MARK: - Vowel formant filter (port of vowel.mjs)

struct VowelFormant {
    let freqs: [Double]
    let gains: [Double]
    let qs: [Double]

    static let table: [String: VowelFormant] = {
        var t: [String: VowelFormant] = [
            "a": VowelFormant(freqs: [660, 1120, 2750, 3000, 3350], gains: [1, 0.5012, 0.0708, 0.0631, 0.0126], qs: [80, 90, 120, 130, 140]),
            "e": VowelFormant(freqs: [440, 1800, 2700, 3000, 3300], gains: [1, 0.1995, 0.1259, 0.1, 0.1], qs: [70, 80, 100, 120, 120]),
            "i": VowelFormant(freqs: [270, 1850, 2900, 3350, 3590], gains: [1, 0.0631, 0.0631, 0.0158, 0.0158], qs: [40, 90, 100, 120, 120]),
            "o": VowelFormant(freqs: [430, 820, 2700, 3000, 3300], gains: [1, 0.3162, 0.0501, 0.0794, 0.01995], qs: [40, 80, 100, 120, 120]),
            "u": VowelFormant(freqs: [370, 630, 2750, 3000, 3400], gains: [1, 0.1, 0.0708, 0.0316, 0.01995], qs: [40, 60, 100, 120, 120]),
            "ae": VowelFormant(freqs: [650, 1515, 2400, 3000, 3350], gains: [1, 0.5, 0.1008, 0.0631, 0.0126], qs: [80, 90, 120, 130, 140]),
            "aa": VowelFormant(freqs: [560, 900, 2570, 3000, 3300], gains: [1, 0.5, 0.0708, 0.0631, 0.0126], qs: [80, 90, 120, 130, 140]),
            "oe": VowelFormant(freqs: [500, 1430, 2300, 3000, 3300], gains: [1, 0.2, 0.0708, 0.0316, 0.01995], qs: [40, 60, 100, 120, 120]),
            "ue": VowelFormant(freqs: [250, 1750, 2150, 3200, 3300], gains: [1, 0.1, 0.0708, 0.0316, 0.01995], qs: [40, 60, 100, 120, 120]),
            "y": VowelFormant(freqs: [400, 1460, 2400, 3000, 3300], gains: [1, 0.2, 0.0708, 0.0316, 0.02995], qs: [40, 60, 100, 120, 120]),
            "uh": VowelFormant(freqs: [600, 1250, 2100, 3100, 3500], gains: [1, 0.3, 0.0608, 0.0316, 0.01995], qs: [40, 70, 100, 120, 130]),
            "un": VowelFormant(freqs: [500, 1240, 2280, 3000, 3500], gains: [1, 0.1, 0.1708, 0.0216, 0.02995], qs: [40, 60, 100, 120, 120]),
            "en": VowelFormant(freqs: [600, 1480, 2450, 3200, 3300], gains: [1, 0.15, 0.0708, 0.0316, 0.02995], qs: [40, 60, 100, 120, 120]),
            "an": VowelFormant(freqs: [700, 1050, 2500, 3000, 3300], gains: [1, 0.1, 0.0708, 0.0316, 0.02995], qs: [40, 60, 100, 120, 120]),
            "on": VowelFormant(freqs: [500, 1080, 2350, 3000, 3300], gains: [1, 0.1, 0.0708, 0.0316, 0.02995], qs: [40, 60, 100, 120, 120]),
        ]
        // Unicode aliases from vowel.mjs
        t["æ"] = t["ae"]; t["ø"] = t["oe"]; t["ɑ"] = t["aa"]
        t["å"] = t["aa"]; t["ö"] = t["oe"]; t["ü"] = t["ue"]; t["ı"] = t["y"]
        return t
    }()

    /// Runs the 5-band parallel formant bank with makeup gain 8.
    static func apply(_ vowel: String, _ samples: inout [Float], sampleRate: Double) {
        guard let formant = table[vowel.lowercased()] else { return }
        var filters = (0..<5).map { i in
            Biquad.make(.bandpass, frequency: formant.freqs[i], q: formant.qs[i], sampleRate: sampleRate)
        }
        let makeup = 8.0
        for i in samples.indices {
            let x = Double(samples[i])
            var sum = 0.0
            for b in 0..<5 {
                sum += filters[b].process(x) * formant.gains[b]
            }
            samples[i] = Float(sum * makeup)
        }
    }
}

// MARK: - Waveshaping (dirt-style)

enum Waveshape {
    /// Dirt/Tidal 'shape': x * (1+k) / (1 + k*|x|), k = 2a/(1-a).
    static func shape(_ samples: inout [Float], amount: Double, postgain: Double = 1) {
        let a = min(max(amount, 0), 0.999)
        guard a > 0 else { return }
        let k = 2 * a / (1 - a)
        for i in samples.indices {
            let x = Double(samples[i])
            samples[i] = Float((x * (1 + k)) / (1 + k * abs(x)) * postgain)
        }
    }

    /// tanh saturation (superdough 'distort').
    static func distort(_ samples: inout [Float], amount: Double, postgain: Double = 1) {
        guard amount > 0 else { return }
        for i in samples.indices {
            samples[i] = Float(tanh(Double(samples[i]) * (1 + amount * 10)) * postgain)
        }
    }

    /// Bit crush to n bits.
    static func crush(_ samples: inout [Float], bits: Double) {
        guard bits >= 1 else { return }
        let x = pow(2.0, bits - 1)
        for i in samples.indices {
            samples[i] = Float((Double(samples[i]) * x).rounded() / x)
        }
    }

    /// Sample-and-hold every n samples.
    static func coarse(_ samples: inout [Float], factor: Int) {
        guard factor > 1 else { return }
        var held: Float = 0
        for i in samples.indices {
            if i % factor == 0 { held = samples[i] }
            samples[i] = held
        }
    }
}

// MARK: - Distortion algorithms (exact port of superdough helpers.mjs)

enum DistortionAlgorithm: String, CaseIterable {
    // Order matters: numeric `distorttype` indexes this list (scurve is 0).
    case scurve, soft, hard, cubic, diode, asym, fold, sinefold, chebyshev

    static func named(_ name: String) -> DistortionAlgorithm {
        DistortionAlgorithm(rawValue: name) ?? .scurve
    }

    static func indexed(_ i: Int) -> DistortionAlgorithm {
        let all = DistortionAlgorithm.allCases
        return all[_mod(i, all.count)]
    }

    private static func squash(_ x: Double) -> Double { x / (1 + x) }

    private static func scurveF(_ x: Double, _ k: Double) -> Double {
        ((1 + k) * x) / (1 + k * Swift.abs(x))
    }
    private static func softF(_ x: Double, _ k: Double) -> Double { tanh(x * (1 + k)) }
    private static func hardF(_ x: Double, _ k: Double) -> Double {
        Swift.min(Swift.max((1 + k) * x, -1), 1)
    }
    private static func foldF(_ x: Double, _ k: Double) -> Double {
        let y = (1 + 0.5 * k) * x
        let window = _mod(y + 1, 4)
        return 1 - Swift.abs(window - 2)
    }
    private static func sineFoldF(_ x: Double, _ k: Double) -> Double {
        sin((Double.pi / 2) * foldF(x, k))
    }
    private static func cubicF(_ x: Double, _ k: Double) -> Double {
        let t = squash(log1p(k))
        let cubic = (x - (t / 3) * x * x * x) / (1 - t / 3)
        return softF(cubic, k)
    }
    private static func diodeF(_ x: Double, _ k: Double, asym: Bool = false) -> Double {
        let g = 1 + 2 * k
        let t = squash(log1p(k))
        let bias = 0.07 * t
        let pos = softF(x + bias, 2 * k)
        let neg = softF(asym ? bias : -x + bias, 2 * k)
        let y = pos - neg
        // Normalize so the map is ~identity near 0.
        let sech = 1 / cosh(g * bias)
        let sech2 = sech * sech
        let denom = Swift.max(1e-8, (asym ? 1 : 2) * g * sech2)
        return softF(y / denom, k)
    }
    private static func chebyshevF(_ x: Double, _ k: Double) -> Double {
        let kl = 10 * log1p(k)
        var tnm1 = 1.0
        var tnm2 = x
        var y = 0.0
        for i in 1..<64 {
            if i < 2 {
                y += i == 0 ? tnm1 : tnm2
                continue
            }
            let tn = 2 * x * tnm1 - tnm2
            tnm2 = tnm1
            tnm1 = tn
            if i % 2 == 0 {
                y += Swift.min((1.3 * kl) / Double(i), 2) * tn
            }
        }
        return softF(y, kl / 20)
    }

    func apply(_ x: Double, _ k: Double) -> Double {
        switch self {
        case .scurve: return Self.scurveF(x, k)
        case .soft: return Self.softF(x, k)
        case .hard: return Self.hardF(x, k)
        case .cubic: return Self.cubicF(x, k)
        case .diode: return Self.diodeF(x, k)
        case .asym: return Self.diodeF(x, k, asym: true)
        case .fold: return Self.foldF(x, k)
        case .sinefold: return Self.sineFoldF(x, k)
        case .chebyshev: return Self.chebyshevF(x, k)
        }
    }

    /// The DistortProcessor loop: shape = expm1(distort), postgain in [0.001, 1].
    static func process(_ samples: inout [Float], amount: Double, postgain: Double,
                        algorithm: DistortionAlgorithm) {
        let k = expm1(amount)
        let g = Swift.min(Swift.max(postgain, 0.001), 1)
        for i in samples.indices {
            samples[i] = Float(g * algorithm.apply(Double(samples[i]), k))
        }
    }
}

// MARK: - Phaser (superdough getPhaser: LFO-swept notch)

enum Phaser {
    /// Notch at center+282 Hz, Q = 2 - clamp(depth*2, 0, 1.9), detune swept
    /// ±sweep cents by a sine LFO at `rate` Hz.
    static func apply(_ samples: inout [Float], rate: Double, depth: Double,
                      center: Double, sweep: Double, sampleRate: Double) {
        let centerFreq = center + 282
        let q = 2 - Swift.min(Swift.max(depth * 2, 0), 1.9)
        var filter = Biquad()
        let block = 64
        var i = 0
        while i < samples.count {
            let t = Double(i) / sampleRate
            let detuneCents = sin(2 * .pi * rate * t) * sweep
            let f = centerFreq * pow(2, detuneCents / 1200)
            filter.configureNotch(frequency: f, q: q, sampleRate: sampleRate)
            let endIdx = Swift.min(i + block, samples.count)
            for j in i..<endIdx {
                samples[j] = Float(filter.process(Double(samples[j])))
            }
            i = endIdx
        }
    }
}

extension Biquad {
    mutating func configureNotch(frequency: Double, q: Double, sampleRate: Double) {
        let freq = Swift.max(10, Swift.min(frequency, sampleRate * 0.49))
        let w0 = 2 * Double.pi * freq / sampleRate
        let cosw = cos(w0), sinw = sin(w0)
        let alpha = sinw / (2 * Swift.max(q, 0.0001))
        let a0 = 1 + alpha
        b0 = 1 / a0; b1 = -2 * cosw / a0; b2 = 1 / a0
        a1 = -2 * cosw / a0; a2 = (1 - alpha) / a0
    }
}

// MARK: - Compressor (WebAudio DynamicsCompressor defaults, per superdough)

enum Compressor {
    /// threshold -3 dB, ratio 10, knee 10, attack 5 ms, release 50 ms.
    static func apply(_ samples: inout [Float], threshold: Double, ratio: Double,
                      knee: Double, attack: Double, release: Double, sampleRate: Double) {
        let attackCoeff = exp(-1 / (Swift.max(attack, 0.0001) * sampleRate))
        let releaseCoeff = exp(-1 / (Swift.max(release, 0.0001) * sampleRate))
        var envelope = 0.0
        for i in samples.indices {
            let x = Double(samples[i])
            let level = Swift.abs(x)
            envelope = level > envelope
                ? attackCoeff * envelope + (1 - attackCoeff) * level
                : releaseCoeff * envelope + (1 - releaseCoeff) * level
            let db = 20 * log10(Swift.max(envelope, 1e-6))
            // soft knee gain computer
            var gainDb = 0.0
            if db > threshold + knee / 2 {
                gainDb = (threshold + (db - threshold) / ratio) - db
            } else if db > threshold - knee / 2 {
                let over = db - threshold + knee / 2
                gainDb = ((1 / ratio - 1) * over * over) / (2 * knee)
            }
            samples[i] = Float(x * pow(10, gainDb / 20))
        }
    }
}

// MARK: - Streaming effects (shared orbit buses)

/// A continuously running feedback delay line — the shared per-orbit delay bus.
/// Parameters update at hap onsets, exactly like superdough's shared node.
final class StreamingDelay {
    private var buffer: [Float]
    private var writeIndex = 0
    private var delaySamples: Int
    var feedback: Double
    private let sampleRate: Double

    init(sampleRate: Double, maxSeconds: Double = 8) {
        self.sampleRate = sampleRate
        self.buffer = [Float](repeating: 0, count: Int(maxSeconds * sampleRate))
        self.delaySamples = Int(0.25 * sampleRate)
        self.feedback = 0.5
    }

    func setTime(_ seconds: Double) {
        delaySamples = Swift.max(1, Swift.min(Int(seconds * sampleRate), buffer.count - 1))
    }

    func reset() {
        for i in buffer.indices { buffer[i] = 0 }
    }

    func process(_ input: Float) -> Float {
        let readIndex = (writeIndex - delaySamples + buffer.count) % buffer.count
        let delayed = buffer[readIndex]
        buffer[writeIndex] = input + delayed * Float(Swift.min(Swift.max(feedback, 0), 0.98))
        writeIndex = (writeIndex + 1) % buffer.count
        return delayed
    }
}

/// A continuously running Freeverb — the shared per-orbit reverb bus.
final class StreamingFreeverb {
    private static let combTunings = [1116, 1188, 1277, 1356, 1422, 1491, 1557, 1617]
    private static let allpassTunings = [556, 441, 341, 225]
    private var combBuffers: [[Float]]
    private var combIndex: [Int]
    private var combStore: [Float]
    private var allpassBuffers: [[Float]]
    private var allpassIndex: [Int]
    private var roomsize = 0.84
    private let damp = 0.4

    init(sampleRate: Double, stereoSpread: Int = 0) {
        let scale = sampleRate / 44_100
        combBuffers = Self.combTunings.map {
            [Float](repeating: 0, count: max(1, Int(Double($0 + stereoSpread) * scale)))
        }
        combIndex = [Int](repeating: 0, count: combBuffers.count)
        combStore = [Float](repeating: 0, count: combBuffers.count)
        allpassBuffers = Self.allpassTunings.map {
            [Float](repeating: 0, count: max(1, Int(Double($0 + stereoSpread) * scale)))
        }
        allpassIndex = [Int](repeating: 0, count: allpassBuffers.count)
    }

    func setSize(_ size: Double) {
        roomsize = 0.7 + Swift.min(Swift.max(size, 0), 1) * 0.28
    }

    func reset() {
        for c in combBuffers.indices {
            for i in combBuffers[c].indices { combBuffers[c][i] = 0 }
            combStore[c] = 0
        }
        for a in allpassBuffers.indices {
            for i in allpassBuffers[a].indices { allpassBuffers[a][i] = 0 }
        }
    }

    func process(_ input: Float) -> Float {
        let x = input * 0.015
        var mixed: Float = 0
        for c in 0..<combBuffers.count {
            let idx = combIndex[c]
            let output = combBuffers[c][idx]
            combStore[c] = output * Float(1 - damp) + combStore[c] * Float(damp)
            combBuffers[c][idx] = x + combStore[c] * Float(roomsize)
            combIndex[c] = (idx + 1) % combBuffers[c].count
            mixed += output
        }
        for a in 0..<allpassBuffers.count {
            let idx = allpassIndex[a]
            let bufout = allpassBuffers[a][idx]
            let output = -mixed + bufout
            allpassBuffers[a][idx] = mixed + bufout * 0.5
            allpassIndex[a] = (idx + 1) % allpassBuffers[a].count
            mixed = output
        }
        return mixed
    }
}
