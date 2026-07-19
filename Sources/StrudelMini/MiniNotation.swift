// MiniNotation.swift — the mini-notation parser.
// Ported from Strudel <https://codeberg.org/uzu/strudel> (packages/mini/krill.pegjs
// and packages/mini/mini.mjs) — AGPL-3.0-or-later.
//
// A hand-written recursive-descent implementation of the krill PEG grammar:
//   sequences        "bd sd hh"
//   sub-cycles       "[bd sd] hh"
//   slow sequences   "<bd sd>"
//   polymeter        "{bd sd, hh hh hh}%4"
//   stacks           "bd, hh hh"
//   random choice    "bd | sd"
//   dot groups       "bd sd . hh"
//   weight/elongate  "bd@3 sd" / "bd _ _ sd"
//   replicate        "bd!3"
//   euclid           "bd(3,8,1)"
//   fast/slow        "bd*2 sd/2"
//   degrade          "bd? sd?0.7"
//   tail (lists)     "bd:3"
//   ranges           "0 .. 7"

import Foundation
import StrudelCore

// MARK: - AST

indirect enum MiniNode {
    case atom(String)
    case pattern(MiniPatternNode)
}

final class MiniPatternNode {
    var source: [MiniElement]
    var alignment: String  // "fastcat" | "stack" | "rand" | "feet" | "polymeter" | "polymeter_slowcat"
    var seed: Int?
    var stepsMarker = false        // '^' prefix
    var stepsPerCycle: MiniElement? = nil  // polymeter %n

    init(source: [MiniElement], alignment: String, seed: Int? = nil) {
        self.source = source
        self.alignment = alignment
        self.seed = seed
    }
}

final class MiniElement {
    var source: MiniNode
    var ops: [MiniOp] = []
    var weight: Fraction = .one
    var reps = 1

    init(_ source: MiniNode) {
        self.source = source
    }
}

enum MiniOp {
    case stretch(amount: MiniElement, type: String)  // "fast" | "slow"
    case replicate(amount: Int)
    case bjorklund(pulse: MiniElement, step: MiniElement, rotation: MiniElement?)
    case degradeBy(amount: Double?, seed: Int)
    case tail(element: MiniElement)
    case range(element: MiniElement)
}

// MARK: - Errors

public struct MiniNotationError: Error, CustomStringConvertible {
    public let message: String
    public let position: Int
    public var description: String { "[mini] parse error at position \(position): \(message)" }
}

// MARK: - Parser

final class MiniParser {
    private let chars: [Character]
    private var pos = 0
    /// Per-parse seed counter (krill's `seed++`).
    private var seed = 0

    init(_ input: String) {
        self.chars = Array(input)
    }

    func parse() throws -> MiniNode {
        let result = try stackOrChoose()
        skipWs()
        guard pos >= chars.count else {
            throw error("unexpected character '\(chars[pos])'")
        }
        return result
    }

    // MARK: primitives

    private func error(_ message: String) -> MiniNotationError {
        MiniNotationError(message: message, position: pos)
    }

    private var atEnd: Bool { pos >= chars.count }

    private func peek() -> Character? {
        pos < chars.count ? chars[pos] : nil
    }

    private func advance() -> Character? {
        guard pos < chars.count else { return nil }
        defer { pos += 1 }
        return chars[pos]
    }

    private func match(_ c: Character) -> Bool {
        if peek() == c { pos += 1; return true }
        return false
    }

    private func skipWs() {
        while let c = peek(), c == " " || c == "\n" || c == "\r" || c == "\t" || c == "\u{00A0}" {
            pos += 1
        }
    }

    private static func isStepChar(_ c: Character) -> Bool {
        c.isLetter || c.isNumber || c == "~" || c == "-" || c == "#" || c == "." || c == "^" || c == "_"
    }

    /// Parses a JSON-style number; returns nil (restoring position) on failure.
    private func number() -> Double? {
        let start = pos
        var s = ""
        if match("-") { s = "-" }
        var digits = false
        while let c = peek(), c.isNumber { s.append(c); pos += 1; digits = true }
        if !digits { pos = start; return nil }
        // frac: don't consume ".." (range operator)
        if peek() == ".", pos + 1 < chars.count, chars[pos + 1].isNumber {
            s.append("."); pos += 1
            while let c = peek(), c.isNumber { s.append(c); pos += 1 }
        }
        if let c = peek(), c == "e" || c == "E" {
            let expStart = pos
            var e = String(c); pos += 1
            if let sign = peek(), sign == "+" || sign == "-" { e.append(sign); pos += 1 }
            var expDigits = false
            while let c2 = peek(), c2.isNumber { e.append(c2); pos += 1; expDigits = true }
            if expDigits { s += e } else { pos = expStart }
        }
        return Double(s)
    }

    // MARK: grammar rules

