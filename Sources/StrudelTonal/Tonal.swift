// Tonal.swift — scales, transposition, and scale-aware pattern functions.
// Ported from Strudel <https://codeberg.org/uzu/strudel> (packages/tonal/tonal.mjs
// and tonleiter.mjs) — AGPL-3.0-or-later.

import Foundation
import StrudelCore

// MARK: - Scale lookup

public struct ScaleInfo {
    public let tonic: String?
    public let type: String
    public let intervals: [String]
    public var notes: [String] {
        guard let tonic else { return [] }
        return intervals.compactMap { TonalPitch.transpose(tonic, $0) }
    }
}

public enum ScaleError: Error, CustomStringConvertible {
    case incomplete(String)
    case invalid(String)
    public var description: String {
        switch self {
        case .incomplete(let name):
            return "Scale name \(name) is incomplete. Make sure to use \":\" instead of spaces, example: .scale(\"C:major\")"
        case .invalid(let name):
            return "Invalid scale name \"\(name)\""
        }
    }
}

/// Splits "C4 bebop major" into tonic ("C4") and type ("bebop major").
func tokenizeScale(_ name: String) -> (tonic: String?, type: String) {
    let parts = name.split(separator: " ").map(String.init)
    guard let first = parts.first else { return (nil, "") }
    if PitchNote(first) != nil, isNote(first) {
        return (first, parts.dropFirst().joined(separator: " "))
    }
    return (nil, parts.joined(separator: " "))
}

func getScale(_ scaleName: String) throws -> ScaleInfo {
    let cleaned = scaleName.replacingOccurrences(of: ":", with: " ")
    let (tonic, type) = tokenizeScale(cleaned)
    guard let intervals = ScaleData.intervals[type] else {
        if isNote(cleaned) || tonic == nil {
            throw ScaleError.incomplete(cleaned)
        }
        throw ScaleError.invalid(cleaned)
    }
    return ScaleInfo(tonic: tonic, type: type, intervals: intervals)
}

private func octavesInterval(_ octaves: Int) -> String {
    "\((octaves <= 0 ? -1 : 1) + octaves * 7)P"
}

/// The note for a (possibly negative) step in a scale, octave-wrapping.
func scaleStepNote(_ step: Int, _ scale: String) throws -> String {
    let info = try getScale(scale)
    let tonic = info.tonic ?? "C"
    let parsed = PitchNote(tonic)
    let pc = parsed.map { PitchNote(step: $0.step, alt: $0.alt, oct: nil).name } ?? "C"
    let oct = parsed?.oct ?? 3
    let count = info.intervals.count
    let octaveOffset = Int(floor(Double(step) / Double(count)))
    let scaleStep = _mod(step, count)
    let interval = TonalPitch.addIntervals(info.intervals[scaleStep], octavesInterval(octaveOffset))
        ?? info.intervals[scaleStep]
    return TonalPitch.transpose(pc + String(oct), interval) ?? pc
}

/// Transposes a note inside a scale by the given number of scale steps.
func scaleOffset(_ scale: String, _ offset: Int, _ note: String) throws -> String {
    let info = try getScale(scale)
    let notes = info.notes.compactMap { PitchNote($0) }
        .map { PitchNote(step: $0.step, alt: $0.alt, oct: nil).name }
    guard let parsed = PitchNote(note) else {
        throw ScaleError.invalid(note)
    }
    let fromPc = PitchNote(step: parsed.step, alt: parsed.alt, oct: nil).name
    let oct = parsed.oct ?? 3
    guard let noteIndex = notes.firstIndex(of: fromPc) else {
        throw ScaleError.invalid("note \"\(note)\" is not in scale \"\(scale)\"")
    }
    var i = noteIndex
    var o = oct
    var n = fromPc
    let direction = offset < 0 ? -1 : 1
    while abs(i - noteIndex) < abs(offset) {
        i += direction
        let index = _mod(i, notes.count)
        if direction < 0 && n.first == "C" { o += direction }
        n = notes[index]
        if direction > 0 && n.first == "C" { o += direction }
    }
    return n + String(o)
}

// MARK: - Nearest-note quantization (for scale() applied to notes)

