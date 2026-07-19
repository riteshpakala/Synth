// Euclid.swift — Bjorklund/Euclidean rhythms.
// Ported from Strudel <https://codeberg.org/uzu/strudel> (packages/core/euclid.mjs),
// itself ported from Rohan Drape's Haskell Music Theory module
// <https://rohandrape.net/?t=hmt> — AGPL-3.0-or-later.

import Foundation

private typealias BjorkState = (counts: (Int, Int), lists: ([[Int]], [[Int]]))

private func bjorkLeft(_ n: (Int, Int), _ x: ([[Int]], [[Int]])) -> BjorkState {
    let (ons, offs) = n
    let (xs, ys) = x
    let xsHead = Array(xs.prefix(offs))
    let xsTail = Array(xs.dropFirst(offs))
    let zipped = Swift.zip(xsHead, ys).map { $0 + $1 }
    return ((offs, ons - offs), (zipped, xsTail))
}

private func bjorkRight(_ n: (Int, Int), _ x: ([[Int]], [[Int]])) -> BjorkState {
    let (ons, offs) = n
    let (xs, ys) = x
    let ysHead = Array(ys.prefix(ons))
    let ysTail = Array(ys.dropFirst(ons))
    let zipped = Swift.zip(xs, ysHead).map { $0 + $1 }
    return ((ons, offs - ons), (zipped, ysTail))
}

private func _bjorklund(_ n: (Int, Int), _ x: ([[Int]], [[Int]])) -> BjorkState {
    let (ons, offs) = n
    if Swift.min(ons, offs) <= 1 {
        return (n, x)
    }
    let next = ons > offs ? bjorkLeft(n, x) : bjorkRight(n, x)
    return _bjorklund(next.counts, next.lists)
}

/// The Bjorklund (euclidean) algorithm: distributes `ons` onsets over `steps`
/// steps as evenly as possible. Negative `ons` inverts the pattern.
public func bjorklund(_ ons: Int, _ steps: Int) -> [Int] {
    let inverted = ons < 0
    let absOns = Swift.abs(ons)
    let offs = steps - absOns
    guard absOns > 0, offs >= 0 else {
        return [Int](repeating: inverted ? 1 : 0, count: Swift.max(steps, 0))
    }
    let ones = [[Int]](repeating: [1], count: absOns)
    let zeros = [[Int]](repeating: [0], count: offs)
    let result = _bjorklund((absOns, offs), (ones, zeros))
    let pattern = result.lists.0.flatMap { $0 } + result.lists.1.flatMap { $0 }
    return inverted ? pattern.map { 1 - $0 } : pattern
}

func _euclidRot(_ pulses: Int, _ steps: Int, _ rotation: Int) -> [Int] {
    let b = bjorklund(pulses, steps)
    if rotation != 0 {
        return rotate(b, -rotation)
    }
    return b
}

private func euclidStructValues(_ bits: [Int]) -> [PatternValue] {
    bits.map { .bool($0 == 1) }
}

extension Pattern {
    /// Euclidean rhythm: `note("c3").euclid(3, 8)`.
    public func euclid(_ pulses: PatternValue, _ steps: PatternValue) -> Pattern {
        patternify2(pulses, steps) { p, s, pat in
            pat.structure(.list(euclidStructValues(
                _euclidRot(p.intValue ?? 0, s.intValue ?? 0, 0)
            )))
        }
    }

    /// Like euclid, with a rotation offset.
    public func euclidRot(_ pulses: PatternValue, _ steps: PatternValue, _ rotation: PatternValue) -> Pattern {
        patternify3(pulses, steps, rotation) { p, s, r, pat in
            pat.structure(.list(euclidStructValues(
                _euclidRot(p.intValue ?? 0, s.intValue ?? 0, r.intValue ?? 0)
            )))
        }
    }

    /// Mini-notation `(p,s,r)` entry point: takes a list [pulses, steps, rot].
    public func bjork(_ euc: PatternValue) -> Pattern {
        patternify(euc) { euc, pat in
            let list = euc.listValue ?? [euc]
            let pulses = list.first?.intValue ?? 0
            let steps = list.count > 1 ? (list[1].intValue ?? pulses) : pulses
            let rot = list.count > 2 ? (list[2].intValue ?? 0) : 0
            return pat.structure(.list(euclidStructValues(_euclidRot(pulses, steps, rot))))
        }
    }

    func _euclidLegato(_ pulses: Int, _ steps: Int, _ rotation: Int) -> Pattern {
        if pulses < 1 { return silence }
        let binPat = _euclidRot(pulses, steps, 0)
        // Split the bit string on 1s; each pulse is held until the next.
        var gapless: [(Fraction?, PatternValue)] = []
        var current: Int? = nil
        for bit in binPat {
            if bit == 1 {
                if let len = current {
                    gapless.append((Fraction(len), .bool(true)))
                }
                current = 1
            } else if current != nil {
                current! += 1
            }
        }
        if let len = current {
            gapless.append((Fraction(len), .bool(true)))
        }
        return structure(.pattern(stepcat(gapless)))
            ._late(Fraction(rotation).div(Fraction(steps)))
    }

    /// Euclid with no gaps: each pulse is held until the next pulse.
    public func euclidLegato(_ pulses: PatternValue, _ steps: PatternValue) -> Pattern {
        patternify2(pulses, steps) { p, s, pat in
            pat._euclidLegato(p.intValue ?? 0, s.intValue ?? 0, 0)
        }
    }

    public func euclidLegatoRot(_ pulses: PatternValue, _ steps: PatternValue, _ rotation: PatternValue) -> Pattern {
        patternify3(pulses, steps, rotation) { p, s, r, pat in
            pat._euclidLegato(p.intValue ?? 0, s.intValue ?? 0, r.intValue ?? 0)
        }
    }
}