    /// step = ws step_char+ ws (but not "." or "_" alone)
    private func step() -> MiniNode? {
        let start = pos
        skipWs()
        var s = ""
        // Don't let a step swallow the ".." range operator or a lone "." / "_".
        while let c = peek(), MiniParser.isStepChar(c) {
            if c == "." {
                // ".." is the range op; "." followed by non-step-char is a dot group.
                if pos + 1 < chars.count, chars[pos + 1] == "." { break }
                if s.isEmpty && !(pos + 1 < chars.count && chars[pos + 1].isNumber) { break }
            }
            s.append(c)
            pos += 1
        }
        if s.isEmpty || s == "." || s == "_" || s == "^" {
            pos = start
            return nil
        }
        skipWs()
        return .atom(s)
    }

    /// sub_cycle = "[" stack_or_choose "]"
    private func subCycle() throws -> MiniNode? {
        let start = pos
        skipWs()
        guard match("[") else { pos = start; return nil }
        skipWs()
        let s = try stackOrChoose()
        skipWs()
        guard match("]") else { throw error("expected ']'") }
        skipWs()
        return s
    }

    /// polymeter = "{" polymeter_stack "}" ("%" slice)?
    private func polymeter() throws -> MiniNode? {
        let start = pos
        skipWs()
        guard match("{") else { pos = start; return nil }
        skipWs()
        let node = try polymeterStack(alignment: "polymeter")
        skipWs()
        guard match("}") else { throw error("expected '}'") }
        if match("%") {
            guard let steps = try slice() else { throw error("expected steps after '%'") }
            if case .pattern(let p) = node {
                p.stepsPerCycle = MiniElement(steps)
            }
        }
        skipWs()
        return node
    }

    /// slow_sequence = "<" polymeter_stack ">" (alignment becomes polymeter_slowcat)
    private func slowSequence() throws -> MiniNode? {
        let start = pos
        skipWs()
        guard match("<") else { pos = start; return nil }
        skipWs()
        let node = try polymeterStack(alignment: "polymeter_slowcat")
        skipWs()
        guard match(">") else { throw error("expected '>'") }
        skipWs()
        return node
    }

    /// slice = step / sub_cycle / polymeter / slow_sequence
    private func slice() throws -> MiniNode? {
        if let s = step() { return s }
        if let s = try subCycle() { return s }
        if let s = try polymeter() { return s }
        if let s = try slowSequence() { return s }
        return nil
    }

    /// slice_with_ops = slice slice_op*
    private func sliceWithOps() throws -> MiniElement? {
        guard let s = try slice() else { return nil }
        let element = MiniElement(s)
        while try sliceOp(element) {}
        return element
    }

    /// One slice op; returns false when none matches.
    private func sliceOp(_ x: MiniElement) throws -> Bool {
        let start = pos
        skipWs()

        // op_weight: ("@" / "_") number?
        if let c = peek(), c == "@" || c == "_" {
            pos += 1
            let a = number() ?? 2
            x.weight = x.weight.add(Fraction(a)).sub(.one)
            return true
        }
        pos = start

        // op_replicate: "!" number?  (supports both x!4 and x!!!)
        skipWs()
        if match("!") {
            let a = number() ?? 2
            let reps = x.reps + Int(a) - 1
            x.reps = reps
            x.ops.removeAll { if case .replicate = $0 { return true }; return false }
            x.ops.append(.replicate(amount: reps))
            x.weight = Fraction(reps)
            return true
        }
        pos = start

        // op_bjorklund: "(" slice_with_ops "," slice_with_ops ("," slice_with_ops?)? ")"
        if match("(") {
            skipWs()
            guard let p = try sliceWithOps() else { throw error("expected euclid pulses") }
            skipWs()
            guard match(",") else { throw error("expected ',' in euclid") }
            skipWs()
            guard let s = try sliceWithOps() else { throw error("expected euclid steps") }
            skipWs()
            var r: MiniElement? = nil
            if match(",") {
                skipWs()
                r = try sliceWithOps()
            }
            skipWs()
            guard match(")") else { throw error("expected ')'") }
            x.ops.append(.bjorklund(pulse: p, step: s, rotation: r))
            return true
        }

        // op_slow: "/" slice
        if match("/") {
            guard let a = try slice() else { throw error("expected slice after '/'") }
            x.ops.append(.stretch(amount: MiniElement(a), type: "slow"))
            return true
        }

        // op_fast: "*" slice
        if match("*") {
            guard let a = try slice() else { throw error("expected slice after '*'") }
            x.ops.append(.stretch(amount: MiniElement(a), type: "fast"))
            return true
        }

        // op_degrade: "?" number?
        if match("?") {
            let a = number()
            x.ops.append(.degradeBy(amount: a, seed: seed))
            seed += 1
            return true
        }

        // op_tail: ":" slice
        if match(":") {
            guard let s = try slice() else { throw error("expected slice after ':'") }
            x.ops.append(.tail(element: MiniElement(s)))
            return true
        }

        // op_range: ".." slice
        if peek() == ".", pos + 1 < chars.count, chars[pos + 1] == "." {
            pos += 2
            guard let s = try slice() else { throw error("expected slice after '..'") }
            x.ops.append(.range(element: MiniElement(s)))
            return true
        }

        pos = start
        return false
    }

