import Foundation

/// A single event in a pattern: either a sounded tone (one or more keys held
/// together) or a rest, with a rhythmic duration.
public struct Step: Sendable {
    public enum Content: Sendable {
        /// One key is a note; several keys are a chord.
        case tone(keys: [PianoKey], velocity: Double)
        case rest
    }

    public var content: Content
    public var value: NoteValue
    /// Overrides the pattern's waveform for this step when non-nil.
    public var waveform: Waveform?

    public init(content: Content, value: NoteValue, waveform: Waveform? = nil) {
        self.content = content
        self.value = value
        self.waveform = waveform
    }
}

// MARK: - Declarative element factories

/// A single sounded key.
public func Note(
    _ key: PianoKey,
    _ value: NoteValue = .quarter,
    velocity: Double = 0.8,
    waveform: Waveform? = nil
) -> Step {
    Step(content: .tone(keys: [key], velocity: velocity), value: value, waveform: waveform)
}

/// Several keys sounded together.
public func Chord(
    _ keys: [PianoKey],
    _ value: NoteValue = .quarter,
    velocity: Double = 0.8,
    waveform: Waveform? = nil
) -> Step {
    Step(content: .tone(keys: keys, velocity: velocity), value: value, waveform: waveform)
}

/// Silence for the given duration.
public func Rest(_ value: NoteValue = .quarter) -> Step {
    Step(content: .rest, value: value)
}

// MARK: - Result builder

/// Lets patterns be written declaratively, with control flow:
///
/// ```swift
/// Pattern(tempo: 120, waveform: .voice) {
///     Note("C4", .quarter)
///     Chord(["C4", "E4", "G4"], .half)
///     for name in ["D4", "E4", "F4"] { Note(name, .eighth) }
/// }
/// ```
@resultBuilder
public enum PatternBuilder {
    public static func buildExpression(_ expression: Step) -> [Step] { [expression] }
    public static func buildExpression(_ expression: [Step]) -> [Step] { expression }
    public static func buildBlock(_ components: [Step]...) -> [Step] { components.flatMap { $0 } }
    public static func buildArray(_ components: [[Step]]) -> [Step] { components.flatMap { $0 } }
    public static func buildOptional(_ component: [Step]?) -> [Step] { component ?? [] }
    public static func buildEither(first component: [Step]) -> [Step] { component }
    public static func buildEither(second component: [Step]) -> [Step] { component }
}

/// A declarative, tempo-based sequence of notes, chords, and rests.
public struct Pattern: Sendable {
    /// Beats per minute (a quarter note per beat).
    public var tempo: Double
    /// Default timbre for steps that don't override it.
    public var waveform: Waveform
    /// Amplitude envelope applied to every tone.
    public var envelope: Envelope
    /// The ordered events.
    public var steps: [Step]

    public init(
        tempo: Double = 120,
        waveform: Waveform = .sine,
        envelope: Envelope = .default,
        @PatternBuilder steps: () -> [Step]
    ) {
        self.tempo = tempo
        self.waveform = waveform
        self.envelope = envelope
        self.steps = steps()
    }

    /// Designated initializer for building patterns programmatically.
    public init(
        tempo: Double = 120,
        waveform: Waveform = .sine,
        envelope: Envelope = .default,
        steps: [Step]
    ) {
        self.tempo = tempo
        self.waveform = waveform
        self.envelope = envelope
        self.steps = steps
    }

    /// The total length of the pattern in seconds.
    public var duration: TimeInterval {
        let beatDuration = 60.0 / tempo
        return steps.reduce(0.0) { $0 + $1.value.beats * beatDuration }
    }

    /// A one-shot pattern containing a single key — handy for interactive
    /// playback (e.g. a key press in the GUI).
    public static func single(
        _ key: PianoKey,
        value: NoteValue = .quarter,
        tempo: Double = 120,
        waveform: Waveform = .sine
    ) -> Pattern {
        Pattern(tempo: tempo, waveform: waveform, steps: [Note(key, value, waveform: waveform)])
    }
}
