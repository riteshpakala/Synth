// HapRenderer.swift — renders one hap's control map into stereo audio.
// The per-voice chain ported from Strudel's superdough
// (packages/superdough/superdough.mjs): source → ADSR → filters (+ envelopes)
// → vowel → phaser → shape/crush/coarse/distort → compressor → gain/velocity
// → pan, with delay/reverb send signals handed to the shared orbit buses.
// — AGPL-3.0-or-later.

import Foundation
import StrudelCore

/// A rendered voice: stereo dry samples plus mono send signals for the
/// orbit's shared delay/reverb buses.
public struct RenderedHap {
    public var left: [Float]
    public var right: [Float]
    public var frames: Int { left.count }

    /// Which orbit's buses receive the sends (superdough default 1).
    public var orbit: Int = 1
    public var delaySend: [Float]? = nil
    public var delayTime: Double = 0.25
    public var delayFeedback: Double = 0.5
    public var reverbSend: [Float]? = nil
    public var roomSize: Double = 0.5
}

public enum HapRenderer {
    /// superdough defaults (defaultDefaultValues).
    static let defaultGain = 0.8
    static let defaultDelayFeedback = 0.5
    static let defaultDelaySync = 3.0 / 16.0

    /// Resolves note/freq like superdough's getFrequencyFromValue (default midi 36).
    static func frequency(of value: ControlMap) -> Double {
        var freq = value["freq"]?.doubleValue
        if freq == nil {
            var note: Double
            if let noteVal = value["note"] {
                if let s = noteVal.stringValue, isNote(s) {
                    note = noteToMidi(s)
                } else {
                    note = noteVal.doubleValue ?? 36
                }
            } else if let n = value["n"]?.doubleValue, value["s"] == nil {
                note = n
            } else {
                note = 36
            }
            freq = midiToFreq(note)
        }
        let octave = value["octave"]?.doubleValue ?? 0
        return freq! * pow(2, octave)
    }

    /// Renders the hap's value into dry stereo + send signals.
    /// `duration` is the event duration in seconds, from the scheduler.
    public static func render(value rawValue: PatternValue, duration: Double,
                              cps: Double = 0.5, sampleRate: Double = 44_100) -> RenderedHap? {
        let value = rawValue.asControlMap(defaultKey: "note")
        var sName = value["s"]?.stringValue ?? "triangle"
        if ["-", "~", "_"].contains(sName) { return nil }
        if let bank = value["bank"]?.stringValue {
            sName = bank + sName
        }
        guard let sound = SoundRegistry.shared.get(sName) else { return nil }

        // unit 'c' speed math needs cps: pre-scale sample speed
        var soundValue = value
        if value["unit"]?.stringValue == "c", let speed = value["speed"]?.doubleValue {
            soundValue["speed"] = .number(speed / cps)
        }

        let velocity = value["velocity"]?.doubleValue ?? 1
        let params = SoundParams(
            frequency: frequency(of: value),
            duration: duration,
            adsr: .init(attack: value["attack"]?.doubleValue,
                        decay: value["decay"]?.doubleValue,
                        sustain: value["sustain"]?.doubleValue,
                        release: value["release"]?.doubleValue),
            velocity: velocity,
            n: value["n"]?.intValue ?? 0,
            value: soundValue
        )

        var mono = sound.render(params: params, sampleRate: sampleRate)
        guard !mono.isEmpty else { return nil }

        // --- Filters (with superdough envelope semantics) ---
        applyFilters(&mono, value: value, sampleRate: sampleRate, duration: duration)

        // --- Vowel formant (the vocal seam) ---
        if let vowel = value["vowel"]?.stringValue {
            VowelFormant.apply(vowel, &mono, sampleRate: sampleRate)
        }

        // --- Phaser (LFO-swept notch, superdough getPhaser) ---
        if let phaserrate = value["phaserrate"]?.doubleValue {
            let depth = value["phaserdepth"]?.doubleValue ?? 0.75
            if depth > 0 {
                Phaser.apply(&mono,
                             rate: phaserrate,
                             depth: depth,
                             center: value["phasercenter"]?.doubleValue ?? 1000,
                             sweep: value["phasersweep"]?.doubleValue ?? 2000,
                             sampleRate: sampleRate)
            }
        }

        // --- Waveshaping ---
        if let shape = value["shape"]?.doubleValue {
            Waveshape.shape(&mono, amount: shape, postgain: value["shapevol"]?.doubleValue ?? 1)
        }
        if let amount = value["distort"]?.doubleValue, amount > 0 {
            // The soft/hard/cubic/… combinators splat [amount, vol, algo]
            // across distort/distortvol/distorttype (multi-name control).
            let postgain = value["distortvol"]?.doubleValue ?? 1
            let algorithm: DistortionAlgorithm
            if let name = value["distorttype"]?.stringValue {
                algorithm = .named(name)
            } else {
                algorithm = .indexed(value["distorttype"]?.intValue ?? 0)
            }
            DistortionAlgorithm.process(&mono, amount: amount, postgain: postgain,
                                        algorithm: algorithm)
        }
        if let crush = value["crush"]?.doubleValue {
            Waveshape.crush(&mono, bits: crush)
        }
        if let coarse = value["coarse"]?.doubleValue {
            Waveshape.coarse(&mono, factor: Int(coarse))
        }

        // --- Compressor (WebAudio DynamicsCompressor defaults) ---
        if let threshold = value["compressor"]?.doubleValue {
            Compressor.apply(&mono,
                             threshold: threshold,
                             ratio: value["compressorRatio"]?.doubleValue ?? 10,
                             knee: value["compressorKnee"]?.doubleValue ?? 10,
                             attack: value["compressorAttack"]?.doubleValue ?? 0.005,
                             release: value["compressorRelease"]?.doubleValue ?? 0.05,
                             sampleRate: sampleRate)
        }

        // --- Gain staging ---
        let gain = (value["gain"]?.doubleValue ?? defaultGain)
            * (value["postgain"]?.doubleValue ?? 1)
        if gain != 1 {
            for i in mono.indices { mono[i] *= Float(gain) }
        }

        // --- Sends for the shared orbit buses ---
        var result = RenderedHap(left: [], right: [])
        result.orbit = value["orbit"]?.intValue ?? 1
        if let delaySend = value["delay"]?.doubleValue, delaySend > 0 {
            result.delayTime = value["delaytime"]?.doubleValue
                ?? ((value["delaysync"]?.doubleValue ?? defaultDelaySync) / cps)
            result.delayFeedback = value["delayfeedback"]?.doubleValue ?? defaultDelayFeedback
            result.delaySend = mono.map { $0 * Float(delaySend) }
        }
        if let room = value["room"]?.doubleValue, room > 0 {
            result.roomSize = value["roomsize"]?.doubleValue ?? value["size"]?.doubleValue ?? 0.5
            result.reverbSend = mono.map { $0 * Float(room) }
        }

        // --- Pan (equal power) ---
        let pan = min(max(value["pan"]?.doubleValue ?? 0.5, 0), 1)
        let angle = pan * .pi / 2
        let lGain = Float(cos(angle))
        let rGain = Float(sin(angle))
        var left = [Float](repeating: 0, count: mono.count)
        var right = [Float](repeating: 0, count: mono.count)
        for i in mono.indices {
            left[i] = mono[i] * lGain
            right[i] = mono[i] * rGain
        }
        result.left = left
        result.right = right
        return result
    }