    /// sequence = '^'? slice_with_ops+
    private func sequence() throws -> MiniPatternNode? {
        let start = pos
        skipWs()
        let stepsMarker = match("^")
        var slices: [MiniElement] = []
        while let s = try sliceWithOps() {
            slices.append(s)
        }
        guard !slices.isEmpty else {
            pos = start
            return nil
        }
        let node = MiniPatternNode(source: slices, alignment: "fastcat")
        node.stepsMarker = stepsMarker
        return node
    }

    /// stack_or_choose = sequence ((',' sequence)+ / ('|' sequence)+ / ('.' sequence)+)?
    private func stackOrChoose() throws -> MiniNode {
        guard let head = try sequence() else {
            throw error("expected sequence")
        }
        skipWs()

        if peek() == "," {
            var list: [MiniPatternNode] = [head]
            while matchDelimiter(",") {
                guard let next = try sequence() else { throw error("expected sequence after ','") }
                list.append(next)
            }
            return .pattern(wrapPatterns(list, alignment: "stack"))
        }

        if peek() == "|" {
            var list: [MiniPatternNode] = [head]
            while matchDelimiter("|") {
                guard let next = try sequence() else { throw error("expected sequence after '|'") }
                list.append(next)
            }
            let node = wrapPatterns(list, alignment: "rand")
            node.seed = seed
            seed += 1
            return .pattern(node)
        }

        if isDotDelimiter() {
            var list: [MiniPatternNode] = [head]
            while matchDotDelimiter() {
                guard let next = try sequence() else { throw error("expected sequence after '.'") }
                list.append(next)
            }
            if list.count > 1 {
                let node = wrapPatterns(list, alignment: "feet")
                node.seed = seed
                seed += 1
                return .pattern(node)
            }
        }

        return .pattern(head)
    }

    /// polymeter_stack = sequence (',' sequence)*
    private func polymeterStack(alignment: String) throws -> MiniNode {
        guard let head = try sequence() else {
            throw error("expected sequence")
        }
        var list: [MiniPatternNode] = [head]
        skipWs()
        while matchDelimiter(",") {
            guard let next = try sequence() else { throw error("expected sequence after ','") }
            list.append(next)
        }
        return .pattern(wrapPatterns(list, alignment: alignment))
    }

    private func matchDelimiter(_ c: Character) -> Bool {
        let start = pos
        skipWs()
        if match(c) {
            skipWs()
            return true
        }
        pos = start
        return false
    }

    private func isDotDelimiter() -> Bool {
        let start = pos
        defer { pos = start }
        skipWs()
        guard peek() == "." else { return false }
        // ".." would be a range; a bare "." must not be followed by "."
        return !(pos + 1 < chars.count && chars[pos + 1] == ".")
    }

    private func matchDotDelimiter() -> Bool {
        let start = pos
        skipWs()
        if peek() == ".", !(pos + 1 < chars.count && chars[pos + 1] == ".") {
            pos += 1
            skipWs()
            return true
        }
        pos = start
        return false
    }

    /// Wraps sub-patterns as elements of a combined pattern node.
    private func wrapPatterns(_ list: [MiniPatternNode], alignment: String) -> MiniPatternNode {
        let elements = list.map { MiniElement(.pattern($0)) }
        return MiniPatternNode(source: elements, alignment: alignment)
    }
}

// MARK: - AST → Pattern (port of mini.mjs patternifyAST)

private let randOffset = 0.0003

private func enterNode(_ node: MiniNode) -> Pattern {
    switch node {
    case .atom(let source):
        if source == "~" || source == "-" {
            return silence
        }
        if let num = Double(source) {
            return pure(.number(num))
        }
        return pure(.string(source))
    case .pattern(let p):
        return patternifyNode(p)
    }
}

private func enterElement(_ element: MiniElement) -> Pattern {
    applyOptions(enterNode(element.source), element)
}

