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
    /// Overrides the pattern's voice for this step when non-nil.
    public var voice: (any Voice)?

    public init(content: Content, value: NoteValue, voice: (any Voice)? = nil) {
        self.content = content
        self.value = value
        self.voice = voice
    }
}

// MARK: - Declarative element factories

/// A single sounded key.
public func Note(
    _ key: PianoKey,
    _ value: NoteValue = .quarter,
    velocity: Double = 0.8,
    voice: (any Voice)? = nil
) -> Step {
    Step(content: .tone(keys: [key], velocity: velocity), value: value, voice: voice)
}

/// Several keys sounded together.
public func Chord(
    _ keys: [PianoKey],
    _ value: NoteValue = .quarter,
    velocity: Double = 0.8,
    voice: (any Voice)? = nil
) -> Step {
    Step(content: .tone(keys: keys, velocity: velocity), value: value, voice: voice)
}

/// Silence for the given duration.
public func Rest(_ value: NoteValue = .quarter) -> Step {
    Step(content: .rest, value: value)
}

// MARK: - Result builder

/// Lets patterns be written declaratively, with control flow:
///
/// ```swift
/// Pattern(tempo: 120, voice: .steinwayGrand) {
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

/// A declarative, tempo-based sequence of notes, chords, and rests, played with
/// a chosen `Voice`.
public struct Pattern: Sendable {
    /// Beats per minute (a quarter note per beat).
    public var tempo: Double
    /// The sound used for steps that don't override it.
    public var voice: any Voice
    /// The ordered events.
    public var steps: [Step]

    public init(
        tempo: Double = 120,
        voice: any Voice = OscillatorVoice.sine,
        @PatternBuilder steps: () -> [Step]
    ) {
        self.tempo = tempo
        self.voice = voice
        self.steps = steps()
    }

    /// Designated initializer for building patterns programmatically.
    public init(
        tempo: Double = 120,
        voice: any Voice = OscillatorVoice.sine,
        steps: [Step]
    ) {
        self.tempo = tempo
        self.voice = voice
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
        voice: any Voice = OscillatorVoice.sine
    ) -> Pattern {
        Pattern(tempo: tempo, voice: voice, steps: [Note(key, value)])
    }
}
