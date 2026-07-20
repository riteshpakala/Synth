// PatternScript.swift — a runtime interpreter for the Swift-flavored pattern DSL.
// Powers the app's live-coding pad: chained expressions over the Strudel API,
// evaluated instantly so code edits and slider tweaks hot-swap the running
// pattern. Part of the Swift port of Strudel — AGPL-3.0-or-later.
//
//     note("c3 [e3 g3]*2").s("sawtooth").lpf(800).every(4) { $0.rev() }
//
// Dispatch is table-driven for combinators and generic for all 494 controls
// (via Controls.alias), so the pad speaks the whole API.

import Foundation
import StrudelCore
import StrudelMini
import StrudelTonal

// MARK: - Public API

public enum PatternScript {
    /// Evaluates DSL source into a playable pattern.
    public static func evaluate(_ source: String) throws -> StrudelCore.Pattern {
        let expr = try ScriptParser(source).parseProgram()
        let value = try ScriptEvaluator().evaluate(expr, dollar: nil)
        return try value.asPattern()
    }

    /// The tuneable numeric literals in the source, in order of appearance.
    public static func tunables(in source: String) -> [Tunable] {
        guard let expr = try? ScriptParser(source).parseProgram() else { return [] }
        var found: [Tunable] = []
        collectTunables(expr, context: nil, into: &found)
        // Stable ids: context name + ordinal among same-context tunables, so
        // SwiftUI sliders keep identity when values (and offsets) change.
        var counts: [String: Int] = [:]
        return found.map { t in
            let ordinal = counts[t.context, default: 0]
            counts[t.context] = ordinal + 1
            var out = t
            out.id = "\(t.context)#\(ordinal)"
            return out
        }
    }

    /// Rewrites the tunable's literal in the source with a new value.
    public static func replacing(_ tunable: Tunable, with newValue: Double,
                                 in source: String) -> String {
        let chars = Array(source)
        guard tunable.sourceRange.lowerBound >= 0,
              tunable.sourceRange.upperBound <= chars.count else { return source }
        let formatted = format(newValue, isInt: tunable.integer)
        let prefix = String(chars[..<tunable.sourceRange.lowerBound])
        let suffix = String(chars[tunable.sourceRange.upperBound...])
        return prefix + formatted + suffix
    }

    public static func format(_ value: Double, isInt: Bool) -> String {
        if isInt || value == value.rounded() {
            return String(Int(value.rounded()))
        }
        return String(format: "%.3g", value)
    }
}

/// A numeric literal the UI can put a slider on.
public struct Tunable: Identifiable, Equatable {
    public var id: String = ""
    /// The call the number is an argument of ("lpf", "fast", …).
    public let context: String
    public let value: Double
    /// Character-offset range of the literal in the source.
    public let sourceRange: Range<Int>
    public let range: ClosedRange<Double>
    /// Whether the slider should snap to whole numbers.
    public let integer: Bool

    public var label: String { context }
}

public struct PatternScriptError: Error, CustomStringConvertible {
    public let message: String
    public let position: Int
    public var description: String { message }
}

// MARK: - Tunable ranges (heuristics per control/combinator)

private let intContexts: Set<String> = [
    "n", "euclid", "euclidRot", "euclidLegato", "iter", "iterBack", "every",
    "firstOf", "lastOf", "chop", "striate", "segment", "seg", "ply", "chunk",
    "chunkBack", "fastChunk", "echo", "stut", "shuffle", "scramble", "crush",
    "coarse", "orbit", "octave", "off",
]

