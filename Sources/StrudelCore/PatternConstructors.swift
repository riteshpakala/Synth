// PatternConstructors.swift — elemental patterns and pattern combination.
// Ported from Strudel <https://codeberg.org/uzu/strudel> (packages/core/pattern.mjs)
// — AGPL-3.0-or-later.

import Foundation

// MARK: - Elemental patterns

/// Does absolutely nothing, but with a given metrical 'steps'.
public func gap(_ steps: Int) -> Pattern {
    Pattern({ _ in [] }, steps: Fraction(steps))
}

/// Does absolutely nothing.
public let silence = gap(1)

/// Like silence, but with a 'steps' (relative duration) of 0.
public let nothing = gap(0)

/// A discrete value that repeats once per cycle.
public func pure(_ value: PatternValue) -> Pattern {
    let result = Pattern({ state in
        state.span.spanCycles.map { subspan in
            Hap(whole: subspan.begin.wholeCycle(), part: subspan, value: value)
        }
    }, steps: .one)
    result.pureValue = value
    return result
}

/// Turns something into a pattern, unless it's already a pattern.
/// Strings are parsed as mini-notation once StrudelMini is loaded;
/// lists become sequences.
public func reify(_ thing: PatternValue) -> Pattern {
    switch thing {
    case .pattern(let p):
        return p
    case .string(let s):
        if let parser = StrudelRuntime.stringParser {
            return parser(s)
        }
        return pure(thing)
    default:
        // Note: lists reify to pure list values (JS reify does not sequence
        // arrays — stack/slowcat/argument positions do that explicitly).
        return pure(thing)
    }
}

// MARK: - Stacking

/// The given items are played at the same time at the same length.
public func stack(_ pats: [PatternValue]) -> Pattern {
    // Array elements are sequenced (JS: `Array.isArray(pat) ? sequence(...pat)`).
    let reified = pats.map { pat -> Pattern in
        if case .list(let items) = pat { return fastcat(items) }
        return reify(pat)
    }
    let result = Pattern { state in
        reified.flatMap { $0.query(state) }
    }
    if StrudelRuntime.stepsEnabled {
        var steps: Fraction? = nil
        var first = true
        for pat in reified {
            if first { steps = pat.steps; first = false }
            else if let s = steps, let o = pat.steps { steps = s.lcm(o) }
            else { steps = nil }
        }
        result.steps = steps
    }
    return result
}

public func stack(_ pats: PatternValue...) -> Pattern {
    stack(pats)
}

/// polyrhythm is an alias for stack.
public func polyrhythm(_ pats: PatternValue...) -> Pattern {
    stack(pats)
}

// MARK: - Concatenation

/// Combines patterns, switching between them successively, one per cycle.
public func slowcat(_ pats: [PatternValue]) -> Pattern {
    // Array elements are fastcat-ed, mirroring JS slowcat.
    let reified = pats.map { pat -> Pattern in
        if case .list(let items) = pat { return fastcat(items) }
        return reify(pat)
    }

    if reified.count == 1 { return reified[0] }

    let query: (State) -> [Hap] = { state in
        let span = state.span
        let patN = _mod(span.begin.sam().floorInt, reified.count)
        let pat = reified[patN]
        // A bit of maths to make sure that cycles from constituent patterns
        // aren't skipped. For example if three patterns are slowcat-ed, the
        // fourth cycle of the result should be the second (rather than fourth)
        // cycle from the first pattern.
        let offset = span.begin.floorFraction()
            .sub(span.begin.div(Fraction(reified.count)).floorFraction())
        return pat
            .withHapTime { $0.add(offset) }
            .query(state.setSpan(span.withTime { $0.sub(offset) }))
    }
    var steps: Fraction? = nil
    if StrudelRuntime.stepsEnabled {
        var acc: Fraction? = nil
        var first = true
        for pat in reified {
            if first { acc = pat.steps; first = false }
            else if let s = acc, let o = pat.steps { acc = s.lcm(o) }
            else { acc = nil }
        }
        steps = acc
    }
    return Pattern(query).splitQueries().setSteps(steps)
}

public func slowcat(_ pats: PatternValue...) -> Pattern {
    slowcat(pats)
}

/// Like slowcat, but skips cycles.
public func slowcatPrime(_ pats: [PatternValue]) -> Pattern {
    let reified = pats.map(reify)
    let query: (State) -> [Hap] = { state in
        let patN = _mod(state.span.begin.floorInt, reified.count)
        return reified[patN].query(state)
    }
    return Pattern(query).splitQueries()
}

/// The given items are concatenated, where each one takes one cycle ("<a b>").
public func cat(_ pats: PatternValue...) -> Pattern {
    slowcat(pats)
}

public func cat(_ pats: [PatternValue]) -> Pattern {
    slowcat(pats)
}

/// Like cat, but the items are crammed into one cycle ("a b").
public func fastcat(_ pats: [PatternValue]) -> Pattern {
    var result = slowcat(pats)
    if pats.count > 1 {
        result = result._fast(Fraction(pats.count))
        result.steps = Fraction(pats.count)
    }
    return result
}

public func fastcat(_ pats: PatternValue...) -> Pattern {
    fastcat(pats)
}

/// See fastcat.
public func sequence(_ pats: [PatternValue]) -> Pattern {
    fastcat(pats)
}

public func sequence(_ pats: PatternValue...) -> Pattern {
    fastcat(pats)
}

public func seq(_ pats: PatternValue...) -> Pattern {
    fastcat(pats)
}

/// Sequences nested arrays, tracking step counts (used by polymeter).
func _sequenceCount(_ x: PatternValue) -> (Pattern, Int) {
    if case .list(let items) = x {
        if items.isEmpty { return (silence, 0) }
        if items.count == 1 { return _sequenceCount(items[0]) }
        return (fastcat(items.map { .pattern(_sequenceCount($0).0) }), items.count)
    }
    return (reify(x), 1)
}

/// Aligns patterns to the given number of steps per cycle, repeating them
/// as necessary ("{a b c, d e}%4").
public func polymeter(steps: Int = 0, _ pats: [PatternValue]) -> Pattern {
    let seqs = pats.map(_sequenceCount)
    if seqs.isEmpty { return silence }
    let steps = steps == 0 ? seqs[0].1 : steps
    var result: [PatternValue] = []
    for (pat, sequenceLength) in seqs {
        if sequenceLength == 0 { continue }
        if steps == sequenceLength {
            result.append(.pattern(pat))
        } else {
            result.append(.pattern(pat._fast(Fraction(Int64(steps), Int64(sequenceLength)))))
        }
    }
    return stack(result).setSteps(Fraction(steps))
}

public func polymeter(steps: Int = 0, _ pats: PatternValue...) -> Pattern {
    polymeter(steps: steps, pats)
}

/// pm is an alias for polymeter.
public func pm(steps: Int = 0, _ pats: PatternValue...) -> Pattern {
    polymeter(steps: steps, pats)
}
