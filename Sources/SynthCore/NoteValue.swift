import Foundation

/// A rhythmic duration, measured in quarter-note beats.
///
/// Durations are tempo-independent; the actual length in seconds is resolved
/// against a `Pattern`'s tempo at render time.
public indirect enum NoteValue: Sendable {
    case whole
    case half
    case quarter
    case eighth
    case sixteenth
    case thirtySecond
    /// 1.5× the wrapped value (a dotted note).
    case dotted(NoteValue)
    /// An explicit number of quarter-note beats.
    case beats(Double)

    /// The duration expressed in quarter-note beats.
    public var beats: Double {
        switch self {
        case .whole: return 4.0
        case .half: return 2.0
        case .quarter: return 1.0
        case .eighth: return 0.5
        case .sixteenth: return 0.25
        case .thirtySecond: return 0.125
        case .dotted(let value): return value.beats * 1.5
        case .beats(let count): return count
        }
    }
}