private func tunableRange(context: String, value: Double) -> ClosedRange<Double> {
    switch context {
    case "lpf", "cutoff", "hpf", "hcutoff", "bandf", "phasercenter":
        return 20...8000
    case "gain", "velocity", "room", "delay", "delayfeedback", "pan", "begin",
         "end", "shape", "distortvol", "postgain", "wt", "sustain", "degradeBy",
         "undegradeBy", "sometimesBy", "someCyclesBy", "juxBy", "swingBy":
        return 0...1
    case "size", "roomsize":
        return 0...10
    case "fast", "hurry", "density":
        return 0.25...16
    case "slow", "sparsity", "linger":
        return 0.25...16
    case "cpm":
        return 10...240
    case "speed":
        return 0.25...4
    case "attack", "decay", "release", "delaytime", "lpd", "lpa":
        return 0...2
    case "lpenv", "hpenv", "bpenv":
        return -8...8
    case "note", "add", "sub", "transpose", "detune":
        return (value - 24)...(value + 24)
    case "n":
        return 0...16
    case "distort", "soft", "hard", "cubic", "diode", "asym", "fold",
         "sinefold", "chebyshev", "scurve":
        return 0...5
    case "crush":
        return 1...16
    case "coarse":
        return 1...32
    case "vib", "phaser", "phaserrate":
        return 0...12
    case "euclid", "euclidRot", "euclidLegato":
        return 1...16
    case "every", "iter", "iterBack", "chunk", "firstOf", "lastOf",
         "chop", "striate", "segment", "seg", "shuffle", "scramble":
        return 1...16
    case "echo", "stut", "ply":
        return 1...8
    case "off", "early", "late":
        return 0...1
    default:
        let hi = Swift.max(1, Swift.abs(value) * 4)
        return value < 0 ? -hi...hi : 0...hi
    }
}

// MARK: - AST

indirect enum ScriptExpr {
    case number(Double, range: Range<Int>)
    case string(String)
    case bool(Bool)
    case list([ScriptExpr])
    /// Free call (`note(...)`), bare identifier (`rev`, `sine`), or method
    /// call when `target` is set (`x.fast(2)`).
    case call(name: String, args: [ScriptExpr], target: ScriptExpr?)
    /// `{ $0.rev().fast(2) }`
    case closure(ScriptExpr)
    /// `$0` inside a closure
    case dollar
}

// MARK: - Tokenizer + parser

final class ScriptParser {
    private let chars: [Character]
    private var pos = 0

    init(_ source: String) {
        self.chars = Array(source)
    }

    func parseProgram() throws -> ScriptExpr {
        skipTrivia()
        let expr = try parseExpr()
        skipTrivia()
        guard pos >= chars.count else {
            throw err("unexpected '\(chars[pos])'")
        }
        return expr
    }

    // MARK: primitives

    private func err(_ message: String) -> PatternScriptError {
        PatternScriptError(message: message, position: pos)
    }

    private func peek() -> Character? { pos < chars.count ? chars[pos] : nil }

    private func match(_ c: Character) -> Bool {
        skipTrivia()
        if peek() == c { pos += 1; return true }
        return false
    }

    private func expect(_ c: Character) throws {
        guard match(c) else { throw err("expected '\(c)'") }
    }

    private func skipTrivia() {
        while pos < chars.count {
            let c = chars[pos]
            if c.isWhitespace {
                pos += 1
            } else if c == "/", pos + 1 < chars.count, chars[pos + 1] == "/" {
                while pos < chars.count, chars[pos] != "\n" { pos += 1 }
            } else {
                break
            }
        }
    }

    // MARK: grammar

    private func parseExpr() throws -> ScriptExpr {
        var expr = try parsePrimary()
        // postfix chains: .name, .name(args), .name(args) { closure }
        while true {
            skipTrivia()
            guard peek() == "." else { break }
            // don't confuse a chained call with a number like `.5`
            if pos + 1 < chars.count, chars[pos + 1].isNumber { break }
            pos += 1
            let name = try parseIdentifier()
            let args = try parseArgumentsIfAny()
            expr = .call(name: name, args: args, target: expr)
        }
        return expr
    }

