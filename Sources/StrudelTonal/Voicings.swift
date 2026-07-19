// Voicings.swift — chord symbols → voicings.
// Ported from Strudel <https://codeberg.org/uzu/strudel> (packages/tonal/voicings.mjs
// and tonleiter.mjs renderVoicing) — AGPL-3.0-or-later.

import Foundation
import StrudelCore

public struct VoicingDictionary {
    public var dictionary: [String: [String]]
    public var mode: String
    public var anchor: String
    public var range: [String]?

    public init(dictionary: [String: [String]], mode: String = "below",
                anchor: String = "c5", range: [String]? = nil) {
        self.dictionary = dictionary
        self.mode = mode
        self.anchor = anchor
        self.range = range
    }
}

private let lefthand: [String: [String]] = [
    "m7": ["3m 5P 7m 9M", "7m 9M 10m 12P"],
    "7": ["3M 6M 7m 9M", "7m 9M 10M 13M"],
    "^7": ["3M 5P 7M 9M", "7M 9M 10M 12P"],
    "69": ["3M 5P 6A 9M"],
    "m7b5": ["3m 5d 7m 8P", "7m 8P 10m 12d"],
    "7b9": ["3M 6m 7m 9m", "7m 9m 10M 13m"],
    "7b13": ["3M 6m 7m 9m", "7m 9m 10M 13m"],
    "o7": ["1P 3m 5d 6M", "5d 6M 8P 10m"],
    "7#11": ["7m 9M 11A 13A"],
    "7#9": ["3M 7m 9A"],
    "mM7": ["3m 5P 7M 9M", "7M 9M 10m 12P"],
    "m6": ["3m 5P 6M 9M", "6M 9M 10m 12P"],
]

private let guidetones: [String: [String]] = [
    "m7": ["3m 7m", "7m 10m"],
    "m9": ["3m 7m", "7m 10m"],
    "7": ["3M 7m", "7m 10M"],
    "^7": ["3M 7M", "7M 10M"],
    "^9": ["3M 7M", "7M 10M"],
    "69": ["3M 6M"],
    "6": ["3M 6M", "6M 10M"],
    "m7b5": ["3m 7m", "7m 10m"],
    "7b9": ["3M 7m", "7m 10M"],
    "7b13": ["3M 7m", "7m 10M"],
    "o7": ["3m 6M", "6M 10m"],
    "7#11": ["3M 7m", "7m 10M"],
    "7#9": ["3M 7m", "7m 10M"],
    "mM7": ["3m 7M", "7M 10m"],
    "m6": ["3m 6M", "6M 10m"],
]

private let triadDict: [String: [String]] = [
    "": ["1P 3M 5P", "3M 5P 8P", "5P 8P 10M"],
    "M": ["1P 3M 5P", "3M 5P 8P", "5P 8P 10M"],
    "m": ["1P 3m 5P", "3m 5P 8P", "5P 8P 10m"],
    "o": ["1P 3m 5d", "3m 5d 8P", "5d 8P 10m"],
    "aug": ["1P 3m 5A", "3m 5A 8P", "5A 8P 10m"],
]

private let legacyDict: [String: [String]] = triadDict.merging(lefthand) { a, _ in a }

/// Expands "-"→"m", "^"→"M", "+"→"aug" aliases and the empty major symbol,
/// mirroring voicingAlias calls at the bottom of voicings.mjs.
private func withAliases(_ dict: [String: [String]]) -> [String: [String]] {
    var out = dict
    if let major = dict["^"] { out[""] = major }
    for (symbol, voicings) in dict {
        if symbol.contains("-") { out[symbol.replacingOccurrences(of: "-", with: "m")] = voicings }
        if symbol.contains("^") { out[symbol.replacingOccurrences(of: "^", with: "M")] = voicings }
        if symbol.contains("+") { out[symbol.replacingOccurrences(of: "+", with: "aug")] = voicings }
    }
    return out
}