    /// LPF/HPF/BPF with superdough's createFilter envelope semantics:
    /// the envelope is active when any of attack/decay/sustain/release/env is
    /// set; env defaults to 1, anchor to 0;
    /// min = 2^(-offset)·f, max = 2^(|env|-offset)·f (clamped to 0..20000),
    /// swapped when env < 0; ADSR defaults [0.005, 0.14, 0, 0.1] exponential.
    static func applyFilters(_ samples: inout [Float], value: ControlMap,
                             sampleRate: Double, duration: Double) {
        func sweep(_ kind: Biquad.Kind, prefix: String, cutoff: Double, q: Double) {
            let envParams = [value["\(prefix)attack"]?.doubleValue,
                             value["\(prefix)decay"]?.doubleValue,
                             value["\(prefix)sustain"]?.doubleValue,
                             value["\(prefix)release"]?.doubleValue]
            let envDepth = value["\(prefix)env"]?.doubleValue
            let hasEnvelope = envDepth != nil || envParams.contains { $0 != nil }

            if hasEnvelope {
                let env = envDepth ?? 1
                let anchor = value["\(prefix)anchor"]?.doubleValue ?? value["fanchor"]?.doubleValue ?? 0
                let envAbs = Swift.abs(env)
                let offset = envAbs * anchor
                var minF = clamp(pow(2, -offset) * cutoff, 0, 20000)
                var maxF = clamp(pow(2, envAbs - offset) * cutoff, 0, 20000)
                if env < 0 { swap(&minF, &maxF) }
                let adsr = ADSR(attack: envParams[0], decay: envParams[1],
                                sustain: envParams[2], release: envParams[3],
                                defaults: (0.005, 0.14, 0, 0.1))
                var filter = Biquad.make(kind, frequency: minF, q: q, sampleRate: sampleRate)
                let block = 64
                var i = 0
                while i < samples.count {
                    let t = Double(i) / sampleRate
                    let e = adsr.level(at: t, holdEnd: duration)
                    // exponential interpolation between min and max
                    let f = max(minF, 0.001) * pow(max(maxF, 0.001) / max(minF, 0.001), e)
                    filter.configure(kind, frequency: f, q: q, sampleRate: sampleRate)
                    let endIdx = min(i + block, samples.count)
                    for j in i..<endIdx {
                        samples[j] = Float(filter.process(Double(samples[j])))
                    }
                    i = endIdx
                }
            } else {
                var filter = Biquad.make(kind, frequency: cutoff, q: q, sampleRate: sampleRate)
                filter.processBuffer(&samples)
            }
        }

        if let cutoff = value["cutoff"]?.doubleValue {
            sweep(.lowpass, prefix: "lp", cutoff: cutoff,
                  q: value["resonance"]?.doubleValue ?? 1)
        }
        if let hcutoff = value["hcutoff"]?.doubleValue {
            sweep(.highpass, prefix: "hp", cutoff: hcutoff,
                  q: value["hresonance"]?.doubleValue ?? 1)
        }
        if let bandf = value["bandf"]?.doubleValue {
            sweep(.bandpass, prefix: "bp", cutoff: bandf,
                  q: value["bandq"]?.doubleValue ?? 1)
        }
    }
}
