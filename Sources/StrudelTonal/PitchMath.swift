// PitchMath.swift — enharmonically-correct note/interval arithmetic.
// A compact port of the @tonaljs pitch algebra (MIT) used by strudel's tonal
// package: notes and intervals as [fifths, octaves] coordinates.

import Foundation

/// A parsed note: step (0=C..6=B), alteration, optional octave.
struct PitchNote {
    var step: Int
    var alt: Int
    var oct: Int?

    static let stepSemitones = [0, 2, 4, 5, 7, 9, 11]
    static let letters = ["C", "D", "E", "F", "G", "A", "B"]

    /// Parses "C", "eb3", "F##-1". Accidentals: # b s f.
    init?(_ name: String) {
        var rest = Substring(name)
        guard let first = rest.first,
              let step = "CDEFGAB".firstIndex(of: Character(first.uppercased())) else { return nil }
        self.step = "CDEFGAB".distance(from: "CDEFGAB".startIndex, to: step)
        rest = rest.dropFirst()
        var alt = 0
        while let c = rest.first, "#bsf".contains(c) {
            alt += (c == "#" || c == "s") ? 1 : -1
            rest = rest.dropFirst()
        }
        self.alt = alt
        if rest.isEmpty {
            self.oct = nil
        } else if let o = Int(rest) {
            self.oct = o
        } else {
            return nil
        }
    }

    init(step: Int, alt: Int, oct: Int?) {
        self.step = step
        self.alt = alt
        self.oct = oct
    }

    var name: String {
        let acc = alt < 0 ? String(repeating: "b", count: -alt)
                          : String(repeating: "#", count: alt)
        return PitchNote.letters[step] + acc + (oct.map(String.init) ?? "")
    }

    var midi: Double? {
        guard let oct else { return nil }
        return Double((oct + 1) * 12 + PitchNote.stepSemitones[step] + alt)
    }

    var chroma: Int {
        ((PitchNote.stepSemitones[step] + alt) % 12 + 12) % 12
    }
}

/// A parsed interval: e.g. "3m", "5P", "-2M", "12P", "4A", "7dd".
struct PitchInterval {
    var num: Int       // signed interval number (non-zero)
    var quality: String
    var step: Int      // 0-based simple step
    var alt: Int
    var oct: Int
    var dir: Int       // 1 or -1

    static let perfectables: Set<Int> = [0, 3, 4]  // unison, fourth, fifth

    init?(_ name: String) {
        // number first ("5P"); tonal also allows quality-first ("P5")
        let pattern = #"^([-+]?\d+)(d{1,4}|m|M|P|A{1,4})$"#
        let alt = #"^(d{1,4}|m|M|P|A{1,4})([-+]?\d+)$"#
        var numStr: String?
        var q: String?
        if let m = name.range(of: pattern, options: .regularExpression) {
            let full = String(name[m])
            let qStart = full.firstIndex { !"-+0123456789".contains($0) }!
            numStr = String(full[full.startIndex..<qStart])
            q = String(full[qStart...])
        } else if let m = name.range(of: alt, options: .regularExpression) {
            let full = String(name[m])
            let nStart = full.firstIndex { "-+0123456789".contains($0) }!
            q = String(full[full.startIndex..<nStart])
            numStr = String(full[nStart...])
        }
        guard let numStr, let q, let n = Int(numStr), n != 0 else { return nil }
        self.init(num: n, quality: q)
    }

    init?(num: Int, quality: String) {
        self.num = num
        self.quality = quality
        self.dir = num < 0 ? -1 : 1
        let m = abs(num) - 1
        self.step = m % 7
        self.oct = m / 7
        let perfectable = PitchInterval.perfectables.contains(step)
        switch quality {
        case "M": if perfectable { return nil }; self.alt = 0
        case "P": if !perfectable { return nil }; self.alt = 0
        case "m": if perfectable { return nil }; self.alt = -1
        default:
            if quality.allSatisfy({ $0 == "A" }) {
                self.alt = quality.count
            } else if quality.allSatisfy({ $0 == "d" }) {
                self.alt = perfectable ? -quality.count : -(quality.count + 1)
            } else {
                return nil
            }
        }
    }

    init(step: Int, alt: Int, oct: Int, dir: Int) {
        self.step = step
        self.alt = alt
        self.oct = oct
        self.dir = dir
        self.num = dir * (step + 1 + 7 * oct)
        let perfectable = PitchInterval.perfectables.contains(step)
        if alt == 0 {
            self.quality = perfectable ? "P" : "M"
        } else if alt == -1 && !perfectable {
            self.quality = "m"
        } else if alt > 0 {
            self.quality = String(repeating: "A", count: alt)
        } else {
            self.quality = String(repeating: "d", count: perfectable ? -alt : -alt - 1)
        }
    }

    var name: String { "\(num)\(quality)" }

    var semitones: Int {
        dir * (PitchNote.stepSemitones[step] + alt + 12 * oct)
    }

    /// Interval for a (signed) number of semitones, e.g. 4 → "3M".
    static func fromSemitones(_ semitones: Int) -> PitchInterval {
        let d = semitones < 0 ? -1 : 1
        let n = abs(semitones)
        let c = n % 12
        let o = n / 12
        let nums = [1, 2, 2, 3, 3, 4, 5, 5, 6, 6, 7, 7]
        let quals = ["P", "m", "M", "m", "M", "P", "d", "P", "m", "M", "m", "M"]
        return PitchInterval(num: d * (nums[c] + 7 * o), quality: quals[c])!
    }
}

// MARK: - Coordinate encoding (fifths/octaves)