    private func parsePrimary() throws -> ScriptExpr {
        skipTrivia()
        guard let c = peek() else { throw err("unexpected end of input") }
        switch c {
        case "\"":
            return .string(try parseStringLiteral())
        case "[":
            pos += 1
            var items: [ScriptExpr] = []
            skipTrivia()
            if !match("]") {
                repeat {
                    items.append(try parseExpr())
                } while match(",")
                try expect("]")
            }
            return .list(items)
        case "(":
            pos += 1
            let inner = try parseExpr()
            try expect(")")
            return inner
        case "{":
            return try parseClosure()
        case "$":
            if pos + 1 < chars.count, chars[pos + 1] == "0" {
                pos += 2
                return .dollar
            }
            throw err("expected $0")
        default:
            if c.isNumber || c == "-" || c == "." {
                return try parseNumber()
            }
            if c.isLetter || c == "_" {
                let name = try parseIdentifier()
                if name == "true" { return .bool(true) }
                if name == "false" { return .bool(false) }
                let args = try parseArgumentsIfAny()
                return .call(name: name, args: args, target: nil)
            }
            throw err("unexpected '\(c)'")
        }
    }

    /// `(a, b) { closure }` — both parts optional; a lone trailing closure
    /// also counts (Swift style).
    private func parseArgumentsIfAny() throws -> [ScriptExpr] {
        var args: [ScriptExpr] = []
        skipTrivia()
        if peek() == "(" {
            pos += 1
            skipTrivia()
            if !match(")") {
                repeat {
                    args.append(try parseExpr())
                } while match(",")
                try expect(")")
            }
        }
        skipTrivia()
        if peek() == "{" {
            args.append(try parseClosure())
        }
        return args
    }

    private func parseClosure() throws -> ScriptExpr {
        try expect("{")
        skipTrivia()
        // optional Swift-style `pat in` intro is not supported; $0 only
        let body = try parseExpr()
        try expect("}")
        return .closure(body)
    }

    private func parseIdentifier() throws -> String {
        skipTrivia()
        var s = ""
        while let c = peek(), c.isLetter || c.isNumber || c == "_" {
            s.append(c)
            pos += 1
        }
        guard !s.isEmpty else { throw err("expected identifier") }
        return s
    }

    private func parseStringLiteral() throws -> String {
        try expect("\"")
        var s = ""
        while let c = peek(), c != "\"" {
            if c == "\\", pos + 1 < chars.count {
                pos += 1
                s.append(chars[pos])
            } else {
                s.append(c)
            }
            pos += 1
        }
        try expect("\"")
        return s
    }

    private func parseNumber() throws -> ScriptExpr {
        skipTrivia()
        let start = pos
        var s = ""
        if peek() == "-" { s = "-"; pos += 1 }
        while let c = peek(), c.isNumber { s.append(c); pos += 1 }
        if peek() == "." {
            // `.` only continues a number when followed by a digit
            if pos + 1 < chars.count, chars[pos + 1].isNumber {
                s.append("."); pos += 1
                while let c = peek(), c.isNumber { s.append(c); pos += 1 }
            }
        }
        guard let value = Double(s), !s.isEmpty, s != "-" else {
            pos = start
            throw err("expected number")
        }
        return .number(value, range: start..<pos)
    }
}

// MARK: - Tunable collection

private func collectTunables(_ expr: ScriptExpr, context: String?, into out: inout [Tunable]) {
    switch expr {
    case .number(let value, let range):
        guard let context else { break }
        out.append(Tunable(
            context: context,
            value: value,
            sourceRange: range,
            range: tunableRange(context: context, value: value),
            integer: intContexts.contains(context) || value == value.rounded()
        ))
    case .list(let items):
        for item in items { collectTunables(item, context: context, into: &out) }
    case .call(let name, let args, let target):
        if let target { collectTunables(target, context: context, into: &out) }
        for arg in args { collectTunables(arg, context: name, into: &out) }
    case .closure(let body):
        collectTunables(body, context: nil, into: &out)
    case .string, .bool, .dollar:
        break
    }
}

// MARK: - Values

enum ScriptValue {
    case value(PatternValue)
    case transform((StrudelCore.Pattern) -> StrudelCore.Pattern)

