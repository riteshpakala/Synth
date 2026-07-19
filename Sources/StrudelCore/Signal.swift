// Signal.swift — continuous patterns and randomness.
// Ported from Strudel <https://codeberg.org/uzu/strudel> (packages/core/signal.mjs)
// — AGPL-3.0-or-later.
//
// The RNGs are ported bit-for-bit (32-bit integer semantics included) so
// random patterns produce identical values to strudel.cc.

import Foundation

// MARK: - Elemental signals

/// A continuous (whole-less) value.
public func steady(_ value: PatternValue) -> Pattern {
    Pattern { state in [Hap(whole: nil, part: state.span, value: value)] }
}

/// A continuous signal sampled at the query span's begin.
public func signal(_ f: @escaping (Fraction, ControlMap) -> PatternValue) -> Pattern {
    Pattern { state in
        [Hap(whole: nil, part: state.span, value: f(state.span.begin, state.controls))]
    }
}

public func signal(_ f: @escaping (Double) -> Double) -> Pattern {
    signal { t, _ in .number(f(t.doubleValue)) }
}

/// A sawtooth signal between 0 and 1.
public let saw = signal { t in _mod(t, 1) }
public let saw2 = saw.toBipolar()
/// Inverted saw, between 1 and 0.
public let isaw = signal { t in 1 - _mod(t, 1) }
public let isaw2 = isaw.toBipolar()
/// A sine signal between -1 and 1.
public let sine2 = signal { t in Foundation.sin(.pi * 2 * t) }
/// A sine signal between 0 and 1.
public let sine = sine2.fromBipolar()
/// A cosine signal between 0 and 1.
public let cosine = sine._early(Fraction(1, 4))
public let cosine2 = sine2._early(Fraction(1, 4))
/// A square signal between 0 and 1.
public let square = signal { t in (t * 2).truncatingRemainder(dividingBy: 2).rounded(.down) }
public let square2 = square.toBipolar()
/// A triangle signal between 0 and 1.
public let tri = fastcat(.pattern(saw), .pattern(isaw))
public let tri2 = fastcat(.pattern(saw2), .pattern(isaw2))
/// Inverted triangle.
public let itri = fastcat(.pattern(isaw), .pattern(saw))
public let itri2 = fastcat(.pattern(isaw2), .pattern(saw2))
/// The cycle time itself.
public let time = signal { t, _ in .fraction(t) }

/// Event-duration signals.
public let cyclesPer = Pattern { state in
    [Hap(whole: nil, part: state.span, value: .fraction(state.span.duration))]
}
public let per = Pattern { state in
    [Hap(whole: nil, part: state.span, value: .fraction(Fraction.one.div(state.span.duration)))]
}
public let perCycle = per
public let perx = Pattern { state in
    let n = Fraction.one.div(state.span.duration).doubleValue
    return [Hap(whole: nil, part: state.span, value: .number(Foundation.log(n) / Foundation.log(2) + 1))]
}

// MARK: - Random number generation

public enum RNGMode: String, Sendable {
    case legacy, precise
}

nonisolated(unsafe) private var rngMode: RNGMode = .legacy

/// Sets which RNG to use ('legacy' is the historical default).
public func useRNG(_ mode: RNGMode) {
    rngMode = mode
}

// New "precise" RNG: murmur-style hash with avalanche effect.
private func murmurHashFinalizer(_ input: UInt32) -> UInt32 {
    var x = input
    x ^= x >> 16
    x = x &* 0x85eb_ca6b
    x ^= x >> 13
    x = x &* 0xc2b2_ae35
    x ^= x >> 16
    return x
}

private func tToT(_ t: Double) -> Double {
    (t * 536_870_912).rounded(.down)
}

