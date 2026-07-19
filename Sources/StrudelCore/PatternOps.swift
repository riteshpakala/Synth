// PatternOps.swift — the operator/alignment "composer matrix".
// Ported from Strudel <https://codeberg.org/uzu/strudel> (packages/core/pattern.mjs,
// COMPOSERS + _setupAlignments) — AGPL-3.0-or-later.
//
// Every binary operator (set, keep, add, mul, …) is available with every
// alignment (in, out, mix, squeeze, squeezeout, reset, restart, poly):
//
//     pat.add(2)            // default 'in' alignment
//     pat.add.out("0 1")    // structure from the right
//     pat.set.squeeze(x)

import Foundation

public typealias BinaryOp = @Sendable (PatternValue, PatternValue) -> PatternValue

public enum Alignment: String, CaseIterable, Sendable {
    case `in`, out, mix, squeeze, squeezeout, reset, restart, poly
}

/// Mirrors `DEFAULT_ALIGNMENT`; changed via `setDefaultJoin`.
nonisolated(unsafe) public var defaultAlignment: Alignment = .in

public func setDefaultJoin(_ alignment: Alignment) {
    defaultAlignment = alignment
}

extension Pattern {
    // MARK: Alignment primitives (_opIn etc.)

    func _opIn(_ other: Pattern, _ f: @escaping @Sendable (PatternValue) -> @Sendable (PatternValue) -> PatternValue) -> Pattern {
        fmap { a in .function(f(a)) }.appLeft(other)
    }

    func _opOut(_ other: Pattern, _ f: @escaping @Sendable (PatternValue) -> @Sendable (PatternValue) -> PatternValue) -> Pattern {
        fmap { a in .function(f(a)) }.appRight(other)
    }

    func _opMix(_ other: Pattern, _ f: @escaping @Sendable (PatternValue) -> @Sendable (PatternValue) -> PatternValue) -> Pattern {
        fmap { a in .function(f(a)) }.appBoth(other)
    }

    func _opSqueeze(_ other: Pattern, _ f: @escaping @Sendable (PatternValue) -> @Sendable (PatternValue) -> PatternValue) -> Pattern {
        let otherPat = other
        return fmap { a in .pattern(otherPat.fmap { b in f(a)(b) }) }.squeezeJoin()
    }

    func _opSqueezeOut(_ other: Pattern, _ f: @escaping @Sendable (PatternValue) -> @Sendable (PatternValue) -> PatternValue) -> Pattern {
        let thisPat = self
        return other.fmap { a in .pattern(thisPat.fmap { b in f(b)(a) }) }.squeezeJoin()
    }

    func _opReset(_ other: Pattern, _ f: @escaping @Sendable (PatternValue) -> @Sendable (PatternValue) -> PatternValue) -> Pattern {
        let thisPat = self
        return other.fmap { b in .pattern(thisPat.fmap { a in f(a)(b) }) }.resetJoin()
    }

    func _opRestart(_ other: Pattern, _ f: @escaping @Sendable (PatternValue) -> @Sendable (PatternValue) -> PatternValue) -> Pattern {
        let thisPat = self
        return other.fmap { b in .pattern(thisPat.fmap { a in f(a)(b) }) }.restartJoin()
    }

    func _opPoly(_ other: Pattern, _ f: @escaping @Sendable (PatternValue) -> @Sendable (PatternValue) -> PatternValue) -> Pattern {
        let otherPat = other
        return fmap { b in .pattern(otherPat.fmap { a in f(a)(b) }) }.polyJoin()
    }

    func _opWith(_ alignment: Alignment, _ other: Pattern,
                 _ f: @escaping @Sendable (PatternValue) -> @Sendable (PatternValue) -> PatternValue) -> Pattern {
        switch alignment {
        case .in: return _opIn(other, f)
        case .out: return _opOut(other, f)
        case .mix: return _opMix(other, f)
        case .squeeze: return _opSqueeze(other, f)
        case .squeezeout: return _opSqueezeOut(other, f)
        case .reset: return _opReset(other, f)
        case .restart: return _opRestart(other, f)
        case .poly: return _opPoly(other, f)
        }
    }
}