    func asPattern() throws -> StrudelCore.Pattern {
        switch self {
        case .value(let v):
            return reify(v)
        case .transform:
            throw PatternScriptError(message: "expected a pattern, got a function", position: 0)
        }
    }

    func asPatternValue() throws -> PatternValue {
        switch self {
        case .value(let v):
            return v
        case .transform:
            throw PatternScriptError(message: "unexpected function argument", position: 0)
        }
    }

    func asTransform() throws -> (StrudelCore.Pattern) -> StrudelCore.Pattern {
        switch self {
        case .transform(let f):
            return f
        case .value:
            throw PatternScriptError(message: "expected a function argument like { $0.rev() }", position: 0)
        }
    }
}

// MARK: - Evaluator

final class ScriptEvaluator {
    func evaluate(_ expr: ScriptExpr, dollar: StrudelCore.Pattern?) throws -> ScriptValue {
        switch expr {
        case .number(let v, _):
            return .value(.number(v))
        case .string(let s):
            return .value(.string(s))
        case .bool(let b):
            return .value(.bool(b))
        case .list(let items):
            let values = try items.map { try evaluate($0, dollar: dollar).asPatternValue() }
            return .value(.list(values))
        case .dollar:
            guard let dollar else {
                throw PatternScriptError(message: "$0 outside a closure", position: 0)
            }
            return .value(.pattern(dollar))
        case .closure(let body):
            return .transform { [weak self] pat in
                guard let self else { return pat }
                return (try? self.evaluate(body, dollar: pat).asPattern()) ?? pat
            }
        case .call(let name, let args, let target):
            if let target {
                let pat = try evaluate(target, dollar: dollar).asPattern()
                return .value(.pattern(try applyMethod(name, args: args, to: pat, dollar: dollar)))
            }
            return try evaluateFree(name, args: args, dollar: dollar)
        }
    }

    // MARK: free functions & constants

    private func evaluateFree(_ name: String, args: [ScriptExpr],
                              dollar: StrudelCore.Pattern?) throws -> ScriptValue {
        // 1. bare signal/constant identifiers
        if args.isEmpty, let constant = ScriptEvaluator.constants[name] {
            return .value(.pattern(constant))
        }

        // 2. pattern constructors with variadic pattern args
        switch name {
        case "stack", "cat", "seq", "fastcat", "slowcat", "sequence", "polyrhythm":
            let values = try args.map { try evaluate($0, dollar: dollar).asPatternValue() }
            switch name {
            case "stack", "polyrhythm": return .value(.pattern(stack(values)))
            case "cat", "slowcat": return .value(.pattern(slowcat(values)))
            default: return .value(.pattern(fastcat(values)))
            }
        case "pure":
            let v = try evaluate(args[0], dollar: dollar).asPatternValue()
            return .value(.pattern(pure(v)))
        case "mini":
            let v = try evaluate(args[0], dollar: dollar).asPatternValue()
            guard let s = v.stringValue else {
                throw PatternScriptError(message: "mini() expects a string", position: 0)
            }
            return .value(.pattern(try StrudelMini.mini(s)))
        case "run":
            let v = try evaluate(args[0], dollar: dollar).asPatternValue()
            return .value(.pattern(run(v)))
        case "irand":
            let v = try evaluate(args[0], dollar: dollar).asPatternValue()
            return .value(.pattern(irand(v)))
        case "choose", "chooseCycles", "randcat":
            let values = try args.map { try evaluate($0, dollar: dollar).asPatternValue() }
            return .value(.pattern(name == "choose" ? chooseWith(rand, values)
                                                    : chooseInWith(rand._segment(.one), values)))
        default:
            break
        }

        // 3. any control name: note("..."), s("..."), lpf(800), …
        if Controls.isControlName(name) {
            let main = Controls.alias[name] ?? name
            let names = Controls.names[main] ?? [main]
            let v = try evaluate(args[0], dollar: dollar).asPatternValue()
            return .value(.pattern(controlPattern(names, v)))
        }

        // 4. combinator name used as a value → curried transform:
        //    .every(4, fast(2)) or .jux(rev)
        if ScriptEvaluator.combinators[name] != nil {
            let evaluatedArgs = args
            return .transform { [weak self] pat in
                guard let self else { return pat }
                return (try? self.applyMethod(name, args: evaluatedArgs, to: pat, dollar: nil)) ?? pat
            }
        }

        throw PatternScriptError(message: "unknown function '\(name)'", position: 0)
    }

