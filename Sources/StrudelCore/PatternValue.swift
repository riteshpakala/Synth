// PatternValue.swift — the dynamic value carried by haps.
// Part of the Swift port of Strudel <https://codeberg.org/uzu/strudel> — AGPL-3.0-or-later.
//
// Strudel patterns are deeply dynamic: hap values can be numbers, note-name
// strings, booleans, arrays, control maps ({ note: 60, s: 'piano' }), or —
// inside the applicative machinery — functions. This enum mirrors that.

import Foundation

/// A control map: named parameters attached to an event, e.g. `note`, `s`, `gain`.
public typealias ControlMap = [String: PatternValue]

public indirect enum PatternValue: @unchecked Sendable {
    case null
    case number(Double)
    case string(String)
    case bool(Bool)
    case fraction(Fraction)
    case list([PatternValue])
    case map(ControlMap)
    /// A nested pattern — the currency of the join family (patterns of patterns).
    case pattern(Pattern)
    /// A unary function value — the currency of `appLeft`/`appRight`/`appBoth`.
    case function(@Sendable (PatternValue) -> PatternValue)

    // MARK: Convenience constructors

    public init(_ v: Double) { self = .number(v) }
    public init(_ v: Int) { self = .number(Double(v)) }
    public init(_ v: String) { self = .string(v) }
    public init(_ v: Bool) { self = .bool(v) }
    public init(_ v: Fraction) { self = .fraction(v) }
    public init(_ v: [PatternValue]) { self = .list(v) }
    public init(_ v: ControlMap) { self = .map(v) }

    // MARK: Accessors

    public var isNull: Bool { if case .null = self { return true }; return false }

    public var doubleValue: Double? {
        switch self {
        case .number(let x): return x
        case .fraction(let f): return f.doubleValue
        case .bool(let b): return b ? 1 : 0
        case .string(let s): return Double(s)
        default: return nil
        }
    }

    public var intValue: Int? {
        guard let d = doubleValue, d.isFinite else { return nil }
        return Int(d.rounded(.towardZero))
    }

    public var fractionValue: Fraction? {
        switch self {
        case .fraction(let f): return f
        case .number(let x): return x.isFinite ? Fraction(x) : nil
        case .string(let s): return Fraction(s)
        case .bool(let b): return Fraction(b ? 1 : 0)
        default: return nil
        }
    }

    public var stringValue: String? {
        if case .string(let s) = self { return s }
        return nil
    }

    /// JS-style truthiness: false, 0, "", null are falsy.
    public var truthy: Bool {
        switch self {
        case .null: return false
        case .bool(let b): return b
        case .number(let x): return x != 0
        case .fraction(let f): return !f.isZero
        case .string(let s): return !s.isEmpty
        case .list, .map, .pattern, .function: return true
        }
    }

    public var mapValue: ControlMap? {
        if case .map(let m) = self { return m }
        return nil
    }

    public var listValue: [PatternValue]? {
        if case .list(let l) = self { return l }
        return nil
    }

    public var functionValue: (@Sendable (PatternValue) -> PatternValue)? {
        if case .function(let f) = self { return f }
        return nil
    }

    public var patternValue: Pattern? {
        if case .pattern(let p) = self { return p }
        return nil
    }

    /// The value as a control map, promoting bare values the way superdough's
    /// `ensureObjectValue` expects callers to have done.
    public func asControlMap(defaultKey: String = "note") -> ControlMap {
        switch self {
        case .map(let m): return m
        default: return [defaultKey: self]
        }
    }
}

// MARK: - Equality (functions compare unequal, like JS closures)

extension PatternValue: Equatable {
    public static func == (lhs: PatternValue, rhs: PatternValue) -> Bool {
        switch (lhs, rhs) {
        case (.null, .null): return true
        case (.number(let a), .number(let b)): return a == b
        case (.string(let a), .string(let b)): return a == b
        case (.bool(let a), .bool(let b)): return a == b
        case (.fraction(let a), .fraction(let b)): return a == b
        // Mixed numeric representations compare numerically (JS has one number type).
        case (.number(let a), .fraction(let b)), (.fraction(let b), .number(let a)):
            return a == b.doubleValue
        case (.list(let a), .list(let b)): return a == b
        case (.map(let a), .map(let b)): return a == b
        default: return false
        }
    }
}

extension PatternValue: CustomStringConvertible {
    public var description: String {
        switch self {
        case .null: return "null"
        case .number(let x):
            return x == x.rounded() && Swift.abs(x) < 1e15
                ? String(Int64(x)) : String(x)
        case .string(let s): return s
        case .bool(let b): return String(b)
        case .fraction(let f): return f.description
        case .list(let l): return "[" + l.map(\.description).joined(separator: ", ") + "]"
        case .map(let m):
            let body = m.sorted { $0.key < $1.key }
                .map { "\($0.key): \($0.value)" }
                .joined(separator: ", ")
            return "{ " + body + " }"
        case .pattern: return "<pattern>"
        case .function: return "<function>"
        }
    }
}

// MARK: - Literals, for a pleasant DSL

extension PatternValue: ExpressibleByIntegerLiteral, ExpressibleByFloatLiteral,
    ExpressibleByStringLiteral, ExpressibleByBooleanLiteral, ExpressibleByArrayLiteral {
    public init(integerLiteral value: Int) { self = .number(Double(value)) }
    public init(floatLiteral value: Double) { self = .number(value) }
    public init(stringLiteral value: String) { self = .string(value) }
    public init(booleanLiteral value: Bool) { self = .bool(value) }
    public init(arrayLiteral elements: PatternValue...) { self = .list(elements) }
}

// MARK: - unionWithObj (value.mjs)

/// Merges two control maps; keys present in both are combined with `f`
/// (b's entries otherwise win, like `Object.assign({}, a, b, common)`).
public func unionWithObj(_ a: ControlMap, _ b: ControlMap,
                         _ f: (PatternValue, PatternValue) -> PatternValue) -> ControlMap {
    var out = a
    for (k, v) in b {
        if let existing = a[k] {
            out[k] = f(existing, v)
        } else {
            out[k] = v
        }
    }
    return out
}