// MARK: - _composeOp: lift ops over control maps

func _nonMapValue(_ x: PatternValue) -> Bool {
    x.mapValue == nil
}

/// If either side is a control map, the op is applied entry-wise over the
/// union of both maps (a bare value becomes `{ value: x }` first).
func _composeOp(_ a: PatternValue, _ b: PatternValue, _ op: BinaryOp) -> PatternValue {
    if a.mapValue != nil || b.mapValue != nil {
        let aMap = a.mapValue ?? ["value": a]
        let bMap = b.mapValue ?? ["value": b]
        return .map(unionWithObj(aMap, bMap) { x, y in op(x, y) })
    }
    return op(a, b)
}

// MARK: - The operator family type

/// The object returned by `pat.add`, `pat.set`, etc. Callable directly
/// (default alignment) or via `.in/.out/.mix/...`.
public struct OpFamily {
    let pat: Pattern
    let op: BinaryOp
    /// keepif throws away b's value entirely and drops undefineds.
    let isKeepif: Bool

    func combine(_ alignment: Alignment, _ others: [PatternValue]) -> Pattern {
        // Mirrors JS `sequence(args)`: one plain arg passes through, one list
        // arg or several args are sequenced.
        let other: Pattern
        if others.count == 1 {
            if case .list(let items) = others[0] {
                other = sequence(items)
            } else {
                other = reify(others[0])
            }
        } else {
            other = sequence(others)
        }
        let op = self.op
        var result: Pattern
        if isKeepif {
            result = pat._opWith(alignment, other) { a in { b in op(a, b) } }
            result = result.removeUndefineds()
        } else {
            result = pat._opWith(alignment, other) { a in { b in _composeOp(a, b, op) } }
        }
        return result
    }

    public func callAsFunction(_ others: PatternValue...) -> Pattern {
        combine(defaultAlignment, others)
    }

    public func `in`(_ others: PatternValue...) -> Pattern { combine(.in, others) }
    public func out(_ others: PatternValue...) -> Pattern { combine(.out, others) }
    public func mix(_ others: PatternValue...) -> Pattern { combine(.mix, others) }
    public func squeeze(_ others: PatternValue...) -> Pattern { combine(.squeeze, others) }
    public func squeezein(_ others: PatternValue...) -> Pattern { combine(.squeeze, others) }
    public func squeezeout(_ others: PatternValue...) -> Pattern { combine(.squeezeout, others) }
    public func reset(_ others: PatternValue...) -> Pattern { combine(.reset, others) }
    public func restart(_ others: PatternValue...) -> Pattern { combine(.restart, others) }
    public func poly(_ others: PatternValue...) -> Pattern { combine(.poly, others) }
}

// MARK: - JS-flavored primitive ops

/// JS `+`: number addition, string concatenation; note names parse to midi
/// when combined with numbers (numeralArgs semantics).
let jsAdd: BinaryOp = { a, b in
    if case .string(let x) = a, case .string(let y) = b, Double(x) == nil, !isNote(x) {
        return .string(x + y)
    }
    return numeralArgs { $0 + $1 }(a, b)
}

private func compareNumbersOrStrings(_ a: PatternValue, _ b: PatternValue,
                                     _ num: (Double, Double) -> Bool,
                                     _ str: (String, String) -> Bool) -> PatternValue {
    if let x = a.doubleValue, let y = b.doubleValue { return .bool(num(x, y)) }
    if case .string(let x) = a, case .string(let y) = b { return .bool(str(x, y)) }
    return .bool(false)
}

private func intOp(_ f: @escaping (Int32, Int32) -> Int32) -> BinaryOp {
    numeralArgs { a, b in Double(f(Int32(truncatingIfNeeded: Int64(a)), Int32(truncatingIfNeeded: Int64(b)))) }
}

extension Pattern {
    // MARK: The operators (mirroring COMPOSERS)