private func decorrelate(_ T: Double, _ i: UInt32, _ seed: UInt32) -> UInt32 {
    let lowBits = UInt32(truncatingIfNeeded: Int64(T.truncatingRemainder(dividingBy: 4_294_967_296)))
    let highBits = UInt32(truncatingIfNeeded: Int64((T / 4_294_967_296).rounded(.down)))
    var key = lowBits ^ ((highBits ^ 0x85eb_ca6b) &* 0xc2b2_ae35)
    key ^= (i ^ 0x7f4a_7c15) &* 0x9e37_79b9
    key ^= (seed ^ 0x1656_67b1) &* 0x27d4_eb2d
    return key
}

private func randAt(_ T: Double, _ i: UInt32, _ seed: UInt32) -> Double {
    Double(murmurHashFinalizer(decorrelate(T, i, seed))) / 4_294_967_296
}

private func timeToRands(_ t: Double, _ n: Int, _ seed: UInt32) -> [Double] {
    let T = tToT(t)
    return (0..<n).map { randAt(T, UInt32($0), seed) }
}

// Legacy RNG: xorshift over time scaled to 2^29, repeating every 300 cycles.
// All shifts operate on 32-bit signed integers, exactly like JS.
private func xorwise(_ x: Int32) -> Int32 {
    let a = (x << 13) ^ x
    let b = (a >> 17) ^ a
    return (b << 5) ^ b
}

private func frac(_ x: Double) -> Double {
    x - x.rounded(.towardZero)
}

private func timeToIntSeed(_ x: Double) -> Int32 {
    let scaled = frac(x / 300) * 536_870_912
    return xorwise(Int32(truncatingIfNeeded: Int64(scaled.rounded(.towardZero))))
}

private func intSeedToRand(_ x: Int32) -> Double {
    Double(x % 536_870_912) / 536_870_912
}

private func legacyTimeToRands(_ t: Double, _ n: Int) -> [Double] {
    var seed = timeToIntSeed(t)
    if n == 1 {
        return [Swift.abs(intSeedToRand(seed))]
    }
    var result: [Double] = []
    for _ in 0..<n {
        result.append(intSeedToRand(seed))
        seed = xorwise(seed)
    }
    return result
}

/// Random values at a given time — the engine's only source of randomness.
public func getRandsAtTime(_ t: Double, _ n: Int = 1, seed: Double = 0) -> [Double] {
    if rngMode == .legacy {
        return legacyTimeToRands(t + seed, n)
    }
    return timeToRands(t, n, UInt32(truncatingIfNeeded: Int64(seed)))
}

private func randSeed(_ controls: ControlMap) -> Double {
    controls["randSeed"]?.doubleValue ?? 0
}

/// A continuous pattern of random numbers between 0 and 1.
public let rand = signal { t, controls in
    .number(getRandsAtTime(t.doubleValue, 1, seed: randSeed(controls))[0])
}

/// Random numbers between -1 and 1.
public let rand2 = rand.toBipolar()

func _brandBy(_ p: Double) -> Pattern {
    rand.fmap { x in .bool((x.doubleValue ?? 0) < p) }
}

/// Binary random with the given probability of being 1.
public func brandBy(_ pPat: PatternValue) -> Pattern {
    reify(pPat).fmap { p in .pattern(_brandBy(p.doubleValue ?? 0.5)) }.innerJoin()
}

/// Binary random (50/50).
public let brand = _brandBy(0.5)

func _irand(_ i: Double) -> Pattern {
    rand.fmap { x in .number(((x.doubleValue ?? 0) * i).rounded(.towardZero)) }
}

/// Random integers between 0 and n-1.
public func irand(_ ipat: PatternValue) -> Pattern {
    reify(ipat).fmap { i in .pattern(_irand(i.doubleValue ?? 1)) }.innerJoin()
}

// MARK: - Perlin & berlin noise

func _perlinAt(_ t: Double, seed: Double) -> Double {
    let ta = t.rounded(.down)
    let tb = ta + 1
    func smootherStep(_ x: Double) -> Double {
        6 * Foundation.pow(x, 5) - 15 * Foundation.pow(x, 4) + 10 * Foundation.pow(x, 3)
    }
    let ra = getRandsAtTime(ta, 1, seed: seed)[0]
    let rb = getRandsAtTime(tb, 1, seed: seed)[0]
    return ra + smootherStep(t - ta) * (rb - ra)
}

