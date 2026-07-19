// Fraction.swift — rational time for the pattern engine.
// Ported from Strudel <https://codeberg.org/uzu/strudel> (packages/core/fraction.mjs,
// backed by fraction.js) — AGPL-3.0-or-later.

import Foundation

/// Exact rational number used for all pattern time arithmetic.
///
/// Always stored reduced, with a positive denominator. Cross-reduction is
/// applied before multiplication/addition so `Int64` overflow is out of reach
/// for any musical use.
public struct Fraction: Sendable, Hashable {
    /// Numerator (carries the sign).
    public let n: Int64
    /// Denominator, always > 0.
    public let d: Int64

    // MARK: Construction

    public init(_ numerator: Int64, _ denominator: Int64) {
        precondition(denominator != 0, "Fraction: denominator must not be zero")
        var n = numerator
        var d = denominator
        if d < 0 { n = -n; d = -d }
        let g = Fraction.gcd(Swift.abs(n), d)
        if g > 1 { n /= g; d /= g }
        self.n = n
        self.d = d
    }

    public init(_ value: Int) {
        self.init(Int64(value), 1)
    }

    /// Converts a double exactly when it is a dyadic rational (the common case
    /// for musical values like 0.25), otherwise finds the closest rational via
    /// continued fractions — mirroring fraction.js's exact number parsing.
    public init(_ value: Double) {
        precondition(value.isFinite, "Fraction: value must be finite")
        if value == value.rounded(), Swift.abs(value) < 9e15 {
            self.init(Int64(value), 1)
            return
        }
        // Continued-fraction expansion, denominator bounded like fraction.js.
        let sign: Int64 = value < 0 ? -1 : 1
        var x = Swift.abs(value)
        var h1: Int64 = 1, h2: Int64 = 0
        var k1: Int64 = 0, k2: Int64 = 1
        let maxDen: Int64 = 1_000_000_000
        while k1 < maxDen {
            let a = x.rounded(FloatingPointRoundingRule.down)
            guard Swift.abs(a) < 9e15 else { break }
            let ai = Int64(a)
            let h = ai &* h1 &+ h2
            let k = ai &* k1 &+ k2
            if k > maxDen || h > Int64.max / 2 { break }
            h2 = h1; h1 = h
            k2 = k1; k1 = k
            let frac = x - a
            if frac < 1e-15 { break }
            x = 1 / frac
        }
        if k1 == 0 { self.init(0, 1) } else { self.init(sign * h1, k1) }
    }

    /// Parses "3", "-1/4", "0.5".
    public init?(_ string: String) {
        let s = string.trimmingCharacters(in: .whitespaces)
        if let slash = s.firstIndex(of: "/") {
            guard let num = Int64(s[s.startIndex..<slash]),
                  let den = Int64(s[s.index(after: slash)...]), den != 0
            else { return nil }
            self.init(num, den)
        } else if let i = Int64(s) {
            self.init(i, 1)
        } else if let dbl = Double(s) {
            self.init(dbl)
        } else {
            return nil
        }
    }

    public static let zero = Fraction(0, 1)
    public static let one = Fraction(1, 1)

    // MARK: Arithmetic

    private static func gcd(_ a: Int64, _ b: Int64) -> Int64 {
        var a = a, b = b
        while b != 0 { (a, b) = (b, a % b) }
        return a
    }

    public func add(_ other: Fraction) -> Fraction {
        // a/b + c/d = (a*(d/g) + c*(b/g)) / lcm, reducing by gcd(b, d) first.
        let g = Fraction.gcd(d, other.d)
        let lhs = n * (other.d / g)
        let rhs = other.n * (d / g)
        return Fraction(lhs + rhs, d * (other.d / g))
    }

    public func sub(_ other: Fraction) -> Fraction {
        add(other.neg())
    }

    public func mul(_ other: Fraction) -> Fraction {
        // Cross-reduce before multiplying to keep magnitudes small.
        let g1 = Fraction.gcd(Swift.abs(n), other.d)
        let g2 = Fraction.gcd(Swift.abs(other.n), d)
        return Fraction((n / g1) * (other.n / g2), (d / g2) * (other.d / g1))
    }

    public func div(_ other: Fraction) -> Fraction {
        precondition(other.n != 0, "Fraction: division by zero")
        return mul(other.inverse())
    }

    /// Remainder with the sign behavior of fraction.js `mod` (sign follows self).
    public func mod(_ other: Fraction) -> Fraction {
        let q = div(other).floorFraction()
        let r = sub(q.mul(other))
        return r
    }

