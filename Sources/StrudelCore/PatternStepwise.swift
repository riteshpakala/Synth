// PatternStepwise.swift — stepwise (steps-per-cycle aware) functions.
// Ported from Strudel <https://codeberg.org/uzu/strudel> (packages/core/pattern.mjs,
// stepwise section) — AGPL-3.0-or-later.

import Foundation

// MARK: - stepcat / timecat

/// 'Concatenates' patterns like fastcat, but proportional to a number of steps
/// per cycle. `stepcat((3, "e3"), (1, "g3"))` is the same as `"e3@3 g3"`.
/// A nil weight means "infer from the pattern's steps".
public func stepcat(_ timepats: [(Fraction?, PatternValue)]) -> Pattern {
    if timepats.isEmpty { return nothing }

    var resolved: [(Fraction?, Pattern)] = timepats.map { (t, p) in
        let pat = reify(p)
        return (t ?? pat.steps ?? .one, pat)
    }

    // (JS: patterns with undefined steps get the average of the known ones —
    // resolved above defaults to 1 which matches `x._steps ?? 1` in findsteps.)

    if resolved.count == 1 {
        let (time, pat) = resolved[0]
        return pat.withSteps { _ in time ?? .one }.setSteps(time)
    }

    let total = resolved.reduce(Fraction.zero) { $0.add($1.0 ?? .one) }
    guard !total.isZero else { return nothing }
    var begin = Fraction.zero
    var pats: [PatternValue] = []
    for (time, pat) in resolved {
        let t = time ?? .one
        if t.isZero { continue }
        let end = begin.add(t)
        pats.append(.pattern(pat._compress(begin.div(total), end.div(total))))
        begin = end
    }
    let result = stack(pats)
    result.setSteps(total)
    return result
}

public func stepcat(_ timepats: (Fraction?, PatternValue)...) -> Pattern {
    stepcat(timepats)
}

/// stepcat variant taking bare patterns (steps inferred).
public func stepcat(_ pats: PatternValue...) -> Pattern {
    stepcat(pats.map { (nil, $0) })
}

/// Aliases for stepcat.
public func timeCat(_ timepats: [(Fraction?, PatternValue)]) -> Pattern { stepcat(timepats) }
public func timecat(_ timepats: [(Fraction?, PatternValue)]) -> Pattern { stepcat(timepats) }

/// Concatenates stepwise; list arguments alternate per repetition.
public func stepalt(_ groups: [PatternValue]) -> Pattern {
    let resolved: [[Pattern]] = groups.map { g in
        if case .list(let items) = g { return items.map(reify) }
        return [reify(g)]
    }
    let cycleCounts = resolved.map { Fraction($0.count) }
    var cycles = Fraction.one
    for c in cycleCounts where !c.isZero {
        cycles = cycles.lcm(c)
    }
    var result: [Pattern] = []
    var cycle = 0
    while Fraction(cycle) < cycles {
        for group in resolved {
            result.append(group.isEmpty ? silence : group[cycle % group.count])
        }
        cycle += 1
    }
    let filtered = result.filter { pat in
        guard let s = pat.steps else { return false }
        return s > .zero
    }
    let steps = filtered.reduce(Fraction.zero) { $0.add($1.steps ?? .zero) }
    let catted = stepcat(filtered.map { (nil, PatternValue.pattern($0)) })
    catted.setSteps(steps)
    return catted
}

public func stepalt(_ groups: PatternValue...) -> Pattern {
    stepalt(groups)
}

/// 'Zips' together the steps of the provided patterns.
public func zip(_ pats: [PatternValue]) -> Pattern {
    let reified = pats.map(reify).filter { $0.hasSteps }
    guard !reified.isEmpty else { return silence }
    let zipped = slowcat(reified.map { pat in
        PatternValue.pattern(pat._slow(pat.steps ?? .one))
    })
    var steps = reified[0].steps ?? .one
    for pat in reified.dropFirst() {
        if let s = pat.steps { steps = steps.lcm(s) }
    }
    return zipped._fast(steps).setSteps(steps)
}

public func zip(_ pats: PatternValue...) -> Pattern {
    zip(pats)
}

// MARK: - Pattern methods

