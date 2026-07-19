import Foundation

/// A selectable sound — the timbre used to turn a note into audio.
///
/// This is the extension point for new sound options, including future vocal
/// styles for the manual vocal synth. To add a sound:
///   1. Make a type conforming to `Voice` that renders a single note.
///   2. Add a preset for it (see the `extension Voice where Self == …` blocks
///      next to each concrete voice).
///   3. List it in `VoiceLibrary.all` so the CLI and GUI can offer it.
///
/// A voice owns its own envelope and spectral behavior, so different voices can
/// synthesize in completely different ways (simple oscillator, additive piano,
/// formant-based vocal, …) behind one interface.
public protocol Voice: Sendable {
    /// Human-readable name shown in the UI and matched by the CLI.
    var name: String { get }

    /// Renders one note into mono samples in roughly `[-1, 1]`.
    ///
    /// - Parameters:
    ///   - frequency: fundamental pitch in Hz.
    ///   - duration: how long the note is held, in seconds.
    ///   - velocity: how hard it is struck, `0...1`.
    ///   - sampleRate: output sample rate in Hz.
    /// - Returns: `duration * sampleRate` samples (may be empty for a zero-length note).
    func render(frequency: Double, duration: TimeInterval, velocity: Double, sampleRate: Double) -> [Float]
}

/// The catalogue of built-in sounds offered by the CLI and the GUI.
///
/// Append new presets to `all` and they show up everywhere automatically.
public enum VoiceLibrary {
    /// Every selectable voice, in display order.
    public static let all: [any Voice] = [
        OscillatorVoice.sine,
        OscillatorVoice.triangle,
        OscillatorVoice.square,
        OscillatorVoice.sawtooth,
        OscillatorVoice.synthVoice,
        SteinwayGrandPianoVoice.steinwayGrand,
    ]

    /// The sound used when none is specified.
    public static let `default`: any Voice = SteinwayGrandPianoVoice.steinwayGrand

    /// Looks up a voice by name (case-insensitive; exact match, then "contains").
    public static func named(_ query: String) -> (any Voice)? {
        let needle = query.lowercased()
        if let exact = all.first(where: { $0.name.lowercased() == needle }) { return exact }
        return all.first { $0.name.lowercased().contains(needle) }
    }
}
