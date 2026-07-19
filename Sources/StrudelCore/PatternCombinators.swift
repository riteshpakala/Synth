// PatternCombinators.swift — the registered pattern functions.
// Ported from Strudel <https://codeberg.org/uzu/strudel> (packages/core/pattern.mjs,
// registered functions section) — AGPL-3.0-or-later.
//
// JS strudel "patternifies" arguments automatically: `fast("1 2")` works with a
// pattern of factors. Here, the public methods take `PatternValue` (which can
// hold a pattern) and patternify via the same innerJoin machinery; the `_`
// versions take plain values, exactly like the JS `_fast` etc.

import Foundation

// MARK: - Patternification helpers (the `register` machinery)

extension Pattern {
    /// Patternifies a 1-argument function: pure args take the fast path,
    /// patterns are bound with the given join (innerJoin by default).
    public func patternify(_ arg: PatternValue,
                    preserveSteps: Bool = false,
                    join: (Pattern) -> Pattern = { $0.innerJoin() },
                    _ f: @escaping (PatternValue, Pattern) -> Pattern) -> Pattern {
        let pat = self
        let argPat = reify(arg)
        let result: Pattern
        if let pv = argPat.pureValue {
            result = f(pv, pat)
        } else {
            result = join(argPat.fmap { v in .pattern(f(v, pat)) })
        }
        if preserveSteps { result.setSteps(pat.steps) }
        return result
    }

    /// Patternifies a 2-argument function via appLeft, like JS register.
    public func patternify2(_ a: PatternValue, _ b: PatternValue,
                     preserveSteps: Bool = false,
                     join: (Pattern) -> Pattern = { $0.innerJoin() },
                     _ f: @escaping (PatternValue, PatternValue, Pattern) -> Pattern) -> Pattern {
        let pat = self
        let aPat = reify(a)
        let bPat = reify(b)
        let result: Pattern
        if let av = aPat.pureValue, let bv = bPat.pureValue {
            result = f(av, bv, pat)
        } else {
            let funcs = aPat.fmap { x in
                PatternValue.function { y in .pattern(f(x, y, pat)) }
            }
            result = join(funcs.appLeft(bPat))
        }
        if preserveSteps { result.setSteps(pat.steps) }
        return result
    }

    /// Patternifies a 3-argument function via chained appLeft.
    public func patternify3(_ a: PatternValue, _ b: PatternValue, _ c: PatternValue,
                     preserveSteps: Bool = false,
                     join: (Pattern) -> Pattern = { $0.innerJoin() },
                     _ f: @escaping (PatternValue, PatternValue, PatternValue, Pattern) -> Pattern) -> Pattern {
        let pat = self
        let aPat = reify(a)
        let bPat = reify(b)
        let cPat = reify(c)
        let result: Pattern
        if let av = aPat.pureValue, let bv = bPat.pureValue, let cv = cPat.pureValue {
            result = f(av, bv, cv, pat)
        } else {
            let funcs = aPat.fmap { x in
                PatternValue.function { y in
                    .function { z in .pattern(f(x, y, z, pat)) }
                }
            }
            result = join(funcs.appLeft(bPat).appLeft(cPat))
        }
        if preserveSteps { result.setSteps(pat.steps) }
        return result
    }

    /// Minimal control setter used by combinators that reference controls
    /// (gain, speed, pan, unit, color). Same semantics as `pat.set(ctrl(v))`.
    public func withControl(_ key: String, _ value: PatternValue) -> Pattern {
        set.in(.pattern(reify(value).fmap { v in .map([key: v]) }))
    }
}

// MARK: - Numerical transformations

extension Pattern {
    public func round() -> Pattern {
        asNumber().fmap { v in v.doubleValue.map { .number(($0).rounded(.toNearestOrAwayFromZero)) } ?? v }
    }

    public func floor() -> Pattern {
        asNumber().fmap { v in v.doubleValue.map { .number($0.rounded(.down)) } ?? v }
    }

    public func ceil() -> Pattern {
        asNumber().fmap { v in v.doubleValue.map { .number($0.rounded(.up)) } ?? v }
    }

    public func log2() -> Pattern {
        asNumber().fmap { v in v.doubleValue.map { .number(Foundation.log2($0)) } ?? v }
    }

    /// Unipolar [0,1] → bipolar [-1,1].
    public func toBipolar() -> Pattern {
        fmap { v in v.doubleValue.map { .number($0 * 2 - 1) } ?? v }
    }

    /// Bipolar [-1,1] → unipolar [0,1].
    public func fromBipolar() -> Pattern {
        fmap { v in v.doubleValue.map { .number(($0 + 1) / 2) } ?? v }
    }

    /// Scales unipolar values to the given range.
    public func range(_ min: PatternValue, _ max: PatternValue) -> Pattern {
        mul(.number((max.doubleValue ?? 1) - (min.doubleValue ?? 0))).add(min)
    }

    public func _range(_ min: Double, _ max: Double) -> Pattern {
        range(.number(min), .number(max))
    }

    /// Like range, but exponential.
    public func rangex(_ min: PatternValue, _ max: PatternValue) -> Pattern {
        _range(Foundation.log(min.doubleValue ?? 1), Foundation.log(max.doubleValue ?? 1))
            .fmap { v in v.doubleValue.map { .number(Foundation.exp($0)) } ?? v }
    }

