import Foundation

/// The twelve pitch classes within an octave.
///
/// Raw values follow the MIDI convention where `C == 0`, so a key's pitch
/// class is simply `midiNoteNumber % 12`.
public enum NoteName: Int, CaseIterable, Sendable {
    case c = 0, cSharp, d, dSharp, e, f, fSharp, g, gSharp, a, aSharp, b

    /// A human-readable label, e.g. `"C"` or `"F#"`.
    public var label: String {
        switch self {
        case .c: return "C"
        case .cSharp: return "C#"
        case .d: return "D"
        case .dSharp: return "D#"
        case .e: return "E"
        case .f: return "F"
        case .fSharp: return "F#"
        case .g: return "G"
        case .gSharp: return "G#"
        case .a: return "A"
        case .aSharp: return "A#"
        case .b: return "B"
        }
    }

    /// Whether this pitch class is an accidental (a black key on a piano).
    public var isSharp: Bool {
        switch self {
        case .cSharp, .dSharp, .fSharp, .gSharp, .aSharp: return true
        default: return false
        }
    }
}

/// One of the 88 keys on a standard piano.
///
/// Keys are numbered `1...88`, where key `1` is the lowest note (A0, MIDI 21)
/// and key `88` is the highest (C8, MIDI 108). The struct knows its MIDI note
/// number, its concert-pitch frequency, and its spelled name (e.g. `"A4"`).
public struct PianoKey: Hashable, Sendable {
    /// The key position on the keyboard, `1...88`.
    public let number: Int

    /// Creates a key from its 1-based keyboard position.
    public init(number: Int) {
        precondition((1...88).contains(number), "Piano key must be in 1...88, got \(number)")
        self.number = number
    }

    /// Creates a key from a pitch class and octave, e.g. `PianoKey(.a, 4)`.
    public init?(_ name: NoteName, _ octave: Int) {
        let midi = (octave + 1) * 12 + name.rawValue
        let number = midi - 20
        guard (1...88).contains(number) else { return nil }
        self.number = number
    }

    /// The MIDI note number. Key 1 (A0) is 21; key 88 (C8) is 108.
    public var midiNoteNumber: Int { number + 20 }

    /// Equal-temperament frequency in Hz, tuned to A4 = 440 Hz.
    public var frequency: Double {
        440.0 * pow(2.0, Double(midiNoteNumber - 69) / 12.0)
    }

    /// The pitch class of this key.
    public var noteName: NoteName { NoteName(rawValue: midiNoteNumber % 12)! }

    /// The scientific-pitch octave number (A4 is octave 4).
    public var octave: Int { midiNoteNumber / 12 - 1 }

    /// The spelled note name, e.g. `"C4"` or `"F#5"`.
    public var name: String { "\(noteName.label)\(octave)" }

    /// Whether this key is a black key.
    public var isSharp: Bool { noteName.isSharp }

    /// Every key on the keyboard, lowest to highest.
    public static let all: [PianoKey] = (1...88).map(PianoKey.init(number:))
}

extension PianoKey {
    /// Parses a name like `"A4"`, `"C#5"`, or `"Eb3"` into a key.
    ///
    /// Returns `nil` if the spelling is malformed or out of the piano's range.
    public init?(name rawName: String) {
        let text = rawName.trimmingCharacters(in: .whitespaces)
        guard let first = text.first else { return nil }

        let base: Int
        switch first.uppercased() {
        case "C": base = 0
        case "D": base = 2
        case "E": base = 4
        case "F": base = 5
        case "G": base = 7
        case "A": base = 9
        case "B": base = 11
        default: return nil
        }

        var index = text.index(after: text.startIndex)
        var accidental = 0
        while index < text.endIndex, text[index] == "#" || text[index] == "b" {
            accidental += text[index] == "#" ? 1 : -1
            index = text.index(after: index)
        }

        guard let octave = Int(text[index...]) else { return nil }

        let pitchClass = ((base + accidental) % 12 + 12) % 12
        guard let resolved = NoteName(rawValue: pitchClass) else { return nil }
        // Re-derive the octave the accidental may have pushed us into.
        let midi = (octave + 1) * 12 + base + accidental
        let number = midi - 20
        guard (1...88).contains(number) else { return nil }
        self = PianoKey(number: number)
        _ = resolved
    }
}

extension PianoKey: ExpressibleByStringLiteral {
    /// Lets you write keys as string literals in patterns, e.g. `Note("A4")`.
    ///
    /// Traps on an invalid spelling — use `init?(name:)` when the value may be
    /// untrusted input.
    public init(stringLiteral value: String) {
        guard let key = PianoKey(name: value) else {
            fatalError("'\(value)' is not a valid piano key name")
        }
        self = key
    }
}