/// Continuous perlin noise in the range 0..1.
public let perlin = signal { t, controls in
    .number(_perlinAt(t.doubleValue, seed: randSeed(controls)))
}

/// Sawtooth-flavored perlin variant.
public let berlin = signal { t, controls in
    let time = t.doubleValue
    let seed = randSeed(controls)
    let prev = time.rounded(.down)
    let next = prev + 1
    let bottom = getRandsAtTime(prev, 1, seed: seed)[0]
    let height = getRandsAtTime(next, 1, seed: seed)[0]
    let top = bottom + height
    let percent = (time - prev) / (next - prev)
    return .number((bottom + percent * (top - bottom)) / 2)
}

// MARK: - Runs and binary patterns

/// A discrete pattern of numbers from 0 to n-1.
public func run(_ n: PatternValue) -> Pattern {
    saw.range(0, n).round().segment(n)
}

/// Creates a binary pattern from a number.
public func binary(_ n: PatternValue) -> Pattern {
    let nBits = reify(n).log2().floor().add(1)
    return binaryN(n, .pattern(nBits))
}

/// Binary pattern from a number, padded to nBits.
public func binaryN(_ n: PatternValue, _ nBits: PatternValue = 16) -> Pattern {
    let bits = reify(nBits)
    let bitPos = run(.pattern(bits)).mul(-1).add(.pattern(bits.sub(1)))
    return reify(n).segment(.pattern(bits)).brshift(.pattern(bitPos)).band(1)
}

/// Binary list pattern from a number.
public func binaryNL(_ n: PatternValue, _ nBits: PatternValue = 16) -> Pattern {
    reify(n).fmap { v in
        PatternValue.function { bits in
            let count = bits.intValue ?? 16
            let value = v.intValue ?? 0
            var bList: [PatternValue] = []
            var i = count - 1
            while i >= 0 {
                bList.append(.number(Double((value >> i) & 1)))
                i -= 1
            }
            return .list(bList)
        }
    }.appLeft(reify(nBits))
}

public func binaryL(_ n: PatternValue) -> Pattern {
    binaryNL(n, .pattern(reify(n).log2().floor().add(1)))
}

/// A list of random numbers of the given length.
public func randL(_ n: PatternValue) -> Pattern {
    signal { t, _ in
        PatternValue.function { nVal in
            .list(getRandsAtTime(t.doubleValue, nVal.intValue ?? 1).map { .number(Swift.abs($0)) })
        }
    }.appLeft(reify(n))
}

/// A random permutation of 0..<n each cycle.
public func randrun(_ n: Int) -> Pattern {
    signal { t, controls in
        guard n > 0 else { return .number(0) }
        // Without adding 0.5, the first cycle would always be 0,1,2,3,…
        let rands = getRandsAtTime(t.floorFraction().doubleValue + 0.5, n, seed: randSeed(controls))
        let nums = rands.enumerated()
            .sorted { $0.element < $1.element }
            .map(\.offset)
        let i = t.cyclePos().mul(Fraction(n)).floorInt % n
        return .number(Double(nums[i]))
    }._segment(Fraction(n))
}

// MARK: - Choosing

func __chooseWith(_ pat: Pattern, _ xs: [PatternValue]) -> Pattern {
    if xs.isEmpty { return silence }
    return pat.range(0, .number(Double(xs.count))).fmap { i in
        let key = Swift.min(Swift.max(Int((i.doubleValue ?? 0).rounded(.down)), 0), xs.count - 1)
        return .pattern(reify(xs[key]))
    }
}

/// Choose from values using a pattern of numbers in 0..1 (structure from chooser).
public func chooseWith(_ pat: Pattern, _ xs: [PatternValue]) -> Pattern {
    __chooseWith(pat, xs).outerJoin()
}

/// As chooseWith, but structure comes from the chosen values.
public func chooseInWith(_ pat: Pattern, _ xs: [PatternValue]) -> Pattern {
    __chooseWith(pat, xs).innerJoin()
}