    /// Scales bipolar values to the given range.
    public func range2(_ min: PatternValue, _ max: PatternValue) -> Pattern {
        fromBipolar().range(min, max)
    }

    /// Divides list values written with ":", e.g. `ratio("5:4")` → 1.25.
    public func ratio() -> Pattern {
        fmap { v in
            guard let list = v.listValue, let first = list.first?.doubleValue else { return v }
            let result = list.dropFirst().reduce(first) { acc, n in acc / (n.doubleValue ?? 1) }
            return .number(result)
        }
    }
}

// MARK: - Temporal transformations

extension Pattern {
    /// Compress each cycle into the given timespan, leaving a gap.
    public func _compress(_ b: Fraction, _ e: Fraction) -> Pattern {
        if b > e || b > .one || e > .one || b < .zero || e < .zero {
            return silence
        }
        return _fastGap(Fraction.one.div(e.sub(b)))._late(b)
    }

    public func compress(_ b: PatternValue, _ e: PatternValue) -> Pattern {
        patternify2(b, e) { b, e, pat in
            pat._compress(b.fractionValue ?? .zero, e.fractionValue ?? .one)
        }
    }

    public func compressSpan(_ span: TimeSpan) -> Pattern {
        _compress(span.begin, span.end)
    }

    /// Speeds up a pattern like fast, but leaves a gap in the remaining space.
    public func _fastGap(_ factor: Fraction) -> Pattern {
        // Drop zero-width queries at the start of the next cycle.
        let qf: (TimeSpan) -> TimeSpan? = { span in
            let cycle = span.begin.sam()
            let bpos = span.begin.sub(cycle).mul(factor).min(.one)
            let epos = span.end.sub(cycle).mul(factor).min(.one)
            if bpos >= .one { return nil }
            return TimeSpan(cycle.add(bpos), cycle.add(epos))
        }
        // Also fiddly, to maintain the right 'whole' relative to the part.
        let ef: (Hap) -> Hap = { hap in
            let begin = hap.part.begin
            let end = hap.part.end
            let cycle = begin.sam()
            let beginPos = begin.sub(cycle).div(factor).min(.one)
            let endPos = end.sub(cycle).div(factor).min(.one)
            let newPart = TimeSpan(cycle.add(beginPos), cycle.add(endPos))
            let newWhole: TimeSpan? = hap.whole.map { whole in
                TimeSpan(
                    newPart.begin.sub(begin.sub(whole.begin).div(factor)),
                    newPart.end.add(whole.end.sub(end).div(factor))
                )
            }
            return Hap(whole: newWhole, part: newPart, value: hap.value, context: hap.context)
        }
        return withQuerySpanMaybe(qf).withHap(ef).splitQueries()
    }

    public func fastGap(_ factor: PatternValue) -> Pattern {
        patternify(factor) { f, pat in pat._fastGap(f.fractionValue ?? .one) }
    }

    /// Similar to compress, but doesn't leave gaps and can be > 1 cycle.
    public func _focus(_ b: Fraction, _ e: Fraction) -> Pattern {
        _early(b.sam())._fast(Fraction.one.div(e.sub(b)))._late(b)
    }

    public func focus(_ b: PatternValue, _ e: PatternValue) -> Pattern {
        patternify2(b, e) { b, e, pat in
            pat._focus(b.fractionValue ?? .zero, e.fractionValue ?? .one)
        }
    }

    public func _focusSpan(_ span: TimeSpan) -> Pattern {
        _focus(span.begin, span.end)
    }

    /// Speed up a pattern by the given factor. "*" in mini notation.
    public func _fast(_ factor: Fraction) -> Pattern {
        if factor.isZero { return silence }
        return withQueryTime { $0.mul(factor) }
            .withHapTime { $0.div(factor) }
            .setSteps(steps)
    }

    public func fast(_ factor: PatternValue) -> Pattern {
        patternify(factor, preserveSteps: true) { f, pat in pat._fast(f.fractionValue ?? .one) }
    }

    /// Alias for fast.
    public func density(_ factor: PatternValue) -> Pattern { fast(factor) }

    /// Slow down a pattern. "/" in mini notation.
    public func _slow(_ factor: Fraction) -> Pattern {
        if factor.isZero { return silence }
        return _fast(Fraction.one.div(factor))
    }

    public func slow(_ factor: PatternValue) -> Pattern {
        patternify(factor, preserveSteps: true) { f, pat in pat._slow(f.fractionValue ?? .one) }
    }

    public func sparsity(_ factor: PatternValue) -> Pattern { slow(factor) }

    /// Speeds up both the pattern and sample playback.
    public func hurry(_ r: PatternValue) -> Pattern {
        patternify(r) { r, pat in
            pat._fast(r.fractionValue ?? .one)
                .mul(.map(["speed": .number(r.doubleValue ?? 1)]))
        }
    }

    /// Carries out an operation 'inside' a cycle.
    public func inside(_ factor: PatternValue, _ f: @escaping (Pattern) -> Pattern) -> Pattern {
        patternify(factor) { n, pat in
            let fr = n.fractionValue ?? .one
            return f(pat._slow(fr))._fast(fr)
        }
    }

    /// Carries out an operation 'outside' a cycle.
    public func outside(_ factor: PatternValue, _ f: @escaping (Pattern) -> Pattern) -> Pattern {
        patternify(factor) { n, pat in
            let fr = n.fractionValue ?? .one
            return f(pat._fast(fr))._slow(fr)
        }
    }