    // MARK: method dispatch

    private func applyMethod(_ name: String, args: [ScriptExpr],
                             to pat: StrudelCore.Pattern,
                             dollar: StrudelCore.Pattern?) throws -> StrudelCore.Pattern {
        let evaluated = try args.map { try evaluate($0, dollar: dollar) }
        if let handler = ScriptEvaluator.combinators[name] {
            return try handler(pat, evaluated)
        }
        // control fallback: all 494 controls
        if Controls.isControlName(name) {
            guard let first = evaluated.first else {
                // `.note()` with no args names the pattern's raw values,
                // like strudel's control-without-arguments form.
                return pat.as(name)
            }
            return pat.control(name, try first.asPatternValue())
        }
        throw PatternScriptError(message: "unknown method '.\(name)'", position: 0)
    }

    // MARK: dispatch tables

    typealias Handler = (StrudelCore.Pattern, [ScriptValue]) throws -> StrudelCore.Pattern

    private static func pv(_ args: [ScriptValue], _ i: Int) throws -> PatternValue {
        guard i < args.count else {
            throw PatternScriptError(message: "missing argument \(i + 1)", position: 0)
        }
        return try args[i].asPatternValue()
    }

    private static func fn(_ args: [ScriptValue], _ i: Int) throws -> (StrudelCore.Pattern) -> StrudelCore.Pattern {
        guard i < args.count else {
            throw PatternScriptError(message: "missing function argument", position: 0)
        }
        return try args[i].asTransform()
    }

    static let constants: [String: StrudelCore.Pattern] = [
        "silence": silence,
        "sine": sine, "sine2": sine2, "cosine": cosine, "cosine2": cosine2,
        "saw": saw, "saw2": saw2, "isaw": isaw, "isaw2": isaw2,
        "tri": tri, "tri2": tri2, "itri": itri, "itri2": itri2,
        "square": square, "square2": square2,
        "rand": rand, "rand2": rand2, "brand": brand,
        "perlin": perlin, "berlin": berlin, "time": time,
    ]