/// Chooses randomly from the given elements (continuous).
public func choose(_ xs: PatternValue...) -> Pattern {
    chooseWith(rand, xs)
}

public func chooseIn(_ xs: PatternValue...) -> Pattern {
    chooseInWith(rand, xs)
}

/// Picks one of the elements at random each cycle.
public func chooseCycles(_ xs: PatternValue...) -> Pattern {
    chooseInWith(rand._segment(.one), xs)
}

public func randcat(_ xs: PatternValue...) -> Pattern {
    chooseInWith(rand._segment(.one), xs)
}

extension Pattern {
    /// Chooses from the values using this pattern (range 0..1) as the chooser.
    public func choose(_ xs: PatternValue...) -> Pattern {
        chooseWith(self, xs)
    }

    /// As choose, for bipolar (-1..1) choosers.
    public func choose2(_ xs: PatternValue...) -> Pattern {
        chooseWith(fromBipolar(), xs)
    }
}

// MARK: - Weighted choosing

func _wchooseWith(_ pat: Pattern, _ pairs: [(PatternValue, PatternValue)]) -> Pattern {
    let values = pairs.map { reify($0.0) }
    var weights: [Pattern] = []
    var total = pure(.number(0))
    for pair in pairs {
        total = total.add(pair.1)
        weights.append(total)
    }
    let weightspat = sequenceP(weights)
    let match: (PatternValue) -> Pattern = { r in
        let findpat = total.mul(r)
        return weightspat.fmap { weightsVal in
            PatternValue.function { find in
                let list = weightsVal.listValue ?? []
                let target = find.doubleValue ?? 0
                let idx = list.firstIndex { ($0.doubleValue ?? 0) > target } ?? (list.count - 1)
                return idx >= 0 && idx < values.count ? .pattern(values[idx]) : .null
            }
        }.appLeft(findpat)
    }
    return pat.bind(match)
}

/// Chooses randomly with weights: `wchoose(("sine", 10), ("tri", 1))`.
public func wchoose(_ pairs: (PatternValue, PatternValue)...) -> Pattern {
    _wchooseWith(rand, pairs).outerJoin()
}

/// Weighted choose per cycle.
public func wchooseCycles(_ pairs: (PatternValue, PatternValue)...) -> Pattern {
    _wchooseWith(rand._segment(.one), pairs).innerJoin()
}

public func wrandcat(_ pairs: (PatternValue, PatternValue)...) -> Pattern {
    _wchooseWith(rand._segment(.one), pairs).innerJoin()
}

// MARK: - Seeds

/// Applies a function to the randSeed control.
public func withSeed(_ f: @escaping (Double?) -> Double?, _ pat: Pattern) -> Pattern {
    Pattern({ state in
        var controls = state.controls
        let current = controls["randSeed"]?.doubleValue
        if let newSeed = f(current) {
            controls["randSeed"] = .number(newSeed)
        } else {
            controls.removeValue(forKey: "randSeed")
        }
        return pat.query(State(span: state.span, controls: controls))
    }, steps: pat.steps)
}

extension Pattern {
    /// Changes the seed for random signals.
    public func seed(_ n: PatternValue) -> Pattern {
        withSeed({ _ in n.doubleValue }, self)
    }

    // MARK: Shuffle & scramble

    func _rearrangeWith(_ ipat: Pattern, _ n: Int) -> Pattern {
        let pat = self
        let pats = (0..<Swift.max(n, 1)).map { i in
            pat._zoom(Fraction(i).div(Fraction(n)), Fraction(i + 1).div(Fraction(n)))
        }
        return ipat.fmap { i in
            let idx = Swift.min(Swift.max(i.intValue ?? 0, 0), pats.count - 1)
            return .pattern(pats[idx]._repeatCycles(n)._fast(Fraction(n)))
        }.innerJoin()
    }