    /// Applies the function every n cycles, starting from the last cycle.
    public func lastOf(_ n: PatternValue, _ f: @escaping (Pattern) -> Pattern) -> Pattern {
        patternify(n) { n, pat in
            let count = n.intValue ?? 1
            guard count > 0 else { return pat }
            var pats = [PatternValue](repeating: .pattern(pat), count: max(0, count - 1))
            pats.append(.pattern(f(pat)))
            return slowcatPrime(pats)
        }
    }

    /// Applies the function every n cycles, starting from the first cycle.
    public func firstOf(_ n: PatternValue, _ f: @escaping (Pattern) -> Pattern) -> Pattern {
        patternify(n) { n, pat in
            let count = n.intValue ?? 1
            guard count > 0 else { return pat }
            var pats = [PatternValue](repeating: .pattern(pat), count: max(0, count - 1))
            pats.insert(.pattern(f(pat)), at: 0)
            return slowcatPrime(pats)
        }
    }

    /// Alias for firstOf.
    public func every(_ n: PatternValue, _ f: @escaping (Pattern) -> Pattern) -> Pattern {
        firstOf(n, f)
    }

    /// Applies the given function to the pattern (single-function layer).
    public func apply(_ f: (Pattern) -> Pattern) -> Pattern {
        f(self)
    }

    public func applyN(_ n: PatternValue, _ f: @escaping (Pattern) -> Pattern) -> Pattern {
        patternify(n) { n, pat in
            var result = pat
            for _ in 0..<(n.intValue ?? 0) { result = f(result) }
            return result
        }
    }

    /// Plays the pattern at the given cycles per minute.
    public func cpm(_ cpm: PatternValue) -> Pattern {
        patternify(cpm) { c, pat in
            pat._fast(Fraction((c.doubleValue ?? 60) / 60))
        }
    }

    /// Nudge a pattern to start earlier in time (Tidal's <~).
    public func _early(_ offset: Fraction) -> Pattern {
        withQueryTime { $0.add(offset) }.withHapTime { $0.sub(offset) }
    }

    public func early(_ offset: PatternValue) -> Pattern {
        patternify(offset, preserveSteps: true) { o, pat in pat._early(o.fractionValue ?? .zero) }
    }

    /// Nudge a pattern to start later in time (Tidal's ~>).
    public func _late(_ offset: Fraction) -> Pattern {
        _early(Fraction.zero.sub(offset))
    }

    public func late(_ offset: PatternValue) -> Pattern {
        patternify(offset, preserveSteps: true) { o, pat in pat._late(o.fractionValue ?? .zero) }
    }

    /// Plays a portion of the pattern over the whole cycle span.
    public func _zoom(_ s: Fraction, _ e: Fraction) -> Pattern {
        if s >= e { return nothing }
        let d = e.sub(s)
        let newSteps = StrudelRuntime.stepsEnabled ? steps.map { $0.mul(d) } : nil
        return withQuerySpan { span in span.withCycle { $0.mul(d).add(s) } }
            .withHapSpan { span in span.withCycle { $0.sub(s).div(d) } }
            .splitQueries()
            .setSteps(newSteps)
    }

    public func zoom(_ s: PatternValue, _ e: PatternValue) -> Pattern {
        patternify2(s, e) { s, e, pat in
            pat._zoom(s.fractionValue ?? .zero, e.fractionValue ?? .one)
        }
    }

    public func zoomArc(_ a: TimeSpan) -> Pattern {
        _zoom(a.begin, a.end)
    }

    /// Splits into n slices and plays them by a pattern of indices.
    public func bite(_ npat: PatternValue, _ ipat: PatternValue) -> Pattern {
        let pat = self
        return reify(ipat)
            .fmap { i in
                PatternValue.function { n in
                    let nf = n.fractionValue ?? .one
                    let a = (i.fractionValue ?? .zero).div(nf).mod(.one)
                    let b = a.add(Fraction.one.div(nf))
                    return .pattern(pat._zoom(a, b))
                }
            }
            .appLeft(reify(npat))
            .squeezeJoin()
    }

    /// Selects a fraction of the pattern and repeats it to fill the cycle.
    public func linger(_ t: PatternValue) -> Pattern {
        patternify(t, preserveSteps: true) { t, pat in
            let f = t.fractionValue ?? .one
            if f.isZero { return silence }
            if f < .zero {
                return pat._zoom(f.add(.one), .one)._slow(f)
            }
            return pat._zoom(.zero, f)._slow(f)
        }
    }

    /// Samples the pattern at n events per cycle.
    public func segment(_ rate: PatternValue) -> Pattern {
        patternify(rate) { rate, pat in
            pat.structure(.pattern(pure(.bool(true))._fast(rate.fractionValue ?? .one)))
                .setSteps(rate.fractionValue)
        }
    }

    public func seg(_ rate: PatternValue) -> Pattern { segment(rate) }

    public func _segment(_ rate: Fraction) -> Pattern {
        structure(.pattern(pure(.bool(true))._fast(rate))).setSteps(rate)
    }

    /// Breaks each cycle into n slices, delaying the second half of each.
    public func swingBy(_ swing: PatternValue, _ n: PatternValue) -> Pattern {
        inside(n) { $0.late(.pattern(sequence(0, .number((swing.doubleValue ?? 0) / 2)))) }
    }