private func applyOptions(_ pat: Pattern, _ element: MiniElement) -> Pattern {
    var pat = pat
    let stepsSource = pat.stepsSource
    for op in element.ops {
        switch op {
        case .stretch(let amount, let type):
            let amountPat = enterElement(amount)
            pat = type == "fast" ? pat.fast(.pattern(amountPat)) : pat.slow(.pattern(amountPat))
        case .replicate(let amount):
            pat = pat._repeatCycles(amount)._fast(Fraction(amount))
        case .bjorklund(let pulse, let step, let rotation):
            if let rotation {
                pat = pat.euclidRot(.pattern(enterElement(pulse)),
                                    .pattern(enterElement(step)),
                                    .pattern(enterElement(rotation)))
            } else {
                pat = pat.euclid(.pattern(enterElement(pulse)),
                                 .pattern(enterElement(step)))
            }
        case .degradeBy(let amount, let opSeed):
            pat = pat._degradeByWith(rand._early(Fraction(randOffset * Double(opSeed))),
                                     amount ?? 0.5)
        case .tail(let element):
            let friend = enterElement(element)
            pat = pat.fmap { a in
                PatternValue.function { b in
                    if let list = a.listValue {
                        return .list(list + [b])
                    }
                    return .list([a, b])
                }
            }.appLeft(friend)
        case .range(let element):
            let friend = enterElement(element)
            pat = pat.squeezeBind { a in
                friend.bind { b in
                    let start = a.intValue ?? 0
                    let stop = b.intValue ?? 0
                    let values = start <= stop
                        ? Array(start...stop)
                        : Array((stop...start).reversed())
                    return fastcat(values.map { PatternValue.number(Double($0)) })
                }
            }
        }
    }
    pat.stepsSource = pat.stepsSource || stepsSource
    return pat
}

private func lcmSteps(_ pats: [Pattern]) -> Fraction? {
    var result: Fraction? = nil
    for pat in pats {
        guard let s = pat.steps else { continue }
        result = result.map { $0.lcm(s) } ?? s
    }
    return result
}

func patternifyNode(_ ast: MiniPatternNode) -> Pattern {
    let children = ast.source.map(enterElement)
    let withSteps = children.filter { $0.stepsSource }
    var pat: Pattern

    switch ast.alignment {
    case "stack":
        pat = stack(children.map { .pattern($0) })
        if !withSteps.isEmpty {
            pat.setSteps(lcmSteps(withSteps))
        }

    case "polymeter_slowcat":
        pat = stack(children.map { child in
            .pattern(child._slow(child.weightHint ?? .one))
        })
        if !withSteps.isEmpty {
            pat.setSteps(lcmSteps(withSteps))
        }

    case "polymeter":
        let stepsPerCycle: Pattern
        if let spc = ast.stepsPerCycle {
            stepsPerCycle = enterElement(spc)
        } else {
            stepsPerCycle = pure(.fraction(children.first?.weightHint ?? .one))
        }
        let aligned = children.map { child -> PatternValue in
            let weight = child.weightHint ?? .one
            return .pattern(child.fast(.pattern(stepsPerCycle.fmap { x in
                .fraction((x.fractionValue ?? .one).div(weight))
            })))
        }
        pat = stack(aligned)

    case "rand":
        let seed = ast.seed ?? 0
        pat = chooseInWith(
            rand._early(Fraction(randOffset * Double(seed)))._segment(.one),
            children.map { .pattern($0) }
        )
        if !withSteps.isEmpty {
            pat.setSteps(lcmSteps(withSteps))
        }

    case "feet":
        pat = fastcat(children.map { .pattern($0) })

    default:  // "fastcat"
        // Elements always carry a weight (default 1), so the JS code path is
        // always the weighted timeCat.
        let weightSum = ast.source.reduce(Fraction.zero) { $0.add($1.weight) }
        pat = stepcat(ast.source.enumerated().map { (i, element) in
            (element.weight, PatternValue.pattern(children[i]))
        })
        pat.weightHint = weightSum
        pat.setSteps(weightSum)
        if !withSteps.isEmpty, let steps = pat.steps, let inner = lcmSteps(withSteps) {
            pat.setSteps(steps.mul(inner))
        }
        if ast.stepsMarker {
            pat.stepsSource = true
        }
    }

    if !withSteps.isEmpty {
        pat.stepsSource = true
    }
    return pat
}

// MARK: - Public API

/// Parses a mini-notation string into a pattern.
public func mini(_ strings: String...) throws -> Pattern {
    let pats = try strings.map { str -> PatternValue in
        let ast = try MiniParser(str).parse()
        return .pattern(enterNode(ast))
    }
    return pats.count == 1 ? reify(pats[0]) : sequence(pats)
}

/// Non-throwing variant used as the global string parser; parse errors log
/// and return silence (matching the REPL behavior).
public func miniOrSilence(_ str: String) -> Pattern {
    do {
        return try mini(str)
    } catch {
        print("\(error)")
        return silence
    }
}

/// Causes all strings in patterns to be parsed as mini notation.
public func miniAllStrings() {
    StrudelRuntime.stringParser = { miniOrSilence($0) }
}

/// Installs the mini-notation parser as the global string parser.
public func installMiniNotation() {
    miniAllStrings()
}