    /// Plays n slices of the pattern in random order (each exactly once per cycle).
    public func shuffle(_ n: PatternValue) -> Pattern {
        patternify(n) { n, pat in
            let count = n.intValue ?? 1
            return pat._rearrangeWith(randrun(count), count)
        }
    }

    /// Plays n slices at random (may repeat or skip slices).
    public func scramble(_ n: PatternValue) -> Pattern {
        patternify(n) { n, pat in
            let count = n.intValue ?? 1
            return pat._rearrangeWith(_irand(Double(count))._segment(Fraction(count)), count)
        }
    }

    // MARK: Degrade family

    public func degradeByWith(_ withPat: Pattern, _ x: Double) -> Pattern {
        fmap { a in PatternValue.function { _ in a } }
            .appLeft(withPat.filterValues { v in (v.doubleValue ?? 0) > x })
            .setSteps(steps)
    }

    public func _degradeByWith(_ withPat: Pattern, _ x: Double) -> Pattern {
        degradeByWith(withPat, x)
    }

    /// Randomly removes events with the given probability (0..1).
    public func degradeBy(_ x: PatternValue) -> Pattern {
        patternify(x, preserveSteps: true) { x, pat in
            pat._degradeByWith(rand, x.doubleValue ?? 0.5)
        }
    }

    /// Removes 50% of events.
    public func degrade() -> Pattern {
        degradeBy(0.5)
    }

    /// Inverse of degradeBy: keeps exactly the events degradeBy would remove.
    public func undegradeBy(_ x: PatternValue) -> Pattern {
        patternify(x, preserveSteps: true) { x, pat in
            pat._degradeByWith(rand.fmap { r in .number(1 - (r.doubleValue ?? 0)) }, x.doubleValue ?? 0.5)
        }
    }

    public func undegrade() -> Pattern {
        undegradeBy(0.5)
    }

    // MARK: Sometimes family

    /// Randomly applies the function with the given probability.
    public func sometimesBy(_ patx: PatternValue, _ f: @escaping (Pattern) -> Pattern) -> Pattern {
        let pat = self
        return reify(patx).fmap { x -> PatternValue in
            let p = x.doubleValue ?? 0.5
            return .pattern(StrudelCore.stack(
                .pattern(pat._degradeByWith(rand, p)),
                .pattern(f(pat._degradeByWith(rand.fmap { r in .number(1 - (r.doubleValue ?? 0)) }, 1 - p)))
            ))
        }.innerJoin()
    }

    public func sometimes(_ f: @escaping (Pattern) -> Pattern) -> Pattern {
        sometimesBy(0.5, f)
    }

    /// Applies the function on a per-cycle basis with the given probability.
    public func someCyclesBy(_ patx: PatternValue, _ f: @escaping (Pattern) -> Pattern) -> Pattern {
        let pat = self
        return reify(patx).fmap { x -> PatternValue in
            let p = x.doubleValue ?? 0.5
            return .pattern(StrudelCore.stack(
                .pattern(pat._degradeByWith(rand._segment(.one), p)),
                .pattern(f(pat._degradeByWith(
                    rand.fmap { r in .number(1 - (r.doubleValue ?? 0)) }._segment(.one), 1 - p
                )))
            ))
        }.innerJoin()
    }

    public func someCycles(_ f: @escaping (Pattern) -> Pattern) -> Pattern {
        someCyclesBy(0.5, f)
    }

    public func often(_ f: @escaping (Pattern) -> Pattern) -> Pattern {
        sometimesBy(0.75, f)
    }

    public func rarely(_ f: @escaping (Pattern) -> Pattern) -> Pattern {
        sometimesBy(0.25, f)
    }

    public func almostNever(_ f: @escaping (Pattern) -> Pattern) -> Pattern {
        sometimesBy(0.1, f)
    }

    public func almostAlways(_ f: @escaping (Pattern) -> Pattern) -> Pattern {
        sometimesBy(0.9, f)
    }

    public func never(_ f: (Pattern) -> Pattern) -> Pattern {
        self
    }

    public func always(_ f: (Pattern) -> Pattern) -> Pattern {
        f(self)
    }
}