    public func swing(_ n: PatternValue) -> Pattern {
        swingBy(.number(1.0 / 3), n)
    }

    /// Swaps 1s and 0s in a binary pattern.
    public func invert() -> Pattern {
        fmap { v in .bool(!v.truthy) }.setSteps(steps)
    }

    public func inv() -> Pattern { invert() }

    /// Applies the function whenever the given pattern is true.
    public func when(_ on: PatternValue, _ f: @escaping (Pattern) -> Pattern) -> Pattern {
        patternify(on) { on, pat in
            on.truthy ? f(pat) : pat
        }
    }

    /// Superimposes the function result, delayed by the given time.
    public func off(_ timePat: PatternValue, _ f: (Pattern) -> Pattern) -> Pattern {
        StrudelCore.stack(.pattern(self), .pattern(f(late(timePat))))
    }

    /// Breakbeat feel: every other cycle plays twice as fast, shifted by 1/4.
    public func brak() -> Pattern {
        when(.pattern(slowcat(false, true))) { x in
            fastcat(.pattern(x), .pattern(silence))._late(Fraction(1, 4))
        }
    }

    /// Reverse each cycle.
    public func rev() -> Pattern {
        let pat = self
        let query: (State) -> [Hap] = { state in
            let span = state.span
            let cycle = span.begin.sam()
            let nextCycle = span.begin.nextSam()
            func reflect(_ toReflect: TimeSpan) -> TimeSpan {
                let reflected = toReflect.withTime { cycle.add(nextCycle.sub($0)) }
                return TimeSpan(reflected.end, reflected.begin)
            }
            let haps = pat.query(state.setSpan(reflect(span)))
            return haps.map { $0.withSpan(reflect) }
        }
        return Pattern(query).splitQueries().setSteps(steps)
    }

    /// Reverse the whole pattern (over all time, not per cycle).
    public func revv() -> Pattern {
        let negateSpan: (TimeSpan) -> TimeSpan = { span in
            TimeSpan(Fraction.zero.sub(span.end), Fraction.zero.sub(span.begin))
        }
        return withQuerySpan(negateSpan).withHapSpan(negateSpan)
    }

    /// Shifts each event by the given fraction of its timespan.
    public func pressBy(_ r: PatternValue) -> Pattern {
        patternify(r) { r, pat in pat._pressBy(r.fractionValue ?? Fraction(1, 2)) }
    }

    public func _pressBy(_ r: Fraction) -> Pattern {
        fmap { x in .pattern(pure(x)._compress(r, .one)) }.squeezeJoin()
    }

    /// Syncopation: shifts each event halfway into its timespan.
    public func press() -> Pattern {
        _pressBy(Fraction(1, 2))
    }

    /// Silences the pattern.
    public func hush() -> Pattern {
        silence
    }

    /// Alternates between forwards and backwards each cycle.
    public func palindrome() -> Pattern {
        lastOf(2) { $0.rev() }.setSteps(steps)
    }

    /// Repeats each event the given number of times.
    public func ply(_ factor: PatternValue) -> Pattern {
        patternify(factor) { f, pat in
            let fr = f.fractionValue ?? .one
            let result = pat.fmap { x in PatternValue.pattern(pure(x)._fast(fr)) }.squeezeJoin()
            if StrudelRuntime.stepsEnabled, let s = pat.steps {
                result.setSteps(fr.mul(s))
            }
            return result
        }
    }

    /// Jux with adjustable stereo width.
    public func juxBy(_ by: PatternValue, _ f: @escaping (Pattern) -> Pattern) -> Pattern {
        patternify(by) { by, pat in
            let half = (by.doubleValue ?? 1) / 2
            func withPan(_ offset: Double) -> (PatternValue) -> PatternValue {
                { val in
                    var map = val.mapValue ?? ["value": val]
                    let pan = map["pan"]?.doubleValue ?? 0.5
                    map["pan"] = .number(pan + offset)
                    return .map(map)
                }
            }
            let left = pat.withValue(withPan(-half))
            let right = f(pat.withValue(withPan(half)))
            let result = StrudelCore.stack(.pattern(left), .pattern(right))
            if StrudelRuntime.stepsEnabled {
                result.setSteps(lcm(left.steps, right.steps))
            }
            return result
        }
    }

    /// Applies a function to the right-hand audio channel only.
    public func jux(_ f: @escaping (Pattern) -> Pattern) -> Pattern {
        juxBy(1, f)
    }

    /// Superimpose and offset multiple times, applying a function each time.
    public func echoWith(_ times: PatternValue, _ time: PatternValue,
                         _ f: @escaping (Pattern, Int) -> Pattern) -> Pattern {
        patternify2(times, time) { times, time, pat in
            let count = times.intValue ?? 1
            let t = time.fractionValue ?? .zero
            let layers = (0..<max(count, 0)).map { i in
                PatternValue.pattern(f(pat._late(t.mul(Fraction(i))), i))
            }
            return StrudelCore.stack(layers)
        }
    }

    public func stutWith(_ times: PatternValue, _ time: PatternValue,
                         _ f: @escaping (Pattern, Int) -> Pattern) -> Pattern {
        echoWith(times, time, f)
    }

    /// Echo with decreasing gain per repeat.
    public func echo(_ times: PatternValue, _ time: PatternValue, _ feedback: PatternValue) -> Pattern {
        let fb = feedback.doubleValue ?? 1
        return echoWith(times, time) { pat, i in
            pat.withControl("gain", .number(Foundation.pow(fb, Double(i))))
        }
    }