    public var set: OpFamily { OpFamily(pat: self, op: { _, b in b }, isKeepif: false) }
    public var keep: OpFamily { OpFamily(pat: self, op: { a, _ in a }, isKeepif: false) }
    public var keepif: OpFamily { OpFamily(pat: self, op: { a, b in b.truthy ? a : .null }, isKeepif: true) }
    public var add: OpFamily { OpFamily(pat: self, op: jsAdd, isKeepif: false) }
    public var sub: OpFamily { OpFamily(pat: self, op: numeralArgs { $0 - $1 }, isKeepif: false) }
    public var mul: OpFamily { OpFamily(pat: self, op: numeralArgs { $0 * $1 }, isKeepif: false) }
    public var div: OpFamily { OpFamily(pat: self, op: numeralArgs { $0 / $1 }, isKeepif: false) }
    public var mod: OpFamily { OpFamily(pat: self, op: numeralArgs { _mod($0, $1) }, isKeepif: false) }
    public var pow: OpFamily { OpFamily(pat: self, op: numeralArgs { Foundation.pow($0, $1) }, isKeepif: false) }
    public var band: OpFamily { OpFamily(pat: self, op: intOp { $0 & $1 }, isKeepif: false) }
    public var bor: OpFamily { OpFamily(pat: self, op: intOp { $0 | $1 }, isKeepif: false) }
    public var bxor: OpFamily { OpFamily(pat: self, op: intOp { $0 ^ $1 }, isKeepif: false) }
    public var blshift: OpFamily { OpFamily(pat: self, op: intOp { $0 << (($1 & 31)) }, isKeepif: false) }
    public var brshift: OpFamily { OpFamily(pat: self, op: intOp { $0 >> (($1 & 31)) }, isKeepif: false) }
    public var lt: OpFamily { OpFamily(pat: self, op: { a, b in compareNumbersOrStrings(a, b, { $0 < $1 }, { $0 < $1 }) }, isKeepif: false) }
    public var gt: OpFamily { OpFamily(pat: self, op: { a, b in compareNumbersOrStrings(a, b, { $0 > $1 }, { $0 > $1 }) }, isKeepif: false) }
    public var lte: OpFamily { OpFamily(pat: self, op: { a, b in compareNumbersOrStrings(a, b, { $0 <= $1 }, { $0 <= $1 }) }, isKeepif: false) }
    public var gte: OpFamily { OpFamily(pat: self, op: { a, b in compareNumbersOrStrings(a, b, { $0 >= $1 }, { $0 >= $1 }) }, isKeepif: false) }
    public var eq: OpFamily { OpFamily(pat: self, op: { a, b in .bool(a == b) }, isKeepif: false) }
    public var ne: OpFamily { OpFamily(pat: self, op: { a, b in .bool(a != b) }, isKeepif: false) }
    public var and: OpFamily { OpFamily(pat: self, op: { a, b in a.truthy ? b : a }, isKeepif: false) }
    public var or: OpFamily { OpFamily(pat: self, op: { a, b in a.truthy ? a : b }, isKeepif: false) }
    /// Assumes b is a function; applies it to a.
    public var funcOp: OpFamily { OpFamily(pat: self, op: { a, b in b.functionValue?(a) ?? a }, isKeepif: false) }

    // MARK: Binary composers (struct/mask/reset/restart)

    /// Applies the given structure to the pattern.
    public func structure(_ others: PatternValue...) -> Pattern {
        keepif.out(.list(others))
    }

    public func structAll(_ others: PatternValue...) -> Pattern {
        keep.out(.list(others))
    }

    /// Returns silence when mask is 0 or "~".
    public func mask(_ others: PatternValue...) -> Pattern {
        keepif.in(.list(others))
    }

    public func maskAll(_ others: PatternValue...) -> Pattern {
        keep.in(.list(others))
    }

    /// Resets the pattern to the start of the cycle for each onset of the reset pattern.
    public func reset(_ others: PatternValue...) -> Pattern {
        keepif.reset(.list(others))
    }

    public func resetAll(_ others: PatternValue...) -> Pattern {
        keep.reset(.list(others))
    }

    /// Restarts the pattern (from cycle 0) for each onset of the restart pattern.
    public func restart(_ others: PatternValue...) -> Pattern {
        keepif.restart(.list(others))
    }

    public func restartAll(_ others: PatternValue...) -> Pattern {
        keep.restart(.list(others))
    }
}
