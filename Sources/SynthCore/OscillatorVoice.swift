import Foundation

/// A simple "oscillator + ADSR envelope" voice. It covers the basic waveforms
/// and is the easiest template to copy when adding a new synthesized sound.
public struct OscillatorVoice: Voice {
    public let name: String
    public var waveform: Waveform
    public var envelope: Envelope

    public init(name: String, waveform: Waveform, envelope: Envelope = .default) {
        self.name = name
        self.waveform = waveform
        self.envelope = envelope
    }

    public func render(
        frequency: Double,
        duration: TimeInterval,
        velocity: Double,
        sampleRate: Double
    ) -> [Float] {
        let frames = max(0, Int(duration * sampleRate))
        guard frames > 0 else { return [] }

        var out = [Float](repeating: 0, count: frames)
        var phase = 0.0
        let increment = frequency / sampleRate

        for i in 0..<frames {
            let env = envelope.amplitude(atFrame: i, totalFrames: frames, sampleRate: sampleRate)
            out[i] = Float(waveform.sample(phase: phase) * velocity * env)
            phase += increment
            if phase >= 1 { phase -= 1 }
        }
        return out
    }
}

extension Voice where Self == OscillatorVoice {
    public static var sine: OscillatorVoice { OscillatorVoice(name: "Sine", waveform: .sine) }
    public static var triangle: OscillatorVoice { OscillatorVoice(name: "Triangle", waveform: .triangle) }
    public static var square: OscillatorVoice { OscillatorVoice(name: "Square", waveform: .square) }
    public static var sawtooth: OscillatorVoice { OscillatorVoice(name: "Sawtooth", waveform: .sawtooth) }
    public static var synthVoice: OscillatorVoice { OscillatorVoice(name: "Synth Voice", waveform: .voice) }
}