/// The voicing dictionary registry (name → dictionary + defaults).
public final class VoicingRegistry: @unchecked Sendable {
    public static let shared = VoicingRegistry()
    private var registry: [String: VoicingDictionary]
    private var defaultDict = "ireal"
    private let lock = NSLock()

    private init() {
        registry = [
            "lefthand": VoicingDictionary(dictionary: lefthand, mode: "below", anchor: "a4", range: ["F3", "A4"]),
            "triads": VoicingDictionary(dictionary: triadDict, mode: "below", anchor: "a4"),
            "guidetones": VoicingDictionary(dictionary: guidetones, mode: "above", anchor: "a4"),
            "legacy": VoicingDictionary(dictionary: legacyDict, mode: "below", anchor: "a4"),
            "ireal": VoicingDictionary(dictionary: withAliases(IRealData.simple)),
            "ireal-ext": VoicingDictionary(dictionary: withAliases(IRealData.complex)),
        ]
    }

    public func get(_ name: String) -> VoicingDictionary? {
        lock.lock(); defer { lock.unlock() }
        return registry[name]
    }

    public func add(_ name: String, _ dictionary: [String: [String]], range: [String]? = ["F3", "A4"]) {
        lock.lock(); defer { lock.unlock() }
        registry[name] = VoicingDictionary(dictionary: dictionary, range: range)
    }

    public var defaultName: String {
        lock.lock(); defer { lock.unlock() }
        return defaultDict
    }

    public func setDefault(_ name: String) {
        lock.lock(); defer { lock.unlock() }
        defaultDict = name
    }
}

public func addVoicings(_ name: String, _ dictionary: [String: [String]],
                        range: [String] = ["F3", "A4"]) {
    VoicingRegistry.shared.add(name, dictionary, range: range)
}

public func setDefaultVoicings(_ name: String) {
    VoicingRegistry.shared.setDefault(name)
}

// MARK: - renderVoicing (tonleiter.mjs)

struct VoicingRequest {
    var chord: String
    var dictionary: [String: [String]]
    var offset = 0
    var n: Int? = nil
    var mode = "below"
    var anchor: PatternValue = .string("c5")
    var octaves = 1
}

func renderVoicing(_ req: VoicingRequest) -> [String]? {
    guard let (root, symbol, _) = tokenizeChord(req.chord), !root.isEmpty else { return nil }
    let rootChroma = pc2chroma(root)
    guard let anchorMidi = x2midi(req.anchor, defaultOctave: 4) else { return nil }
    let anchorChroma = _mod(Int(anchorMidi), 12)
    guard let voicingStrings = req.dictionary[symbol] else { return nil }
    let voicings: [[Double]] = voicingStrings.map { v in
        v.split(separator: " ").compactMap { step2semitones(.string(String($0))) }
    }
    guard !voicings.isEmpty else { return nil }

    func modeTarget(_ v: [Double]) -> Double {
        switch req.mode {
        case "above", "root": return v.first ?? 0
        default: return v.last ?? 0  // "below", "duck"
        }
    }

    var minDistance: Int? = nil
    var bestIndex = 0
    let chromaDiffs: [Int] = voicings.enumerated().map { (i, v) in
        let targetStep = modeTarget(v)
        let diff = _mod(anchorChroma - Int(targetStep) - rootChroma, 12)
        if minDistance == nil || diff < minDistance! {
            minDistance = diff
            bestIndex = i
        }
        return diff
    }
    if req.mode == "root" { bestIndex = 0 }

    let octDiff = Int(ceil(Double(req.offset) / Double(voicings.count))) * 12
    let indexWithOffset = _mod(bestIndex + req.offset, voicings.count)
    let voicing = voicings[indexWithOffset]
    let targetStep = modeTarget(voicing)
    let anchorTarget = anchorMidi - Double(chromaDiffs[indexWithOffset]) + Double(octDiff)

    let voicingMidi = voicing.map { anchorTarget - targetStep + $0 }
    var notes = voicingMidi.map { midiToNoteName($0) }

    if req.mode == "duck" {
        notes = notes.enumerated().filter { voicingMidi[$0.offset] != anchorMidi }.map(\.element)
    }
    if let n = req.n {
        let midi = scaleStepMidi(notes.map { noteToMidi($0) }, n, octaves: req.octaves)
        return [midiToNoteName(midi)]
    }
    return notes
}