private final class ScaleNoteCache: @unchecked Sendable {
    private var cache: [String: ([Double], [String])] = [:]
    private let lock = NSLock()

    func midisAndNotes(_ scaleName: String) throws -> ([Double], [String]) {
        lock.lock(); defer { lock.unlock() }
        if let hit = cache[scaleName] { return hit }
        let info = try getScale(scaleName)
        let tonic = info.tonic ?? "C"
        let pcName = PitchNote(tonic).map { PitchNote(step: $0.step, alt: $0.alt, oct: nil).name } ?? "C"
        let expanded = info.intervals + ["8P"]  // add the octave for wrapping
        let sNotes = expanded.compactMap { TonalPitch.transpose(pcName + "0", $0) }
        let sMidi = sNotes.map { noteToMidi($0) }
        cache[scaleName] = (sMidi, sNotes)
        return (sMidi, sNotes)
    }
}

private let scaleNoteCache = ScaleNoteCache()

func nearestNumberIndex(_ target: Double, _ numbers: [Double], preferHigher: Bool) -> Int {
    var bestIndex = 0
    var bestDiff = Double.infinity
    for (i, s) in numbers.enumerated() {
        let diff = abs(s - target)
        if (!preferHigher && diff < bestDiff) || (preferHigher && diff <= bestDiff) {
            bestIndex = i
            bestDiff = diff
        }
    }
    return bestIndex
}

func nearestScaleNote(_ scaleName: String, _ note: PatternValue, preferHigher: Bool = true) throws -> String {
    let noteMidi: Double
    if let s = note.stringValue, isNote(s) {
        noteMidi = noteToMidi(s)
    } else if let d = note.doubleValue {
        noteMidi = d
    } else {
        throw ScaleError.invalid("\(note)")
    }
    let (scaleMidis, scaleNotes) = try scaleNoteCache.midisAndNotes(scaleName)
    let rootMidi = scaleMidis[0]
    let octaveDiff = Int(floor((noteMidi - rootMidi) / 12))
    let aligned = scaleMidis.map { $0 + 12 * Double(octaveDiff) }
    let idx = nearestNumberIndex(noteMidi, aligned, preferHigher: preferHigher)
    let match = scaleNotes[idx]
    return TonalPitch.transpose(match, TonalPitch.fromSemitones(12 * octaveDiff)) ?? match
}

// MARK: - Step decoration ("4#", "-2b")

/// Converts a decorated step ("4#", "-2b") to (number, semitone offset).
func convertStepToNumberAndOffset(_ step: PatternValue) throws -> (Int, Int) {
    if let d = step.doubleValue {
        return (Int(ceil(d)), 0)
    }
    guard let s = step.stringValue,
          let m = s.range(of: #"^(-?\d+)([#bsf]*)$"#, options: .regularExpression) else {
        throw ScaleError.invalid("invalid scale step \"\(step)\"")
    }
    let matched = String(s[m])
    let digits = matched.prefix { "-0123456789".contains($0) }
    let accidentals = String(matched.dropFirst(digits.count))
    return (Int(digits) ?? 0, accidentalsOffset(accidentals))
}

// MARK: - Pattern functions

extension Pattern {
    /// Changes the pitch of each value by a number of semitones or an interval
    /// string ("3M", "-5P", …), preserving enharmonics for note-name values.
    public func transpose(_ amount: PatternValue) -> Pattern {
        patternify(amount) { amount, pat in
            pat.withHap { hap in
                let noteVal = hap.value.mapValue?["note"] ?? hap.value
                let isObject = hap.value.mapValue != nil

                func replace(_ newNote: PatternValue) -> Hap {
                    if isObject {
                        var m = hap.value.mapValue!
                        m["note"] = newNote
                        return hap.withValue { _ in .map(m) }
                    }
                    return hap.withValue { _ in newNote }
                }

                if let num = noteVal.doubleValue, noteVal.stringValue == nil {
                    // numeric note: add semitones
                    let semitones: Double
                    if let d = amount.doubleValue, amount.stringValue == nil || Double(amount.stringValue!) != nil {
                        semitones = d
                    } else if let s = amount.stringValue {
                        semitones = Double(TonalPitch.semitones(s) ?? 0)
                    } else {
                        semitones = 0
                    }
                    return replace(.number(num + semitones))
                }
                guard let noteStr = noteVal.stringValue, isNote(noteStr) else {
                    return hap
                }
                // note is a string; preserve enharmonics when possible
                let interval: String
                if let d = amount.doubleValue, amount.stringValue == nil || Double(amount.stringValue!) != nil {
                    interval = TonalPitch.fromSemitones(Int(d))
                } else {
                    interval = amount.stringValue ?? "1P"
                }
                let target = TonalPitch.transpose(noteStr, interval) ?? noteStr
                return replace(.string(target))
            }
        }
    }

