// ZzFX.swift — the ZzFX micro-synth.
// Ported from Strudel <https://codeberg.org/uzu/strudel>
// (packages/superdough/zzfx.mjs + zzfx_fork.mjs, itself from
// https://github.com/KilledByAPixel/ZzFX by Frank Force, MIT) — AGPL-3.0-or-later.

import Foundation
import StrudelCore

/// Direct port of zzfx_fork.mjs buildSamples.
func zzfxBuildSamples(
    volume: Double = 1,
    randomness: Double = 0.05,
    frequency frequencyIn: Double = 220,
    attack attackIn: Double = 0,
    sustain sustainIn: Double = 0,
    release releaseIn: Double = 0.1,
    shape: Int = 0,
    shapeCurve: Double = 1,
    slide slideIn: Double = 0,
    deltaSlide deltaSlideIn: Double = 0,
    pitchJump pitchJumpIn: Double = 0,
    pitchJumpTime pitchJumpTimeIn: Double = 0,
    repeatTime repeatTimeIn: Double = 0,
    noise: Double = 0,
    modulation modulationIn: Double = 0,
    bitCrush: Double = 0,
    delay delayIn: Double = 0,
    sustainVolume: Double = 1,
    decay decayIn: Double = 0,
    tremolo: Double = 0,
    sampleRate: Double
) -> [Float] {
    let PI2 = Double.pi * 2
    func sign(_ v: Double) -> Double { v > 0 ? 1 : -1 }

    var slide = slideIn * (500 * PI2) / sampleRate / sampleRate
    let startSlide = slide
    var frequency = frequencyIn * ((1 + randomness * 2 * Double.random(in: 0..<1) - randomness) * PI2) / sampleRate
    var startFrequency = frequency

    let attack = attackIn * sampleRate + 9  // minimum attack to prevent pop
    let decay = decayIn * sampleRate
    let sustain = sustainIn * sampleRate
    let release = releaseIn * sampleRate
    let delay = delayIn * sampleRate
    let deltaSlide = deltaSlideIn * (500 * PI2) / pow(sampleRate, 3)
    let modulation = modulationIn * PI2 / sampleRate
    let pitchJump = pitchJumpIn * PI2 / sampleRate
    let pitchJumpTime = pitchJumpTimeIn * sampleRate
    let repeatTime = Int(repeatTimeIn * sampleRate)

    let length = Int(attack + decay + sustain + release + delay)
    guard length > 0 else { return [] }
    var b = [Float](repeating: 0, count: length)

    var t = 0.0
    var tm = 0.0
    var j = 1.0
    var r = 0
    var c = 0
    var s = 0.0

    for i in 0..<length {
        c += 1
        let crushPeriod = Int(bitCrush * 100)
        if crushPeriod == 0 || c % crushPeriod == 0 {
            // wave shape
            switch shape {
            case 0: s = Foundation.sin(t)
            case 1: s = 1 - 4 * Swift.abs((t / PI2).rounded() - t / PI2)  // triangle
            case 2: s = 1 - _mod((2 * t) / PI2, 2)  // saw
            case 3: s = Swift.max(Swift.min(Foundation.tan(t), 1), -1)  // tan
            default: s = Foundation.sin(pow(_mod(t, PI2), 3))  // noise
            }

            let trem = repeatTime != 0
                ? 1 - tremolo + tremolo * Foundation.sin((PI2 * Double(i)) / Double(repeatTime))
                : 1
            let env: Double
            let di = Double(i)
            if di < attack {
                env = di / attack
            } else if di < attack + decay {
                env = 1 - ((di - attack) / decay) * (1 - sustainVolume)
            } else if di < attack + decay + sustain {
                env = sustainVolume
            } else if di < Double(length) - delay {
                env = ((Double(length) - di - delay) / release) * sustainVolume
            } else {
                env = 0
            }
            s = trem * sign(s) * pow(Swift.abs(s), shapeCurve) * volume * env

            if delay > 0 {
                let echoIndex = Int(di - delay)
                let echo = delay > di ? 0
                    : (di < Double(length) - delay ? 1 : (Double(length) - di) / delay)
                    * Double(echoIndex >= 0 && echoIndex < length ? b[echoIndex] : 0) / 2
                s = s / 2 + echo
            }
        }

        slide += deltaSlide
        frequency += slide
        let f = frequency * Foundation.cos(modulation * tm)
        tm += 1
        t += f - f * noise * (1 - _mod((Foundation.sin(Double(i)) + 1) * 1e9, 2))

        if j != 0 {
            j += 1
            if j > pitchJumpTime {
                frequency += pitchJump
                startFrequency += pitchJump
                j = 0
            }
        }

        if repeatTime != 0 {
            r += 1
            if r % repeatTime == 0 {
                frequency = startFrequency
                slide = startSlide
                if j == 0 { j = 1 }
            }
        }

        b[i] = Float(s)
    }
    return b
}

/// The zzfx sounds: `s("z_sawtooth")` etc. — value controls map to the zzfx
/// parameter list exactly as in zzfx.mjs.
struct ZzfxSound: SoundSource {
    let name: String

    func render(params: SoundParams, sampleRate: Double) -> [Float] {
        let value = params.value
        let shapeName = name.replacingOccurrences(of: "z_", with: "")
        let shape = max(["sine", "triangle", "sawtooth", "tan", "noise"].firstIndex(of: shapeName) ?? 0, 0)
        var curve = value["curve"]?.doubleValue ?? 1
        if shapeName == "square" { curve = 0 }

        let attack = value["attack"]?.doubleValue ?? 0
        let decay = value["decay"]?.doubleValue ?? 0
        let sustainLevel = value["sustain"]?.doubleValue ?? 0.8
        let release = value["release"]?.doubleValue ?? 0.1
        let sustainTime = max(params.duration - attack - decay, 0)

        let out = zzfxBuildSamples(
            volume: 0.25,
            randomness: value["zrand"]?.doubleValue ?? 0,
            frequency: params.frequency,
            attack: attack,
            sustain: sustainTime,
            release: release,
            shape: shape,
            shapeCurve: curve,
            slide: value["slide"]?.doubleValue ?? 0,
            deltaSlide: value["deltaSlide"]?.doubleValue ?? 0,
            pitchJump: value["pitchJump"]?.doubleValue ?? 0,
            pitchJumpTime: value["pitchJumpTime"]?.doubleValue ?? 0,
            repeatTime: value["lfo"]?.doubleValue ?? 0,
            noise: value["znoise"]?.doubleValue ?? 0,
            modulation: value["zmod"]?.doubleValue ?? 0,
            bitCrush: value["zcrush"]?.doubleValue ?? 0,
            delay: value["zdelay"]?.doubleValue ?? 0,
            sustainVolume: sustainLevel,
            decay: decay,
            tremolo: value["tremolo"]?.doubleValue ?? 0,
            sampleRate: sampleRate
        )
        guard params.velocity != 1 else { return out }
        return out.map { $0 * Float(params.velocity) }
    }
}