    static let combinators: [String: Handler] = [
        // tempo & time
        "fast": { p, a in p.fast(try pv(a, 0)) },
        "density": { p, a in p.fast(try pv(a, 0)) },
        "slow": { p, a in p.slow(try pv(a, 0)) },
        "sparsity": { p, a in p.slow(try pv(a, 0)) },
        "hurry": { p, a in p.hurry(try pv(a, 0)) },
        "cpm": { p, a in p.cpm(try pv(a, 0)) },
        "early": { p, a in p.early(try pv(a, 0)) },
        "late": { p, a in p.late(try pv(a, 0)) },
        "rev": { p, _ in p.rev() },
        "revv": { p, _ in p.revv() },
        "palindrome": { p, _ in p.palindrome() },
        "brak": { p, _ in p.brak() },
        "press": { p, _ in p.press() },
        "pressBy": { p, a in p.pressBy(try pv(a, 0)) },
        "hush": { p, _ in p.hush() },
        "iter": { p, a in p.iter(try pv(a, 0)) },
        "iterBack": { p, a in p.iterBack(try pv(a, 0)) },
        "linger": { p, a in p.linger(try pv(a, 0)) },
        "zoom": { p, a in p.zoom(try pv(a, 0), try pv(a, 1)) },
        "compress": { p, a in p.compress(try pv(a, 0), try pv(a, 1)) },
        "segment": { p, a in p.segment(try pv(a, 0)) },
        "seg": { p, a in p.segment(try pv(a, 0)) },
        "ply": { p, a in p.ply(try pv(a, 0)) },
        "swing": { p, a in p.swing(try pv(a, 0)) },
        "swingBy": { p, a in p.swingBy(try pv(a, 0), try pv(a, 1)) },
        "ribbon": { p, a in p.ribbon(try pv(a, 0), try pv(a, 1)) },
        "repeatCycles": { p, a in p.repeatCycles(try pv(a, 0)) },
        // structure
        "euclid": { p, a in p.euclid(try pv(a, 0), try pv(a, 1)) },
        "euclidRot": { p, a in p.euclidRot(try pv(a, 0), try pv(a, 1), try pv(a, 2)) },
        "euclidLegato": { p, a in p.euclidLegato(try pv(a, 0), try pv(a, 1)) },
        "struct": { p, a in p.structure(try pv(a, 0)) },
        "mask": { p, a in p.mask(try pv(a, 0)) },
        "reset": { p, a in p.reset(try pv(a, 0)) },
        "restart": { p, a in p.restart(try pv(a, 0)) },
        "chop": { p, a in p.chop(try pv(a, 0)) },
        "striate": { p, a in p.striate(try pv(a, 0)) },
        "slice": { p, a in p.slice(try pv(a, 0), try pv(a, 1)) },
        "splice": { p, a in p.splice(try pv(a, 0), try pv(a, 1)) },
        "loopAt": { p, a in p.loopAt(try pv(a, 0)) },
        "fit": { p, _ in p.fit() },
        "bite": { p, a in p.bite(try pv(a, 0), try pv(a, 1)) },
        // randomness
        "degrade": { p, _ in p.degrade() },
        "degradeBy": { p, a in p.degradeBy(try pv(a, 0)) },
        "undegrade": { p, _ in p.undegrade() },
        "undegradeBy": { p, a in p.undegradeBy(try pv(a, 0)) },
        "shuffle": { p, a in p.shuffle(try pv(a, 0)) },
        "scramble": { p, a in p.scramble(try pv(a, 0)) },
        "seed": { p, a in p.seed(try pv(a, 0)) },
        // higher-order
        "every": { p, a in p.every(try pv(a, 0), try fn(a, 1)) },
        "firstOf": { p, a in p.firstOf(try pv(a, 0), try fn(a, 1)) },
        "lastOf": { p, a in p.lastOf(try pv(a, 0), try fn(a, 1)) },
        "when": { p, a in p.when(try pv(a, 0), try fn(a, 1)) },
        "off": { p, a in p.off(try pv(a, 0), try fn(a, 1)) },
        "jux": { p, a in p.jux(try fn(a, 0)) },
        "juxBy": { p, a in p.juxBy(try pv(a, 0), try fn(a, 1)) },
        "superimpose": { p, a in p.superimpose(try fn(a, 0)) },
        "layer": { p, a in
            let fns = try a.map { try $0.asTransform() }
            var pats: [PatternValue] = []
            for f in fns { pats.append(.pattern(f(p))) }
            return stack(pats)
        },
        "sometimes": { p, a in p.sometimes(try fn(a, 0)) },
        "sometimesBy": { p, a in p.sometimesBy(try pv(a, 0), try fn(a, 1)) },
        "often": { p, a in p.often(try fn(a, 0)) },
        "rarely": { p, a in p.rarely(try fn(a, 0)) },
        "almostAlways": { p, a in p.almostAlways(try fn(a, 0)) },
        "almostNever": { p, a in p.almostNever(try fn(a, 0)) },
        "someCycles": { p, a in p.someCycles(try fn(a, 0)) },
        "someCyclesBy": { p, a in p.someCyclesBy(try pv(a, 0), try fn(a, 1)) },
        "chunk": { p, a in p.chunk(try pv(a, 0), try fn(a, 1)) },
        "chunkBack": { p, a in p.chunkBack(try pv(a, 0), try fn(a, 1)) },
        "fastChunk": { p, a in p.fastChunk(try pv(a, 0), try fn(a, 1)) },
        "echoWith": { p, a in
            let f = try fn(a, 2)
            return p.echoWith(try pv(a, 0), try pv(a, 1)) { pat, _ in f(pat) }
        },
        "echo": { p, a in p.echo(try pv(a, 0), try pv(a, 1), try pv(a, 2)) },
        "stut": { p, a in p.stut(try pv(a, 0), try pv(a, 1), try pv(a, 2)) },
        // combination
        "stack": { p, a in
            var values: [PatternValue] = [.pattern(p)]
            for arg in a { values.append(try arg.asPatternValue()) }
            return stack(values)
        },
        "seq": { p, a in
            var values: [PatternValue] = [.pattern(p)]
            for arg in a { values.append(try arg.asPatternValue()) }
            return fastcat(values)
        },
        "cat": { p, a in
            var values: [PatternValue] = [.pattern(p)]
            for arg in a { values.append(try arg.asPatternValue()) }
            return slowcat(values)
        },
        // ops
        "add": { p, a in p.add(try pv(a, 0)) },
        "sub": { p, a in p.sub(try pv(a, 0)) },
        "mul": { p, a in p.mul(try pv(a, 0)) },
        "div": { p, a in p.div(try pv(a, 0)) },
        "mod": { p, a in p.mod(try pv(a, 0)) },
        "set": { p, a in p.set(try pv(a, 0)) },
        "keep": { p, a in p.keep(try pv(a, 0)) },
        "range": { p, a in p.range(try pv(a, 0), try pv(a, 1)) },
        "rangex": { p, a in p.rangex(try pv(a, 0), try pv(a, 1)) },
        "range2": { p, a in p.range2(try pv(a, 0), try pv(a, 1)) },
        "round": { p, _ in p.round() },
        "floor": { p, _ in p.floor() },
        "ceil": { p, _ in p.ceil() },
        // tonal
        "scale": { p, a in p.scale(try pv(a, 0)) },
        "transpose": { p, a in p.transpose(try pv(a, 0)) },
        "scaleTranspose": { p, a in p.scaleTranspose(try pv(a, 0)) },
        "voicing": { p, a in p.voicing(a.isEmpty ? "lefthand" : (try pv(a, 0).stringValue ?? "lefthand")) },
        "voicings": { p, a in p.voicings(a.isEmpty ? "lefthand" : (try pv(a, 0).stringValue ?? "lefthand")) },
        "rootNotes": { p, a in p.rootNotes(try pv(a, 0)) },
        "arp": { p, a in p.arp(try pv(a, 0)) },
        // distortion algorithms
        "soft": { p, a in p.soft(try pv(a, 0)) },
        "hard": { p, a in p.hard(try pv(a, 0)) },
        "cubic": { p, a in p.cubic(try pv(a, 0)) },
        "diode": { p, a in p.diode(try pv(a, 0)) },
        "asym": { p, a in p.asym(try pv(a, 0)) },
        "fold": { p, a in p.fold(try pv(a, 0)) },
        "sinefold": { p, a in p.sinefold(try pv(a, 0)) },
        "chebyshev": { p, a in p.chebyshev(try pv(a, 0)) },
        "scurve": { p, a in p.scurve(try pv(a, 0)) },
        // envelope shorthand
        "adsr": { p, a in p.adsr(try pv(a, 0)) },
        "ar": { p, a in p.ar(try pv(a, 0)) },
        // misc pattern methods
        "partials": { p, a in p.partials(try pv(a, 0)) },
        "phases": { p, a in p.phases(try pv(a, 0)) },
        "tag": { p, a in p.tag(try pv(a, 0).stringValue ?? "") },
        "invert": { p, _ in p.invert() },
        "log": { p, _ in p.log() },
    ]
}

extension ScriptValue {
    /// Bare method calls on non-pattern targets don't exist; coerce strings
    /// (mini) and lists (sequence) to patterns when used as chain roots.
    func asChainRoot() throws -> StrudelCore.Pattern {
        try asPattern()
    }
}
