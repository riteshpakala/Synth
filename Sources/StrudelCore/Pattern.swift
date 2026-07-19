// Pattern.swift — the core pattern representation.
// Ported from Strudel <https://codeberg.org/uzu/strudel> (packages/core/pattern.mjs)
// — AGPL-3.0-or-later.
//
// A pattern is a function from a `State` (query timespan + controls) to an
// array of `Hap`s. Patterns are immutable: transformations wrap the query
// function of the original pattern.

import Foundation

/// Global engine settings (mirrors module-level state in pattern.mjs).
public enum StrudelRuntime {
    /// When set (by StrudelMini), all strings reified into patterns are parsed
    /// as mini-notation.
    nonisolated(unsafe) public static var stringParser: ((String) -> Pattern)?
    /// Mirrors `__steps` — whether `_steps` bookkeeping is maintained.
    nonisolated(unsafe) public static var stepsEnabled = true
}

public final class Pattern: @unchecked Sendable {
    /// Maps a `State` to an array of `Hap`s.
    public let query: (State) -> [Hap]
    /// Number of metrical steps per cycle, when known.
    public internal(set) var steps: Fraction?
    /// Set when this pattern is a `pure(value)` — used by the register
    /// machinery to fast-path plain arguments.
    internal var pureValue: PatternValue?
    /// Weight sum hint used by mini-notation polymeters (JS `__weight`).
    public var weightHint: Fraction?
    /// Whether this pattern's steps came from an explicit `^` marker
    /// in mini-notation (JS `__steps_source`).
    public var stepsSource: Bool = false

    public init(_ query: @escaping (State) -> [Hap], steps: Fraction? = nil) {
        self.query = query
        self.steps = steps
    }

    @discardableResult
    public func setSteps(_ steps: Fraction?) -> Pattern {
        self.steps = steps
        return self
    }

    public func withSteps(_ f: (Fraction) -> Fraction) -> Pattern {
        guard StrudelRuntime.stepsEnabled else { return self }
        let result = Pattern(query, steps: steps.map(f))
        result.pureValue = pureValue
        return result
    }

    public var hasSteps: Bool { steps != nil }

    // MARK: - Functor

    /// Returns a new pattern with the function applied to each hap's value.
    public func withValue(_ f: @escaping (PatternValue) -> PatternValue) -> Pattern {
        let result = Pattern { state in self.query(state).map { $0.withValue(f) } }
        result.steps = steps
        return result
    }

    /// See `withValue`.
    public func fmap(_ f: @escaping (PatternValue) -> PatternValue) -> Pattern {
        withValue(f)
    }

    /// Runs a function on the query state before querying.
    public func withState(_ f: @escaping (State) -> State) -> Pattern {
        Pattern { state in self.query(f(state)) }
    }

    // MARK: - Applicative

    /// Assumes `self` is a pattern of functions; applies the given pattern of
    /// values to it, using `wholeFunc` to resolve the combined wholes.
    public func appWhole(
        _ wholeFunc: @escaping (TimeSpan?, TimeSpan?) -> TimeSpan?,
        _ patVal: Pattern
    ) -> Pattern {
        let patFunc = self
        return Pattern { state in
            let hapFuncs = patFunc.query(state)
            let hapVals = patVal.query(state)
            var haps: [Hap] = []
            for hapFunc in hapFuncs {
                guard let fn = hapFunc.value.functionValue else { continue }
                for hapVal in hapVals {
                    guard let s = hapFunc.part.intersection(hapVal.part) else { continue }
                    haps.append(Hap(
                        whole: wholeFunc(hapFunc.whole, hapVal.whole),
                        part: s,
                        value: fn(hapVal.value),
                        context: hapVal.combineContext(hapFunc)
                    ))
                }
            }
            return haps
        }
    }

    /// Tidal's `<*>`: parts and wholes are the intersections of both sides.
    public func appBoth(_ patVal: Pattern) -> Pattern {
        let result = appWhole({ a, b in
            guard let a, let b else { return nil }
            return a.intersectionE(b)
        }, patVal)
        if StrudelRuntime.stepsEnabled {
            result.steps = lcm(patVal.steps, steps)
        }
        return result
    }

    /// Structure comes from the left (this pattern of functions).
    public func appLeft(_ patVal: Pattern) -> Pattern {
        let patFunc = self
        let result = Pattern { state in
            var haps: [Hap] = []
            for hapFunc in patFunc.query(state) {
                guard let fn = hapFunc.value.functionValue else { continue }
                let hapVals = patVal.query(state.setSpan(hapFunc.wholeOrPart()))
                for hapVal in hapVals {
                    guard let newPart = hapFunc.part.intersection(hapVal.part) else { continue }
                    haps.append(Hap(
                        whole: hapFunc.whole,
                        part: newPart,
                        value: fn(hapVal.value),
                        context: hapVal.combineContext(hapFunc)
                    ))
                }
            }
            return haps
        }
        result.steps = steps
        return result
    }