    public func trans(_ amount: PatternValue) -> Pattern { transpose(amount) }

    /// Transposes notes inside the scale set by `.scale(...)`.
    public func scaleTranspose(_ offset: PatternValue) -> Pattern {
        patternify(offset) { offset, pat in
            pat.withHap { hap in
                guard let scaleName = hap.context.scale else { return hap }
                let steps = offset.intValue ?? 0
                if let m = hap.value.mapValue, let note = m["note"]?.stringValue {
                    if let transposed = try? scaleOffset(scaleName, steps, note) {
                        var out = m
                        out["note"] = .string(transposed)
                        return hap.withValue { _ in .map(out) }
                    }
                    return hap
                }
                if let note = hap.value.stringValue,
                   let transposed = try? scaleOffset(scaleName, steps, note) {
                    return hap.withValue { _ in .string(transposed) }
                }
                return hap
            }
        }
    }

    public func scaleTrans(_ offset: PatternValue) -> Pattern { scaleTranspose(offset) }

    /// Turns numbers into notes in the scale (zero-indexed), or quantizes
    /// note values to the scale. `n("0 2 4").scale("C:major")`.
    public func scale(_ scaleValue: PatternValue) -> Pattern {
        patternify(scaleValue, preserveSteps: true) { scaleValue, pat in
            // mini ':' lists arrive as list values ("C:major")
            let scaleName: String
            if let list = scaleValue.listValue {
                scaleName = list.map { $0.description }.joined(separator: " ")
            } else {
                scaleName = scaleValue.stringValue ?? scaleValue.description
            }
            return pat.withHaps { haps, _ in
                haps.compactMap { hap in
                    let isObject = hap.value.mapValue != nil
                    let hVal = hap.value.mapValue ?? ["n": hap.value]
                    var otherValues = hVal
                    otherValues.removeValue(forKey: "note")
                    otherValues.removeValue(forKey: "n")
                    otherValues.removeValue(forKey: "value")
                    guard let noteOrStep = hVal["note"] ?? hVal["n"] ?? hVal["value"] else {
                        return hap
                    }
                    var scaleNote: String
                    if let s = noteOrStep.stringValue, isNote(s) {
                        // Note case: quantize to scale
                        guard let nearest = try? nearestScaleNote(scaleName, noteOrStep) else { return nil }
                        scaleNote = nearest
                    } else {
                        // Step case: convert scale degree to note
                        guard let (number, offset) = try? convertStepToNumberAndOffset(noteOrStep) else { return nil }
                        if let anchor = otherValues["anchor"],
                           let midi = stepInNamedScale(step: number, scale: scaleName, anchor: anchor) {
                            var out = otherValues
                            out["note"] = .number(midi + Double(offset))
                            var ctx = hap.context
                            ctx.scale = scaleName
                            return Hap(whole: hap.whole, part: hap.part,
                                       value: isObject ? .map(out) : out["note"]!,
                                       context: ctx)
                        }
                        guard var note = try? scaleStepNote(number, scaleName) else { return nil }
                        if offset != 0 {
                            note = TonalPitch.transpose(note, TonalPitch.fromSemitones(offset)) ?? note
                        }
                        scaleNote = note
                    }
                    var ctx = hap.context
                    ctx.scale = scaleName
                    if isObject {
                        var out = otherValues
                        out["note"] = .string(scaleNote)
                        return Hap(whole: hap.whole, part: hap.part, value: .map(out), context: ctx)
                    }
                    return Hap(whole: hap.whole, part: hap.part, value: .string(scaleNote), context: ctx)
                }
            }
        }
    }
}