    /// Deprecated variant of echo with flipped args.
    public func stut(_ times: PatternValue, _ feedback: PatternValue, _ time: PatternValue) -> Pattern {
        echo(times, time, feedback)
    }

    /// The ply variant that applies a function cumulatively to each repeat.
    public func plyWith(_ factor: PatternValue, _ f: @escaping (Pattern) -> Pattern) -> Pattern {
        patternify(factor) { factor, pat in
            let n = factor.intValue ?? 1
            let result = pat.fmap { x -> PatternValue in
                let versions = (0..<max(n, 1)).map { i -> PatternValue in
                    var p = pure(x)
                    for _ in 0..<i { p = f(p) }
                    return .pattern(p)
                }
                return .pattern(StrudelCore.cat(versions)._fast(Fraction(n)))
            }.squeezeJoin()
            if StrudelRuntime.stepsEnabled, let s = pat.steps {
                result.setSteps(Fraction(n).mul(s))
            }
            return result
        }
    }

    /// Cycles through subdivisions, incrementing the start each cycle.
    func _iter(_ times: Fraction, back: Bool) -> Pattern {
        let n = times.floorInt
        guard n > 0 else { return self }
        let shifted = (0..<n).map { i -> PatternValue in
            let amount = Fraction(i).div(times)
            return .pattern(back ? _late(amount) : _early(amount))
        }
        return slowcat(shifted)
    }

    public func iter(_ times: PatternValue) -> Pattern {
        patternify(times, preserveSteps: true) { t, pat in
            pat._iter(t.fractionValue ?? .one, back: false)
        }
    }

    public func iterBack(_ times: PatternValue) -> Pattern {
        patternify(times, preserveSteps: true) { t, pat in
            pat._iter(t.fractionValue ?? .one, back: true)
        }
    }

    /// Repeats each cycle the given number of times.
    public func repeatCycles(_ n: PatternValue) -> Pattern {
        patternify(n, preserveSteps: true) { n, pat in pat._repeatCycles(n.intValue ?? 1) }
    }

    public func _repeatCycles(_ n: Int) -> Pattern {
        let pat = self
        guard n != 0 else { return silence }
        return Pattern { state in
            let cycle = state.span.begin.sam()
            let sourceCycle = cycle.div(Fraction(n)).sam()
            let delta = cycle.sub(sourceCycle)
            let shifted = state.withSpan { span in span.withTime { $0.sub(delta) } }
            return pat.query(shifted).map { hap in
                hap.withSpan { span in span.withTime { $0.add(delta) } }
            }
        }.splitQueries()
    }

    /// Divides into n parts, applying the function to one part per cycle.
    func _chunk(_ n: Int, _ f: @escaping (Pattern) -> Pattern, back: Bool, fast: Bool) -> Pattern {
        var binary: [PatternValue] = [.bool(true)]
        binary.append(contentsOf: [PatternValue](repeating: .bool(false), count: max(0, n - 1)))
        // Invert 'back' because we shift the pattern forwards, time backwards.
        let binaryPat = sequence(binary)._iter(Fraction(n), back: !back)
        let source = fast ? self : _repeatCycles(n)
        return source.when(.pattern(binaryPat), f)
    }

    public func chunk(_ n: PatternValue, _ f: @escaping (Pattern) -> Pattern) -> Pattern {
        patternify(n, preserveSteps: true) { n, pat in
            pat._chunk(n.intValue ?? 1, f, back: false, fast: false)
        }
    }

    public func chunkBack(_ n: PatternValue, _ f: @escaping (Pattern) -> Pattern) -> Pattern {
        patternify(n, preserveSteps: true) { n, pat in
            pat._chunk(n.intValue ?? 1, f, back: true, fast: false)
        }
    }

    public func fastChunk(_ n: PatternValue, _ f: @escaping (Pattern) -> Pattern) -> Pattern {
        patternify(n, preserveSteps: true) { n, pat in
            pat._chunk(n.intValue ?? 1, f, back: false, fast: true)
        }
    }

    public func bypass(_ on: PatternValue) -> Pattern {
        patternify(on, preserveSteps: true) { on, pat in
            on.truthy ? silence : pat
        }
    }

    /// Loops the pattern inside an offset for the given number of cycles.
    public func ribbon(_ offset: PatternValue, _ cycles: PatternValue) -> Pattern {
        patternify2(offset, cycles) { offset, cycles, pat in
            pat._early(offset.fractionValue ?? .zero)
                .restart(.pattern(pure(.number(1))._slow(cycles.fractionValue ?? .one)))
        }
    }

    /// Tags each hap with an identifier, for filtering.
    public func tag(_ tag: String) -> Pattern {
        withContext { ctx in
            var out = ctx
            out.tags = (ctx.tags ?? []) + [tag]
            return out
        }
    }

    /// Filters haps using the given function.
    public func filter(_ test: @escaping (Hap) -> Bool) -> Pattern {
        withHaps { haps, _ in haps.filter(test) }
    }

    /// Filters haps by their begin time.
    public func filterWhen(_ test: @escaping (Fraction) -> Bool) -> Pattern {
        filter { hap in
            guard let whole = hap.whole else { return false }
            return test(whole.begin)
        }
    }