// MARK: - Pattern functions

extension Pattern {
    /// Turns chord symbols (or `chord` control values) into note voicings.
    /// `n("0 1 2").chord("<C Am F G>").voicing()`.
    public func voicing(_ dictionaryName: String? = nil) -> Pattern {
        fmap { value -> PatternValue in
            var map = value.mapValue ?? [:]
            if map.isEmpty, let chordStr = value.stringValue {
                map = ["chord": .string(chordStr)]
            }
            guard let chord = map["chord"]?.stringValue else { return .pattern(silence) }
            let dictName = dictionaryName
                ?? map["dict"]?.stringValue
                ?? VoicingRegistry.shared.defaultName
            guard let dict = VoicingRegistry.shared.get(dictName) else { return .pattern(silence) }
            var req = VoicingRequest(chord: chord, dictionary: dict.dictionary)
            req.mode = map["mode"]?.stringValue ?? dict.mode
            req.anchor = map["anchor"] ?? .string(dict.anchor)
            req.offset = map["offset"]?.intValue ?? 0
            req.n = map["n"]?.intValue
            req.octaves = map["octaves"]?.intValue ?? 1
            guard let notes = renderVoicing(req) else { return .pattern(silence) }
            // remaining controls (minus voicing controls) ride along
            var rest = map
            for key in ["chord", "dict", "anchor", "offset", "mode", "n", "octaves"] {
                rest.removeValue(forKey: key)
            }
            let notePats: [PatternValue] = notes.map { note in
                var m = rest
                m["note"] = .string(note)
                return .map(m)
            }
            return .pattern(StrudelCore.stack(notePats))
        }
        .outerJoin()
    }

    /// Deprecated legacy voicings API — smooth voice leading via the ported
    /// chord-voicings algorithm (dictionaryVoicing + minTopNoteDiff).
    public func voicings(_ dictionaryName: String = "lefthand") -> Pattern {
        voicingsLed(dictionaryName)
    }

    /// Maps chord symbols to their root notes in the given octave.
    /// `"<C^7 A7 Dm7 G7>".rootNotes(2).note()`.
    public func rootNotes(_ octave: PatternValue) -> Pattern {
        patternify(octave) { octave, pat in
            let oct = octave.intValue ?? 2
            return pat.fmap { value in
                let chordStr = value.mapValue?["chord"]?.stringValue ?? value.stringValue
                guard let chord = chordStr,
                      let (root, _, _) = tokenizeChord(chord), !root.isEmpty else { return value }
                let note = root + String(oct)
                if value.mapValue?["chord"] != nil {
                    return .map(["note": .string(note)])
                }
                return .string(note)
            }
        }
    }
}

// MARK: - chord-voicings port (dictionaryVoicing + minTopNoteDiff)
// Ported from https://github.com/felixroos/chord-voicings (MIT), the package
// used by strudel's deprecated-but-supported `voicings` function.