// MARK: - tonleiter helpers (chroma math used by voicings)

let flatPcs = ["C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab", "A", "Bb", "B"]
let sharpPcs = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

public func pc2chroma(_ pc: String) -> Int {
    guard let parsed = PitchNote(pc) else { return 0 }
    return ((PitchNote.stepSemitones[parsed.step] + parsed.alt) % 12 + 12) % 12
}

public func chroma2pc(_ chroma: Int, sharp: Bool = false) -> String {
    (sharp ? sharpPcs : flatPcs)[_mod(chroma, 12)]
}

/// Splits "Ab^7/C" into (root, symbol, bass).
public func tokenizeChord(_ chord: String) -> (root: String, symbol: String, bass: String?)? {
    guard let m = chord.range(of: #"^([A-G][b#]*)([^/]*)[/]?([A-G][b#]*)?$"#,
                              options: .regularExpression) else { return nil }
    let s = String(chord[m])
    var root = ""
    var idx = s.startIndex
    if idx < s.endIndex, s[idx].isLetter, "ABCDEFG".contains(s[idx]) {
        root.append(s[idx])
        idx = s.index(after: idx)
        while idx < s.endIndex, s[idx] == "b" || s[idx] == "#" {
            root.append(s[idx])
            idx = s.index(after: idx)
        }
    }
    let restStr = String(s[idx...])
    let parts = restStr.split(separator: "/", maxSplits: 1, omittingEmptySubsequences: false)
    let symbol = parts.isEmpty ? "" : String(parts[0])
    let bass = parts.count > 1 ? String(parts[1]) : nil
    return (root, symbol, bass)
}

public func step2semitones(_ x: PatternValue) -> Double? {
    if let n = x.doubleValue, x.stringValue == nil || Double(x.stringValue!) != nil {
        return n
    }
    guard let s = x.stringValue else { return nil }
    if let n = Double(s) { return n }
    return TonalPitch.semitones(s).map(Double.init)
}

func x2midi(_ x: PatternValue, defaultOctave: Int = 3) -> Double? {
    if let s = x.stringValue, isNote(s) {
        return noteToMidi(s, defaultOctave: defaultOctave)
    }
    return x.doubleValue
}

/// midi → note name, flats by default.
public func midiToNoteName(_ midi: Double, sharp: Bool = false) -> String {
    let m = Int(midi.rounded())
    let oct = Int(floor(Double(m) / 12)) - 1
    return (sharp ? sharpPcs : flatPcs)[_mod(m, 12)] + String(oct)
}

/// The midi note for a step in a list of notes, octave-wrapping.
func scaleStepMidi(_ notes: [Double], _ offset: Int, octaves: Int = 1) -> Double {
    guard !notes.isEmpty else { return 0 }
    let octOffset = Int(floor(Double(offset) / Double(notes.count))) * octaves * 12
    return notes[_mod(offset, notes.count)] + Double(octOffset)
}

/// Steps through a named scale, expressed in midi numbers.
public func stepInNamedScale(step: Int, scale: String, anchor: PatternValue?,
                             preferHigher: Bool = false) -> Double? {
    let (rootTok, scaleName) = tokenizeScale(scale.replacingOccurrences(of: ":", with: " "))
    guard let root = rootTok, let rootMidi = x2midi(.string(root)) else { return nil }
    let rootChroma = _mod(Int(rootMidi), 12)
    guard let intervals = ScaleData.intervals[scaleName] else { return nil }
    let steps = intervals.compactMap { TonalPitch.semitones($0).map(Double.init) }
    var step = step
    var transpose = rootMidi
    if let anchor, let anchorMidi = x2midi(anchor, defaultOctave: 3) {
        let anchorChroma = _mod(Int(anchorMidi), 12)
        let anchorDiff = Double(_mod(anchorChroma - rootChroma, 12))
        let zeroIndex = nearestNumberIndex(anchorDiff, steps, preferHigher: preferHigher)
        step += zeroIndex
        transpose = anchorMidi - anchorDiff
    }
    let octOffset = Int(floor(Double(step) / Double(steps.count))) * 12
    let idx = _mod(step, steps.count)
    return steps[idx] + transpose + Double(octOffset)
}