    /// Applies a function to only a part of a pattern (start/end within cycle).
    public func within(_ a: Fraction, _ b: Fraction, _ f: (Pattern) -> Pattern) -> Pattern {
        StrudelCore.stack(
            .pattern(f(filterWhen { t in t.cyclePos() >= a && t.cyclePos() <= b })),
            .pattern(filterWhen { t in t.cyclePos() < a || t.cyclePos() > b })
        )
    }

    // MARK: Sample-related (value-map manipulating)

    /// Cuts each sample into n parts (granular-friendly begin/end slices).
    public func chop(_ n: PatternValue) -> Pattern {
        patternify(n) { n, pat in
            let count = max(n.intValue ?? 1, 1)
            let sliceObjects: [ControlMap] = (0..<count).map { i in
                ["begin": .number(Double(i) / Double(count)),
                 "end": .number(Double(i + 1) / Double(count))]
            }
            func merge(_ a: PatternValue, _ b: ControlMap) -> PatternValue {
                var out = a.mapValue ?? ["value": a]
                if let ab = out["begin"]?.doubleValue, let ae = out["end"]?.doubleValue {
                    let d = ae - ab
                    out["begin"] = .number(ab + (b["begin"]?.doubleValue ?? 0) * d)
                    out["end"] = .number(ab + (b["end"]?.doubleValue ?? 1) * d)
                } else {
                    out["begin"] = b["begin"]
                    out["end"] = b["end"]
                }
                return .map(out)
            }
            let result = pat.squeezeBind { o in
                sequence(sliceObjects.map { merge(o, $0) })
            }
            if StrudelRuntime.stepsEnabled, let s = pat.steps {
                result.setSteps(Fraction(count).mul(s))
            }
            return result
        }
    }

    /// Progressive portions of each sample at each loop.
    public func striate(_ n: PatternValue) -> Pattern {
        patternify(n) { n, pat in
            let count = max(n.intValue ?? 1, 1)
            let sliceObjects: [PatternValue] = (0..<count).map { i in
                .map(["begin": .number(Double(i) / Double(count)),
                      "end": .number(Double(i + 1) / Double(count))])
            }
            let slicePat = slowcat(sliceObjects)
            let result = pat.set.in(.pattern(slicePat))._fast(Fraction(count))
            if StrudelRuntime.stepsEnabled, let s = pat.steps {
                result.setSteps(Fraction(count).mul(s))
            }
            return result
        }
    }

    func _loopAt(_ factor: Fraction, cps: Double) -> Pattern {
        withControl("speed", .number(1 / factor.doubleValue * cps))
            .withControl("unit", .string("c"))
            ._slow(factor)
    }

    /// Fits the sample into the given number of cycles by changing speed.
    public func loopAt(_ factor: PatternValue) -> Pattern {
        patternify(factor) { factor, pat in
            let f = factor.fractionValue ?? .one
            let steps = pat.steps.map { $0.div(f) }
            return Pattern({ state in
                let cps = state.controls["_cps"]?.doubleValue ?? 0.5
                return pat._loopAt(f, cps: cps).query(state)
            }, steps: steps)
        }
    }

    /// Chops samples into slices, triggered by a pattern of slice indices.
    public func slice(_ npat: PatternValue, _ ipat: PatternValue) -> Pattern {
        let nP = reify(npat)
        let iP = reify(ipat)
        let oP = self
        return nP.innerBind { n in
            iP.outerBind { i in
                oP.outerBind { o in
                    let oMap = o.mapValue ?? ["s": o]
                    var out = oMap
                    if let list = n.listValue {
                        let idx = i.intValue ?? 0
                        out["begin"] = idx < list.count ? list[idx] : .number(0)
                        out["end"] = idx + 1 < list.count ? list[idx + 1] : .number(1)
                    } else {
                        let nVal = n.doubleValue ?? 1
                        let iVal = i.doubleValue ?? 0
                        out["begin"] = .number(iVal / nVal)
                        out["end"] = .number((iVal + 1) / nVal)
                    }
                    out["_slices"] = n
                    return pure(.map(out))
                }
            }
        }.setSteps(iP.steps)
    }

    /// Like slice, but adjusts playback speed to match the step duration.
    public func splice(_ npat: PatternValue, _ ipat: PatternValue) -> Pattern {
        let sliced = slice(npat, ipat)
        return Pattern { state in
            let cps = state.controls["_cps"]?.doubleValue ?? 1
            return sliced.query(state).map { hap in
                hap.withValue { v in
                    var map = v.mapValue ?? [:]
                    let slices = map["_slices"]?.doubleValue ?? 1
                    let dur = (hap.whole?.duration ?? .one).doubleValue
                    let existing = map["speed"]?.doubleValue ?? 1
                    if map["speed"] == nil {
                        map["speed"] = .number(cps / slices / dur * existing)
                    }
                    if map["unit"] == nil {
                        map["unit"] = .string("c")
                    }
                    return .map(map)
                }
            }
        }.setSteps(reify(ipat).steps)
    }

    /// Makes the sample fit its event duration.
    public func fit() -> Pattern {
        withHaps { haps, state in
            haps.map { hap in
                hap.withValue { v in
                    var map = v.mapValue ?? ["value": v]
                    let begin = map["begin"]?.doubleValue ?? 0
                    let end = map["end"]?.doubleValue ?? 1
                    let slicedur = end - begin
                    let cps = state.controls["_cps"]?.doubleValue ?? 1
                    let dur = (hap.whole?.duration ?? .one).doubleValue
                    map["speed"] = .number(cps / dur * slicedur)
                    map["unit"] = .string("c")
                    return .map(map)
                }
            }
        }
    }