private let fifthsOfStep = [0, 2, 4, -1, 1, 3, 5]
private let stepsToOcts = fifthsOfStep.map { Int(floor(Double($0 * 7) / 12)) }
private let fifthsToSteps = [3, 0, 4, 1, 5, 2, 6]

private func encodeNote(_ p: PitchNote) -> (Int, Int?) {
    let f = fifthsOfStep[p.step] + 7 * p.alt
    guard let oct = p.oct else { return (f, nil) }
    return (f, oct - stepsToOcts[p.step] - 4 * p.alt)
}

private func encodeInterval(_ i: PitchInterval) -> (Int, Int) {
    let f = fifthsOfStep[i.step] + 7 * i.alt
    let o = i.oct - stepsToOcts[i.step] - 4 * i.alt
    return (i.dir * f, i.dir * o)
}

private func decodeNote(_ f: Int, _ o: Int?) -> PitchNote {
    // tonal's `unaltered`: index by (f + 1) mod 7
    let step = fifthsToSteps[(((f + 1) % 7) + 7) % 7]
    let alt = Int(floor(Double(f + 1) / 7))
    guard let o else { return PitchNote(step: step, alt: alt, oct: nil) }
    return PitchNote(step: step, alt: alt, oct: o + 4 * alt + stepsToOcts[step])
}

private func decodeInterval(_ f: Int, _ o: Int) -> PitchInterval {
    // Force descending intervals into ascending form to name them, keep dir.
    let isDescending = f * 7 + o * 12 < 0
    let (ff, oo, dir) = isDescending ? (-f, -o, -1) : (f, o, 1)
    let step = fifthsToSteps[(((ff + 1) % 7) + 7) % 7]
    let alt = Int(floor(Double(ff + 1) / 7))
    let oct = oo + 4 * alt + stepsToOcts[step]
    return PitchInterval(step: step, alt: alt, oct: oct, dir: dir)
}

// MARK: - Public operations (Note.transpose, Interval.add)

enum TonalPitch {
    /// Transposes a note by an interval, enharmonically correct.
    /// ("C4", "3M") → "E4"; ("D", "3M") → "F#".
    static func transpose(_ note: String, _ interval: String) -> String? {
        guard let n = PitchNote(note), let i = PitchInterval(interval) else { return nil }
        let (nf, no) = encodeNote(n)
        let (f, o) = encodeInterval(i)
        if let no {
            return decodeNote(nf + f, no + o).name
        }
        return decodeNote(nf + f, nil).name
    }

    /// Adds two intervals: ("3m", "5P") → "7m".
    static func addIntervals(_ a: String, _ b: String) -> String? {
        guard let ia = PitchInterval(a), let ib = PitchInterval(b) else { return nil }
        let (fa, oa) = encodeInterval(ia)
        let (fb, ob) = encodeInterval(ib)
        return decodeInterval(fa + fb, oa + ob).name
    }

    static func semitones(_ interval: String) -> Int? {
        PitchInterval(interval)?.semitones
    }

    static func fromSemitones(_ n: Int) -> String {
        PitchInterval.fromSemitones(n).name
    }
}

extension TonalPitch {
    /// Subtracts two intervals: ("7m", "3m") → "5P".
    static func subtractIntervals(_ a: String, _ b: String) -> String? {
        guard let ia = PitchInterval(a), let ib = PitchInterval(b) else { return nil }
        let (fa, oa) = encodeIntervalCoord(ia)
        let (fb, ob) = encodeIntervalCoord(ib)
        return decodeIntervalCoord(fa - fb, oa - ob).name
    }

    /// Respells `note` with the pitch class of `target`, keeping the midi
    /// value (tonal Note.enharmonic).
    static func enharmonic(_ note: String, _ targetPc: String) -> String? {
        guard let n = PitchNote(note), let midi = n.midi,
              let pc = PitchNote(targetPc) else { return nil }
        // octave such that (oct+1)*12 + chroma' == midi, where chroma' may
        // exceed [0,12) for spellings like B# or Cb
        let chromaUnwrapped = PitchNote.stepSemitones[pc.step] + pc.alt
        let oct = (Int(midi) - chromaUnwrapped) / 12 - 1
        return PitchNote(step: pc.step, alt: pc.alt, oct: oct).name
    }

    static func midi(_ note: String) -> Double? {
        PitchNote(note)?.midi
    }

    static func chroma(_ note: String) -> Int? {
        PitchNote(note)?.chroma
    }
}

// internal encode/decode access for interval arithmetic
func encodeIntervalCoord(_ i: PitchInterval) -> (Int, Int) {
    let fifthsOfStep = [0, 2, 4, -1, 1, 3, 5]
    let stepsToOcts = fifthsOfStep.map { Int(floor(Double($0 * 7) / 12)) }
    let f = fifthsOfStep[i.step] + 7 * i.alt
    let o = i.oct - stepsToOcts[i.step] - 4 * i.alt
    return (i.dir * f, i.dir * o)
}

func decodeIntervalCoord(_ f: Int, _ o: Int) -> PitchInterval {
    let fifthsOfStep = [0, 2, 4, -1, 1, 3, 5]
    let stepsToOcts = fifthsOfStep.map { Int(floor(Double($0 * 7) / 12)) }
    let fifthsToSteps = [3, 0, 4, 1, 5, 2, 6]
    let isDescending = f * 7 + o * 12 < 0
    let (ff, oo, dir) = isDescending ? (-f, -o, -1) : (f, o, 1)
    let step = fifthsToSteps[(((ff + 1) % 7) + 7) % 7]
    let alt = Int(floor(Double(ff + 1) / 7))
    let oct = oo + 4 * alt + stepsToOcts[step]
    return PitchInterval(step: step, alt: alt, oct: oct, dir: dir)
}