    public func neg() -> Fraction { Fraction(-n, d) }

    public func inverse() -> Fraction {
        precondition(n != 0, "Fraction: inverse of zero")
        return Fraction(n < 0 ? -d : d, Swift.abs(n))
    }

    public func abs() -> Fraction { Fraction(Swift.abs(n), d) }

    public func gcd(_ other: Fraction) -> Fraction {
        // gcd(a/b, c/d) = gcd(a, c) / lcm(b, d)
        let num = Fraction.gcd(Swift.abs(n), Swift.abs(other.n))
        let g = Fraction.gcd(d, other.d)
        return Fraction(num, (d / g) * other.d)
    }

    public func lcm(_ other: Fraction) -> Fraction {
        // lcm(a/b, c/d) = lcm(a, c) / gcd(b, d)
        if n == 0 || other.n == 0 { return .zero }
        let g = Fraction.gcd(Swift.abs(n), Swift.abs(other.n))
        let num = (Swift.abs(n) / g) * Swift.abs(other.n)
        return Fraction(num, Fraction.gcd(d, other.d))
    }

    // MARK: Rounding

    public func floorFraction() -> Fraction {
        let q = n / d
        let r = n % d
        return Fraction(r < 0 ? q - 1 : q, 1)
    }

    public func ceilFraction() -> Fraction {
        let q = n / d
        let r = n % d
        return Fraction(r > 0 ? q + 1 : q, 1)
    }

    public func roundFraction() -> Fraction {
        // fraction.js rounds half away from zero.
        Fraction(Int64((Double(n) / Double(d)).rounded(.toNearestOrAwayFromZero)), 1)
    }

    /// Integer value after flooring — for indexing.
    public var floorInt: Int { Int(floorFraction().n) }

    // MARK: Cycle helpers (fraction.mjs extensions)

    /// The start of the cycle this time value is in.
    public func sam() -> Fraction { floorFraction() }

    /// The start of the next cycle.
    public func nextSam() -> Fraction { sam().add(.one) }

    /// The begin/end of this time value's whole cycle.
    public func wholeCycle() -> TimeSpan { TimeSpan(sam(), nextSam()) }

    /// Position relative to the start of its cycle.
    public func cyclePos() -> Fraction { sub(sam()) }

    public func min(_ other: Fraction) -> Fraction { self < other ? self : other }
    public func max(_ other: Fraction) -> Fraction { self > other ? self : other }

    /// `self` if non-zero, otherwise `other` (fraction.mjs `or`).
    public func or(_ other: Fraction) -> Fraction { n == 0 ? other : self }

    public var isZero: Bool { n == 0 }
    public var doubleValue: Double { Double(n) / Double(d) }

    public func show() -> String { "\(n)/\(d)" }
}

// MARK: - Operators & literals

extension Fraction: Comparable {
    public static func < (lhs: Fraction, rhs: Fraction) -> Bool {
        // Compare via cross-reduced multiplication to avoid overflow.
        let g = gcd(lhs.d, rhs.d)
        return lhs.n * (rhs.d / g) < rhs.n * (lhs.d / g)
    }
}

extension Fraction: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int64) { self.init(value, 1) }
}

extension Fraction: CustomStringConvertible {
    public var description: String { d == 1 ? "\(n)" : "\(n)/\(d)" }
}

public extension Fraction {
    static func + (a: Fraction, b: Fraction) -> Fraction { a.add(b) }
    static func - (a: Fraction, b: Fraction) -> Fraction { a.sub(b) }
    static func * (a: Fraction, b: Fraction) -> Fraction { a.mul(b) }
    static func / (a: Fraction, b: Fraction) -> Fraction { a.div(b) }
}

/// Variadic gcd over optional fractions (fraction.mjs `gcd`).
public func gcd(_ fractions: Fraction?...) -> Fraction? {
    let present = fractions.compactMap { $0 }
    guard !present.isEmpty else { return nil }
    return present.reduce(Fraction.one) { $0.gcd($1) }
}

/// Variadic lcm over optional fractions (fraction.mjs `lcm`); nil if any is nil.
public func lcm(_ fractions: Fraction?...) -> Fraction? {
    guard !fractions.isEmpty else { return nil }
    var result: Fraction? = nil
    for f in fractions {
        guard let f else { return nil }
        result = result == nil ? f : result!.lcm(f)
    }
    return result
}