    // MARK: Arpeggios

    /// Applies a function to groups of congruent (chord) haps.
    public func arpWith(_ f: @escaping ([PatternValue]) -> PatternValue) -> Pattern {
        collect()
            .fmap { v in .pattern(reify(f(v.listValue ?? []))) }
            .innerJoin()
    }

    /// Selects chord indices with a pattern, e.g. `.arp("0 [0,2] 1")`.
    public func arp(_ indices: PatternValue) -> Pattern {
        arpWith { haps in
            .pattern(reify(indices).fmap { i in
                let idx = _mod(i.intValue ?? 0, Swift.max(haps.count, 1))
                return haps.isEmpty ? .null : haps[idx]
            })
        }
    }

    // MARK: into / unjoin

    /// Breaks a pattern into a pattern of patterns per the binary structure.
    public func unjoin(_ pieces: Pattern, _ f: @escaping (Pattern) -> Pattern) -> Pattern {
        let pat = self
        return pieces.withHap { hap in
            hap.withValue { v in
                guard let whole = hap.whole, v.truthy else { return .pattern(pat) }
                return .pattern(f(pat._ribbonSpan(whole.begin, whole.duration)))
            }
        }
    }

    /// Applies a function to looped subcycles selected by a binary pattern.
    public func into(_ pieces: PatternValue, _ f: @escaping (Pattern) -> Pattern) -> Pattern {
        unjoin(reify(pieces), f).innerJoin()
    }

    func _ribbonSpan(_ offset: Fraction, _ cycles: Fraction) -> Pattern {
        _early(offset).restart(.pattern(pure(.number(1))._slow(cycles)))
    }

    // MARK: Crossfade

    /// Cross-fades between this pattern and another (0 = all this, 1 = all other).
    public func xfade(_ pos: PatternValue, _ b: PatternValue) -> Pattern {
        StrudelCore.xfade(.pattern(self), pos, b)
    }

    /// Creates structure from divisions of a cycle; useful for rhythms.
    public func beat(_ t: PatternValue, _ div: PatternValue) -> Pattern {
        patternify2(t, div) { t, div, pat in
            let divF = div.fractionValue ?? Fraction(16)
            let tF = (t.fractionValue ?? .zero).mod(divF)
            let b = tF.div(divF)
            let e = tF.add(.one).div(divF)
            return pat.fmap { x in .pattern(pure(x)._compress(b, e)) }.innerJoin()
        }
    }
}

// MARK: - Free-function versions

/// Cross-fades between left and right from 0 to 1.
public func xfade(_ a: PatternValue, _ pos: PatternValue, _ b: PatternValue) -> Pattern {
    let fadeGain: (Double) -> Double = { p in p < 0.5 ? 1 : 1 - (p - 0.5) / 0.5 }
    let posPat = reify(pos)
    let aPat = reify(a)
    let bPat = reify(b)
    let gaina = posPat.fmap { v in PatternValue.map(["gain": .number(fadeGain(v.doubleValue ?? 0))]) }
    let gainb = posPat.fmap { v in PatternValue.map(["gain": .number(fadeGain(1 - (v.doubleValue ?? 0)))]) }
    return stack(.pattern(aPat.mul(.pattern(gaina))), .pattern(bPat.mul(.pattern(gainb))))
}

/// Combines patterns over multiple cycles: each section is [cycles, pattern].
public func arrange(_ sections: (Int, PatternValue)...) -> Pattern {
    let total = sections.reduce(0) { $0 + $1.0 }
    let stretched = sections.map { (cycles, section) in
        (Fraction(cycles), reify(section)._fast(Fraction(cycles)))
    }
    return stepcat(stretched.map { (t, p) in (t, PatternValue.pattern(p)) })._slow(Fraction(total))
}

/// Like arrange, but with explicit start/stop times so patterns can overlap.
public func seqPLoop(_ parts: (PatternValue, PatternValue, PatternValue)...) -> Pattern {
    var total = Fraction.zero
    var resolved: [(Fraction, Fraction, Pattern)] = []
    for (start, stop, pat) in parts {
        let s = start.fractionValue ?? total
        let e = stop.fractionValue ?? s
        resolved.append((s, e, reify(pat)))
        total = e
    }
    guard !total.isZero else { return silence }
    let pats: [PatternValue] = resolved.map { (start, stop, pat) in
        .pattern(pure(.pattern(pat))._compress(start.div(total), stop.div(total)))
    }
    return stack(pats)._slow(total).innerJoin()
}

/// Turns a list of patterns into a single pattern of list values.
public func parray(_ pats: [PatternValue]) -> Pattern {
    var acc = pure(.list([]))
    for p in pats {
        acc = acc.fmap { list in
            PatternValue.function { v in
                .list((list.listValue ?? []) + [v])
            }
        }.appBoth(reify(p))
    }
    return acc
}

/// Takes a list of patterns and returns a pattern of lists (structure from all).
public func sequenceP(_ pats: [Pattern]) -> Pattern {
    var result = pure(.list([]))
    for pat in pats {
        result = result.bind { list in
            pat.fmap { v in .list((list.listValue ?? []) + [v]) }
        }
    }
    return result
}