/// All voicings of a chord symbol whose notes fit within the note range.
func voicingsInRange(_ chord: String, dictionary: [String: [String]],
                     range: [String]) -> [[String]] {
    guard let (tonic, symbol, _) = tokenizeChord(chord), !tonic.isEmpty,
          let voicingStrings = dictionary[symbol],
          range.count >= 2,
          let rangeLow = TonalPitch.midi(range[0]),
          let rangeHigh = TonalPitch.midi(range[1]) else { return [] }

    var result: [[String]] = []
    for voicingString in voicingStrings {
        let voicing = voicingString.split(separator: " ").map(String.init)
        guard let first = voicing.first else { continue }
        // intervals relative to the first (e.g. 3m 5P → 1P 3M)
        let relativeIntervals = voicing.compactMap {
            TonalPitch.subtractIntervals($0, first)
        }
        guard relativeIntervals.count == voicing.count,
              let bottomPitchClass = TonalPitch.transpose(tonic, first),
              let bottomChroma = TonalPitch.chroma(bottomPitchClass),
              let topInterval = relativeIntervals.last else { continue }

        // every chromatic start note in range with the right pitch class
        var midi = Int(rangeLow)
        while midi <= Int(rangeHigh) {
            defer { midi += 1 }
            guard midi % 12 == bottomChroma % 12 || (midi % 12 + 12) % 12 == bottomChroma else { continue }
            // respell with the correct enharmonic pitch class
            guard let start = TonalPitch.enharmonic(midiToNoteName(Double(midi)), bottomPitchClass),
                  let topNote = TonalPitch.transpose(start, topInterval),
                  let topMidi = TonalPitch.midi(topNote),
                  topMidi <= rangeHigh else { continue }
            let notes = relativeIntervals.compactMap { TonalPitch.transpose(start, $0) }
            if notes.count == relativeIntervals.count {
                result.append(notes)
            }
        }
    }
    return result
}

/// Picks the voicing whose top note moves least from the last one.
func minTopNoteDiff(_ voicings: [[String]], lastVoicing: [String]?) -> [String]? {
    guard let firstVoicing = voicings.first else { return nil }
    guard let lastVoicing, let lastTop = lastVoicing.last,
          let lastTopMidi = TonalPitch.midi(lastTop) else { return firstVoicing }
    func diff(_ v: [String]) -> Double {
        guard let top = v.last, let m = TonalPitch.midi(top) else { return .infinity }
        return Swift.abs(lastTopMidi - m)
    }
    return voicings.reduce(firstVoicing) { best, current in
        diff(current) < diff(best) ? current : best
    }
}

/// Global voice-leading state, like the JS module-level lastVoicing.
private final class VoiceLeadingState: @unchecked Sendable {
    static let shared = VoiceLeadingState()
    private var last: [String]?
    private let lock = NSLock()
    var lastVoicing: [String]? {
        get { lock.lock(); defer { lock.unlock() }; return last }
        set { lock.lock(); defer { lock.unlock() }; last = newValue }
    }
}

/// Resets the voice-leading state (voicings.mjs resetVoicings).
public func resetVoicings() {
    VoiceLeadingState.shared.lastVoicing = nil
}

extension Pattern {
    /// Turns chord symbols into voicings with smooth voice leading: each
    /// chord picks the voicing whose top note is nearest the previous one.
    /// Port of the chord-voicings-backed `voicings` (dictionary default
    /// 'lefthand', range F3–A4).
    public func voicingsLed(_ dictionaryName: String = "lefthand") -> Pattern {
        fmap { value -> PatternValue in
            guard let chord = value.stringValue ?? value.mapValue?["chord"]?.stringValue,
                  let dict = VoicingRegistry.shared.get(dictionaryName) else {
                return .pattern(silence)
            }
            let range = dict.range ?? ["F3", "A4"]
            let candidates = voicingsInRange(chord, dictionary: dict.dictionary, range: range)
            guard let voicing = minTopNoteDiff(candidates, lastVoicing: VoiceLeadingState.shared.lastVoicing) else {
                return .pattern(silence)
            }
            VoiceLeadingState.shared.lastVoicing = voicing
            // JS voicings yields raw note strings (append .note() like in JS)
            return .pattern(StrudelCore.stack(voicing.map { .string($0) }))
        }
        .outerJoin()
    }
}