extension Pattern {
    /// Speeds the pattern up or down to fit the given steps per cycle.
    public func pace(_ targetSteps: PatternValue) -> Pattern {
        patternify(targetSteps) { target, pat in
            guard let steps = pat.steps else { return pat }
            if steps.isZero { return nothing }
            let t = target.fractionValue ?? .one
            return pat._fast(t.div(steps)).setSteps(t)
        }
    }

    /// Flattens a pattern of patterns stepwise, aligning steps per cycle.
    public func stepJoin() -> Pattern {
        let pp = self
        let firstSteps = stepcat(_retime(_slices(pp.queryArc(Fraction.zero, Fraction.one)))).steps
        let q: (State) -> [Hap] = { state in
            let shifted = pp._early(state.span.begin.sam())
            let haps = shifted.query(state.setSpan(TimeSpan(.zero, .one)))
            let pat = stepcat(_retime(_slices(haps)))
            return pat.query(state)
        }
        return Pattern(q, steps: firstSteps)
    }

    public func stepBind(_ f: @escaping (PatternValue) -> Pattern) -> Pattern {
        fmap { .pattern(f($0)) }.stepJoin()
    }

    /// Takes the given number of steps from the pattern (negative = from end).
    public func _take(_ i: Fraction) -> Pattern {
        guard let steps, steps > .zero else { return nothing }
        var i = i
        if i.isZero { return nothing }
        let flip = i < .zero
        if flip { i = i.abs() }
        let frac = i.div(steps)
        if frac <= .zero { return nothing }
        if frac >= .one { return self }
        if flip { return _zoom(Fraction.one.sub(frac), .one) }
        return _zoom(.zero, frac)
    }

    public func take(_ i: PatternValue) -> Pattern {
        patternify(i, join: { $0.stepJoin() }) { i, pat in
            pat._take(i.fractionValue ?? .zero)
        }
    }

    /// Drops the given number of steps from the pattern (negative = from end).
    public func drop(_ i: PatternValue) -> Pattern {
        patternify(i, join: { $0.stepJoin() }) { i, pat in
            guard let steps = pat.steps else { return nothing }
            let iF = i.fractionValue ?? .zero
            if iF < .zero {
                return pat._take(steps.add(iF))
            }
            return pat._take(Fraction.zero.sub(steps.sub(iF)))
        }
    }

    /// Increases density and step count together.
    public func _extend(_ factor: Fraction) -> Pattern {
        _fast(factor)._expand(factor)
    }

    public func extend(_ factor: PatternValue) -> Pattern {
        patternify(factor, join: { $0.stepJoin() }) { f, pat in
            pat._extend(f.fractionValue ?? .one)
        }
    }

    /// Like extend, but repeats cycles rather than squeezing them.
    public func replicate(_ factor: PatternValue) -> Pattern {
        patternify(factor, join: { $0.stepJoin() }) { f, pat in
            let fr = f.fractionValue ?? .one
            return pat._repeatCycles(fr.floorInt)._fast(fr)._expand(fr)
        }
    }

    /// Expands the step size by the given factor.
    public func _expand(_ factor: Fraction) -> Pattern {
        withSteps { $0.mul(factor) }
    }

    public func expand(_ factor: PatternValue) -> Pattern {
        patternify(factor, join: { $0.stepJoin() }) { f, pat in
            pat._expand(f.fractionValue ?? .one)
        }
    }

    /// Contracts the step size by the given factor.
    public func contract(_ factor: PatternValue) -> Pattern {
        patternify(factor, join: { $0.stepJoin() }) { f, pat in
            pat.withSteps { $0.div(f.fractionValue ?? .one) }
        }
    }

    /// List of progressively shrunk versions of the pattern.
    public func shrinklist(_ amount: Fraction, times: Int? = nil) -> [Pattern] {
        guard let steps, !steps.isZero else { return [self] }
        let count = times ?? steps.floorInt
        if count == 0 || amount.isZero { return [self] }

        var ranges: [(Fraction, Fraction)] = []
        if amount > .zero {
            let seg = Fraction.one.div(steps).mul(amount)
            for i in 0..<count {
                let s = seg.mul(Fraction(i))
                if s > .one { break }
                ranges.append((s, .one))
            }
        } else {
            let amt = Fraction.zero.sub(amount)
            let seg = Fraction.one.div(steps).mul(amt)
            for i in 0..<count {
                let e = Fraction.one.sub(seg.mul(Fraction(i)))
                if e < .zero { break }
                ranges.append((.zero, e))
            }
        }
        return ranges.map { (s, e) in _zoom(s, e) }
    }