    /// Structure comes from the right (the pattern of values).
    public func appRight(_ patVal: Pattern) -> Pattern {
        let patFunc = self
        let result = Pattern { state in
            var haps: [Hap] = []
            for hapVal in patVal.query(state) {
                let hapFuncs = patFunc.query(state.setSpan(hapVal.wholeOrPart()))
                for hapFunc in hapFuncs {
                    guard let fn = hapFunc.value.functionValue else { continue }
                    guard let newPart = hapFunc.part.intersection(hapVal.part) else { continue }
                    haps.append(Hap(
                        whole: hapVal.whole,
                        part: newPart,
                        value: fn(hapVal.value),
                        context: hapVal.combineContext(hapFunc)
                    ))
                }
            }
            return haps
        }
        result.steps = patVal.steps
        return result
    }

    // MARK: - Monad

    public func bindWhole(
        _ chooseWhole: @escaping (TimeSpan?, TimeSpan?) -> TimeSpan?,
        _ f: @escaping (PatternValue) -> Pattern
    ) -> Pattern {
        let patVal = self
        return Pattern { state in
            var haps: [Hap] = []
            for a in patVal.query(state) {
                let inner = f(a.value).query(state.setSpan(a.part))
                for b in inner {
                    haps.append(Hap(
                        whole: chooseWhole(a.whole, b.whole),
                        part: b.part,
                        value: b.value,
                        context: a.context.merging(b.context)
                    ))
                }
            }
            return haps
        }
    }

    public func bind(_ f: @escaping (PatternValue) -> Pattern) -> Pattern {
        bindWhole({ a, b in
            guard let a, let b else { return nil }
            return a.intersectionE(b)
        }, f)
    }

    /// Flattens a pattern of patterns; wholes are the intersection of inner and outer.
    public func join() -> Pattern {
        bind { $0.patternValue ?? pure($0) }
    }

    public func outerBind(_ f: @escaping (PatternValue) -> Pattern) -> Pattern {
        bindWhole({ a, _ in a }, f).setSteps(steps)
    }

    /// Flattens a pattern of patterns; wholes are taken from the outer haps.
    public func outerJoin() -> Pattern {
        outerBind { $0.patternValue ?? pure($0) }
    }

    public func innerBind(_ f: @escaping (PatternValue) -> Pattern) -> Pattern {
        bindWhole({ _, b in b }, f)
    }

    /// Flattens a pattern of patterns; wholes are taken from the inner haps.
    public func innerJoin() -> Pattern {
        innerBind { $0.patternValue ?? pure($0) }
    }

    /// Flattens patterns of patterns by retriggering/resetting inner patterns
    /// at onsets of the outer pattern's haps.
    /// reset = align the inner pattern's cycle start to outer haps;
    /// restart = align the inner pattern's cycle zero to outer haps.
    public func resetJoin(restart: Bool = false) -> Pattern {
        let patOfPats = self
        return Pattern { state in
            var haps: [Hap] = []
            for outerHap in patOfPats.discreteOnly().query(state) {
                guard let outerWhole = outerHap.whole,
                      let innerPat = outerHap.value.patternValue else { continue }
                let shifted = innerPat._late(restart ? outerWhole.begin : outerWhole.begin.cyclePos())
                for innerHap in shifted.query(state) {
                    // Supports continuous haps in the inner pattern.
                    let whole = innerHap.whole.flatMap { $0.intersection(outerWhole) }
                    if innerHap.whole != nil && whole == nil { continue }
                    guard let part = innerHap.part.intersection(outerHap.part) else { continue }
                    haps.append(Hap(
                        whole: innerHap.whole == nil ? nil : whole,
                        part: part,
                        value: innerHap.value,
                        context: outerHap.combineContext(innerHap)
                    ))
                }
            }
            return haps
        }
    }

    public func restartJoin() -> Pattern {
        resetJoin(restart: true)
    }

    /// Joins by fitting whole cycles of the inner pattern into each event of
    /// the outer pattern.
    public func squeezeJoin() -> Pattern {
        let patOfPats = self
        return Pattern { state in
            let haps = patOfPats.discreteOnly().query(state)
            var out: [Hap] = []
            for outerHap in haps {
                guard let innerRaw = outerHap.value.patternValue else { continue }
                // Slow/shift the inner pattern so the outer whole corresponds
                // to the inner pattern's first cycle.
                let innerPat = innerRaw._focusSpan(outerHap.wholeOrPart())
                let innerHaps = innerPat.query(state.setSpan(outerHap.part))
                for inner in innerHaps {
                    var whole: TimeSpan? = nil
                    if let iw = inner.whole, let ow = outerHap.whole {
                        whole = iw.intersection(ow)
                        if whole == nil { continue } // wholes present but don't intersect
                    }
                    guard let part = inner.part.intersection(outerHap.part) else { continue }
                    out.append(Hap(
                        whole: whole,
                        part: part,
                        value: inner.value,
                        context: inner.combineContext(outerHap)
                    ))
                }
            }
            return out
        }
    }