/// Converts numbers to patterns of digits in the given base.
public func base(_ n: PatternValue, _ b: PatternValue = 10, _ d: PatternValue = 0) -> Pattern {
    let nPat = reify(n)
    let bPat = reify(b)
    let dPat = reify(d)
    return dPat.fmap { e -> PatternValue in
        .pattern(bPat.fmap { c -> PatternValue in
            .pattern(nPat.fmap { v -> PatternValue in
                var digits: [PatternValue] = []
                var value = v.intValue ?? 0
                let radix = Swift.max(c.intValue ?? 10, 2)
                while value > 0 {
                    digits.insert(.number(Double(value % radix)), at: 0)
                    value /= radix
                }
                if let e = e.intValue, e > 0, digits.count > e {
                    digits = Array(digits.suffix(e))
                }
                return .pattern(sequence(digits))
            }.squeezeJoin())
        }.squeezeJoin())
    }.squeezeJoin()
}

/// Exposes a custom value at query time (mutable state without evaluation).
public func ref(_ accessor: @escaping () -> PatternValue) -> Pattern {
    pure(.number(1)).withValue { _ in .pattern(reify(accessor())) }.innerJoin()
}

// MARK: - Partials & phases (pattern.mjs Pattern.prototype.partials/phases)

/// Turns a list or pattern into a pattern of list values (pattern.mjs parray
/// via _ensureListPattern).
func _ensureListPattern(_ list: PatternValue) -> Pattern {
    if case .list(let items) = list {
        return parray(items)
    }
    return reify(list)
}

extension Pattern {
    /// Scales the magnitudes of the harmonics of the core synths, or defines
    /// a custom waveform via `s("user").partials([1, 0, 1, 0.5])`.
    public func partials(_ list: PatternValue) -> Pattern {
        withValue { v in
            PatternValue.function { l in
                var m = v.asControlMap()
                m["partials"] = l
                return .map(m)
            }
        }.appLeft(_ensureListPattern(list))
    }

    /// Rotates the harmonics by a list of [0,1) phases.
    public func phases(_ list: PatternValue) -> Pattern {
        withValue { v in
            PatternValue.function { l in
                var m = v.asControlMap()
                m["phases"] = l
                return .map(m)
            }
        }.appLeft(_ensureListPattern(list))
    }
}

/// Top-level partials/phases (patterns of control maps).
public func partials(_ list: PatternValue) -> Pattern {
    _ensureListPattern(list).fmap { l in .map(["partials": l]) }
}

public func phases(_ list: PatternValue) -> Pattern {
    _ensureListPattern(list).fmap { l in .map(["phases": l]) }
}

// MARK: - Distortion algorithm combinators (pattern.mjs _distortWithAlg)

extension Pattern {
    /// `pat.soft(1.5)` == `pat.distort([1.5, 1, "soft"])`; args can be a
    /// mini list "amount:volume".
    func _distortWith(_ name: String, _ args: PatternValue) -> Pattern {
        let argsPat = reify(args).fmap { v -> PatternValue in
            if let list = v.listValue {
                return .list(list + [.string(name)])
            }
            return .list([v, .number(1), .string(name)])
        }
        return control("distort", .pattern(argsPat))
    }

    /// Soft-clipping distortion (tanh).
    public func soft(_ args: PatternValue) -> Pattern { _distortWith("soft", args) }
    /// Hard-clipping distortion.
    public func hard(_ args: PatternValue) -> Pattern { _distortWith("hard", args) }
    /// Cubic polynomial distortion.
    public func cubic(_ args: PatternValue) -> Pattern { _distortWith("cubic", args) }
    /// Diode-emulating distortion.
    public func diode(_ args: PatternValue) -> Pattern { _distortWith("diode", args) }
    /// Asymmetrical diode distortion.
    public func asym(_ args: PatternValue) -> Pattern { _distortWith("asym", args) }
    /// Wavefolding distortion.
    public func fold(_ args: PatternValue) -> Pattern { _distortWith("fold", args) }
    /// Wavefolding composed with a sinusoid.
    public func sinefold(_ args: PatternValue) -> Pattern { _distortWith("sinefold", args) }
    /// Distortion via Chebyshev polynomials.
    public func chebyshev(_ args: PatternValue) -> Pattern { _distortWith("chebyshev", args) }
    /// S-curve waveshaping (the default `distort` algorithm).
    public func scurve(_ args: PatternValue) -> Pattern { _distortWith("scurve", args) }
}

public func soft(_ args: PatternValue) -> Pattern { pure(.map([:])).soft(args) }
public func hard(_ args: PatternValue) -> Pattern { pure(.map([:])).hard(args) }
public func cubic(_ args: PatternValue) -> Pattern { pure(.map([:])).cubic(args) }
public func diode(_ args: PatternValue) -> Pattern { pure(.map([:])).diode(args) }
public func asym(_ args: PatternValue) -> Pattern { pure(.map([:])).asym(args) }
public func fold(_ args: PatternValue) -> Pattern { pure(.map([:])).fold(args) }
public func sinefold(_ args: PatternValue) -> Pattern { pure(.map([:])).sinefold(args) }
public func chebyshev(_ args: PatternValue) -> Pattern { pure(.map([:])).chebyshev(args) }
public func scurve(_ args: PatternValue) -> Pattern { pure(.map([:])).scurve(args) }