    public func growlist(_ amount: Fraction, times: Int? = nil) -> [Pattern] {
        shrinklist(amount, times: times).reversed()
    }

    /// Progressively shrinks the pattern by n steps.
    public func shrink(_ amount: PatternValue) -> Pattern {
        patternify(amount, join: { $0.stepJoin() }) { amount, pat in
            guard pat.hasSteps else { return nothing }
            let (amt, times) = Pattern._amountAndTimes(amount)
            let list = pat.shrinklist(amt, times: times)
            let result = stepcat(list.map { (nil, PatternValue.pattern($0)) })
            result.setSteps(list.reduce(Fraction.zero) { $0.add($1.steps ?? .zero) })
            return result
        }
    }

    /// Progressively grows the pattern by n steps.
    public func grow(_ amount: PatternValue) -> Pattern {
        patternify(amount, join: { $0.stepJoin() }) { amount, pat in
            guard pat.hasSteps else { return nothing }
            let (amt, times) = Pattern._amountAndTimes(amount)
            var list = pat.shrinklist(Fraction.zero.sub(amt), times: times)
            list.reverse()
            let result = stepcat(list.map { (nil, PatternValue.pattern($0)) })
            result.setSteps(list.reduce(Fraction.zero) { $0.add($1.steps ?? .zero) })
            return result
        }
    }

    /// Mini-notation list syntax "n:times" arrives as a list value.
    static func _amountAndTimes(_ v: PatternValue) -> (Fraction, Int?) {
        if let list = v.listValue, let first = list.first?.fractionValue {
            return (first, list.count > 1 ? list[1].intValue : nil)
        }
        return (v.fractionValue ?? .zero, nil)
    }

    /// Inserts this pattern into a list of patterns, moving backwards through
    /// the list on successive repetitions.
    public func tour(_ many: PatternValue...) -> Pattern {
        let manyPats = many.map { PatternValue.pattern(reify($0)) }
        var sectionsList: [PatternValue] = []
        for i in 0..<manyPats.count {
            sectionsList.append(contentsOf: manyPats.prefix(manyPats.count - i))
            sectionsList.append(.pattern(self))
            sectionsList.append(contentsOf: manyPats.suffix(i))
        }
        sectionsList.append(.pattern(self))
        sectionsList.append(contentsOf: manyPats)
        return stepcat(sectionsList.map { (nil, $0) })
    }
}

// MARK: - stepJoin helpers

func _retime(_ timedPats: [(Fraction, Pattern)]) -> [(Fraction?, PatternValue)] {
    let occupiedPerc = timedPats.filter { $0.1.hasSteps }.reduce(Fraction.zero) { $0.add($1.0) }
    let occupiedSteps = timedPats.compactMap { $0.1.steps }.reduce(Fraction.zero) { $0.add($1) }
    let totalSteps: Fraction? = occupiedPerc.isZero ? nil : occupiedSteps.div(occupiedPerc)
    return timedPats.map { (dur, pat) in
        if let steps = pat.steps {
            return (steps, PatternValue.pattern(pat))
        }
        return (totalSteps.map { dur.mul($0) }, PatternValue.pattern(pat))
    }
}

func _slices(_ haps: [Hap]) -> [(Fraction, Pattern)] {
    var breakpoints: [Fraction] = [.zero, .one]
    for hap in haps {
        breakpoints.append(hap.part.begin)
        breakpoints.append(hap.part.end)
    }
    let unique = uniqsortr(breakpoints)
    return pairs(unique).map { (b, e) in
        let span = TimeSpan(b, e)
        let fitted = _fitslice(span, haps)
        let stacked = stack(fitted.map { hap -> PatternValue in
            guard let inner = hap.value.patternValue else { return hap.value }
            return .pattern(inner.withHap { h in h.setContext(h.combineContext(hap)) })
        })
        return (e.sub(b), stacked)
    }
}

func _fitslice(_ span: TimeSpan, _ haps: [Hap]) -> [Hap] {
    haps.compactMap { _matchSlice(span, $0) }
}

func _matchSlice(_ span: TimeSpan, _ hap: Hap) -> Hap? {
    guard let subspan = span.intersection(hap.part) else { return nil }
    return Hap(whole: hap.whole, part: subspan, value: hap.value, context: hap.context)
}