    public func squeezeBind(_ f: @escaping (PatternValue) -> Pattern) -> Pattern {
        fmap { .pattern(f($0)) }.squeezeJoin()
    }

    public func polyJoin() -> Pattern {
        let pp = self
        let outerSteps = pp.steps ?? .one
        return pp.fmap { v in
            guard let p = v.patternValue else { return v }
            let innerSteps = p.steps ?? .one
            return .pattern(p._extend(outerSteps.div(innerSteps)))
        }.outerJoin()
    }

    public func polyBind(_ f: @escaping (PatternValue) -> Pattern) -> Pattern {
        fmap { .pattern(f($0)) }.polyJoin()
    }

    // MARK: - Querying utilities

    /// Query haps inside the given time span.
    public func queryArc(_ begin: Fraction, _ end: Fraction, controls: ControlMap = [:]) -> [Hap] {
        query(State(span: TimeSpan(begin, end), controls: controls))
    }

    public func queryArc(_ begin: Double, _ end: Double, controls: ControlMap = [:]) -> [Hap] {
        queryArc(Fraction(begin), Fraction(end), controls: controls)
    }

    /// Splits queries at cycle boundaries, so all haps are constrained to
    /// happen within one cycle.
    public func splitQueries() -> Pattern {
        Pattern { state in
            state.span.spanCycles.flatMap { subspan in
                self.query(state.setSpan(subspan))
            }
        }
    }

    /// Applies a function to the query timespan before querying.
    public func withQuerySpan(_ f: @escaping (TimeSpan) -> TimeSpan) -> Pattern {
        Pattern { state in self.query(state.withSpan(f)) }
    }

    public func withQuerySpanMaybe(_ f: @escaping (TimeSpan) -> TimeSpan?) -> Pattern {
        Pattern { state in
            guard let newSpan = f(state.span) else { return [] }
            return self.query(state.setSpan(newSpan))
        }
    }

    /// As `withQuerySpan`, applied to both begin and end.
    public func withQueryTime(_ f: @escaping (Fraction) -> Fraction) -> Pattern {
        Pattern { state in self.query(state.withSpan { $0.withTime(f) }) }
    }

    /// Applies a function to the timespans of all returned haps.
    public func withHapSpan(_ f: @escaping (TimeSpan) -> TimeSpan) -> Pattern {
        Pattern { state in self.query(state).map { $0.withSpan(f) } }
    }

    public func withHapTime(_ f: @escaping (Fraction) -> Fraction) -> Pattern {
        withHapSpan { $0.withTime(f) }
    }

    /// Applies a function to the list of haps returned by every query.
    public func withHaps(_ f: @escaping ([Hap], State) -> [Hap]) -> Pattern {
        let result = Pattern { state in f(self.query(state), state) }
        result.steps = steps
        return result
    }

    public func withHap(_ f: @escaping (Hap) -> Hap) -> Pattern {
        withHaps { haps, _ in haps.map(f) }
    }

    // MARK: - Context

    public func setContext(_ context: HapContext) -> Pattern {
        withHap { $0.setContext(context) }
    }

    public func withContext(_ f: @escaping (HapContext) -> HapContext) -> Pattern {
        let result = withHap { $0.setContext(f($0.context)) }
        result.pureValue = pureValue
        return result
    }

    public func stripContext() -> Pattern {
        withHap { $0.setContext(HapContext()) }
    }

    /// Attaches a trigger callback to every hap; `dominant` disables the
    /// default audio output for these haps.
    public func onTrigger(_ trigger: @escaping HapTrigger, dominant: Bool = true) -> Pattern {
        withHap { hap in
            let previous = hap.context.onTrigger
            var ctx = hap.context
            ctx.onTrigger = { h, deadline, duration, cps, targetTime in
                previous?(h, deadline, duration, cps, targetTime)
                trigger(h, deadline, duration, cps, targetTime)
            }
            // When using multiple triggers, the flag can't flip back to false.
            ctx.dominantTrigger = (hap.context.dominantTrigger ?? false) || dominant
            return hap.setContext(ctx)
        }
    }

