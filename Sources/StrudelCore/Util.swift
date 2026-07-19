// Util.swift — note parsing, numeral helpers, list utilities.
// Ported from Strudel <https://codeberg.org/uzu/strudel> (packages/core/util.mjs)
// — AGPL-3.0-or-later.

import Foundation

// MARK: - Notes

/// True if the given string is a note name, e.g. "c4", "A#3", "gb", "eb-1".
public func isNote(_ name: String) -> Bool {
    tokenizeNote(name) != nil
}

/// Splits "eb3" into (pitchClass: "e", accidentals: "b", octave: 3).
/// Octave is nil when absent. Accepts accidentals #, b, s, f.
public func tokenizeNote(_ note: String) -> (pc: String, acc: String, oct: Int?)? {
    var chars = Substring(note)
    guard let first = chars.first, first.isLetter,
          "abcdefgABCDEFG".contains(first) else { return nil }
    chars = chars.dropFirst()
    var acc = ""
    while let c = chars.first, "#bsf".contains(c) {
        acc.append(c)
        chars = chars.dropFirst()
    }
    if chars.isEmpty { return (String(first), acc, nil) }
    guard let oct = Int(chars) else { return nil }
    return (String(first), acc, oct)
}

private let noteChromas: [String: Int] = ["c": 0, "d": 2, "e": 4, "f": 5, "g": 7, "a": 9, "b": 11]
private let accOffsets: [Character: Int] = ["#": 1, "b": -1, "s": 1, "f": -1]

public func accidentalsOffset(_ accidentals: String) -> Int {
    accidentals.reduce(0) { $0 + (accOffsets[$1] ?? 0) }
}

/// Turns a note name into its midi number ("c4" → 60). Traps on non-notes,
/// like the JS original — call `isNote` first when unsure.
public func noteToMidi(_ note: String, defaultOctave: Int = 3) -> Double {
    guard let (pc, acc, oct) = tokenizeNote(note),
          let chroma = noteChromas[pc.lowercased()] else {
        fatalError("not a note: \"\(note)\"")
    }
    return Double((oct ?? defaultOctave) + 1) * 12 + Double(chroma + accidentalsOffset(acc))
}

public func midiToFreq(_ n: Double) -> Double {
    pow(2, (n - 69) / 12) * 440
}

public func freqToMidi(_ freq: Double) -> Double {
    12 * log(freq / 440) / M_LN2 + 69
}

private let midiPcs = ["C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab", "A", "Bb", "B"]

public func midi2note(_ n: Int) -> String {
    let oct = Int(floor(Double(n) / 12)) - 1
    return midiPcs[_mod(n, 12)] + String(oct)
}

// MARK: - Numerals

/// Parses a numeral: a number, or a note name converted to midi.
/// Returns nil where the JS throws.
public func parseNumeral(_ value: PatternValue) -> Double? {
    switch value {
    case .number(let x): return x
    case .fraction(let f): return f.doubleValue
    case .bool(let b): return b ? 1 : 0
    case .string(let s):
        if let x = Double(s) { return x }
        if isNote(s) { return noteToMidi(s) }
        return nil
    default: return nil
    }
}

/// Wraps a numeric binary op so both args are parsed as numerals first;
/// values that can't be parsed pass through untouched on the left
/// (mirroring how JS ends up with NaN — we prefer keeping the value).
public func numeralArgs(_ f: @escaping @Sendable (Double, Double) -> Double)
    -> @Sendable (PatternValue, PatternValue) -> PatternValue {
    { a, b in
        guard let x = parseNumeral(a), let y = parseNumeral(b) else { return a }
        return .number(f(x, y))
    }
}

/// Parses "pi" and note-length shorthand used by some controls.
public func parseFractional(_ value: PatternValue) -> Double? {
    if let x = value.doubleValue { return x }
    guard let s = value.stringValue else { return nil }
    switch s {
    case "pi": return Double.pi
    case "w": return 1
    case "h": return 0.5
    case "q": return 0.25
    case "e": return 0.125
    case "s": return 0.0625
    case "t": return 1.0 / 3
    case "f": return 0.2
    case "x": return 1.0 / 6
    default: return nil
    }
}

// MARK: - Misc

/// Modulo that stays positive for negative operands: `_mod(-1, 3) == 2`.
public func _mod(_ n: Int, _ m: Int) -> Int {
    m == 0 ? 0 : ((n % m) + m) % m
}

public func _mod(_ n: Double, _ m: Double) -> Double {
    m == 0 ? 0 : (n.truncatingRemainder(dividingBy: m) + m).truncatingRemainder(dividingBy: m)
}

public func _mod(_ n: Fraction, _ m: Fraction) -> Fraction {
    n.mod(m)
}

/// Rotates an array n steps to the left.
public func rotate<T>(_ arr: [T], _ n: Int) -> [T] {
    guard !arr.isEmpty else { return arr }
    let k = _mod(n, arr.count)
    return Array(arr[k...] + arr[..<k])
}

public func listRange(_ min: Int, _ max: Int) -> [Int] {
    min <= max ? Array(min...max) : []
}

public func clamp(_ num: Double, _ min: Double, _ max: Double) -> Double {
    Swift.min(Swift.max(num, min), max)
}

/// Pairs of adjacent elements.
public func pairs<T>(_ xs: [T]) -> [(T, T)] {
    guard xs.count > 1 else { return [] }
    return (0..<(xs.count - 1)).map { (xs[$0], xs[$0 + 1]) }
}

/// Sorts fractions and removes duplicates.
public func uniqsortr(_ a: [Fraction]) -> [Fraction] {
    var out: [Fraction] = []
    for f in a.sorted() where out.last != f {
        out.append(f)
    }
    return out
}