    /// Prints each triggered hap (CLI-friendly stand-in for the REPL logger).
    public func log(_ f: @escaping (Hap) -> String = { "[hap] \($0.show(compact: true))" }) -> Pattern {
        onTrigger({ hap, _, _, _, _ in print(f(hap)) }, dominant: false)
    }

    // MARK: - Filtering

    public func filterHaps(_ test: @escaping (Hap) -> Bool) -> Pattern {
        Pattern { state in self.query(state).filter(test) }
    }

    public func filterValues(_ test: @escaping (PatternValue) -> Bool) -> Pattern {
        Pattern { state in
            self.query(state).filter { test($0.value) }
        }.setSteps(steps)
    }

    public func removeUndefineds() -> Pattern {
        filterValues { !$0.isNull }
    }

    /// Only haps that include their onset.
    public func onsetsOnly() -> Pattern {
        filterHaps { $0.hasOnset() }
    }

    /// Removes continuous haps (those without a `whole`).
    public func discreteOnly() -> Pattern {
        filterHaps { $0.whole != nil }
    }

    /// Combines adjacent haps with the same value and whole. For tests.
    public func defragmentHaps() -> Pattern {
        discreteOnly().withHaps { queried, _ in
            var haps = queried
            var result: [Hap] = []
            var i = 0
            while i < haps.count {
                var a = haps[i]
                var searching = true
                while searching {
                    var found = false
                    var j = i + 1
                    while j < haps.count {
                        let b = haps[j]
                        if let aw = a.whole, let bw = b.whole, aw == bw {
                            if a.part.begin == b.part.end, a.value == b.value {
                                a = Hap(whole: aw, part: TimeSpan(b.part.begin, a.part.end), value: a.value)
                                haps.remove(at: j)
                                found = true
                                break
                            } else if b.part.begin == a.part.end, a.value == b.value {
                                a = Hap(whole: aw, part: TimeSpan(a.part.begin, b.part.end), value: a.value)
                                haps.remove(at: j)
                                found = true
                                break
                            }
                        }
                        j += 1
                    }
                    searching = found
                }
                result.append(a)
                i += 1
            }
            return result
        }
    }

    /// Queries the pattern for the first cycle. Mainly for debugging/tests.
    public func firstCycle(withContext: Bool = false) -> [Hap] {
        let target = withContext ? self : stripContext()
        return target.query(State(span: TimeSpan(.zero, .one)))
    }

    public var firstCycleValues: [PatternValue] {
        firstCycle().map(\.value)
    }

    /// Haps sorted in temporal order; for comparing patterns in tests.
    public func sortHapsByPart() -> Pattern {
        withHaps { haps, _ in
            haps.sorted { a, b in
                if a.part.begin != b.part.begin { return a.part.begin < b.part.begin }
                if a.part.end != b.part.end { return a.part.end < b.part.end }
                let aw = a.whole ?? a.part
                let bw = b.whole ?? b.part
                if aw.begin != bw.begin { return aw.begin < bw.begin }
                return aw.end < bw.end
            }
        }
    }

    /// Values parsed as numerals (note names become midi numbers).
    public func asNumber() -> Pattern {
        fmap { v in parseNumeral(v).map { .number($0) } ?? .null }
    }

    // MARK: - Multi-pattern methods

    /// Layers the results of the given functions (without the original).
    public func layer(_ funcs: ((Pattern) -> Pattern)...) -> Pattern {
        StrudelCore.stack(funcs.map { .pattern($0(self)) })
    }

    /// Superimposes the results of the given functions on the original.
    public func superimpose(_ funcs: ((Pattern) -> Pattern)...) -> Pattern {
        var pats: [PatternValue] = [.pattern(self)]
        pats.append(contentsOf: funcs.map { .pattern($0(self)) })
        return StrudelCore.stack(pats)
    }

    public func stack(_ pats: PatternValue...) -> Pattern {
        StrudelCore.stack([.pattern(self)] + pats)
    }

    public func seq(_ pats: PatternValue...) -> Pattern {
        StrudelCore.fastcat([.pattern(self)] + pats)
    }

    public func cat(_ pats: PatternValue...) -> Pattern {
        StrudelCore.slowcat([.pattern(self)] + pats)
    }

    // MARK: - Chords / collect

    /// Groups congruent haps (equal spans) into haps of lists.
    public func collect() -> Pattern {
        withHaps { haps, _ in
            var groups: [[Hap]] = []
            for hap in haps {
                if let idx = groups.firstIndex(where: { $0[0].spanEquals(hap) }) {
                    groups[idx].append(hap)
                } else {
                    groups.append([hap])
                }
            }
            return groups.map { group in
                Hap(whole: group[0].whole, part: group[0].part,
                    value: .list(group.map(\.value)))
            }
        }
    }
}
