// PatternCoreTests.swift — ported from strudel's packages/core/test/pattern.test.mjs
// (a representative subset; the differential harness covers the long tail).
// AGPL-3.0-or-later.

import XCTest
@testable import StrudelCore

/// Convenience for comparing hap spans/values.
func hapString(_ hap: Hap) -> String {
    let whole = hap.whole.map { "\($0.begin)→\($0.end)" } ?? "~"
    return "[\(whole) | \(hap.part.begin)→\(hap.part.end) | \(hap.value)]"
}

func firstCycleStrings(_ pat: StrudelCore.Pattern) -> [String] {
    pat.sortHapsByPart().firstCycle().map(hapString)
}

final class FractionTests: XCTestCase {
    func testBasics() {
        XCTAssertEqual(Fraction(1, 2).add(Fraction(1, 3)), Fraction(5, 6))
        XCTAssertEqual(Fraction(0.5), Fraction(1, 2))
        XCTAssertEqual(Fraction(1.0 / 3), Fraction(1, 3))
        XCTAssertEqual(Fraction(-1, 4).sam(), Fraction(-1))
        XCTAssertEqual(Fraction(5, 4).sam(), Fraction(1))
        XCTAssertEqual(Fraction(5, 4).cyclePos(), Fraction(1, 4))
        XCTAssertEqual(Fraction(7, 2).mod(Fraction(2)), Fraction(3, 2))
        XCTAssertEqual(Fraction(-1, 2).mod(Fraction(1)), Fraction(1, 2))
    }

    func testStringParse() {
        XCTAssertEqual(Fraction("1/3"), Fraction(1, 3))
        XCTAssertEqual(Fraction("0.25"), Fraction(1, 4))
        XCTAssertEqual(Fraction("-2"), Fraction(-2))
    }
}

final class PatternCoreTests: XCTestCase {
    func testPureFirstCycle() {
        let haps = pure(.string("a")).firstCycle()
        XCTAssertEqual(haps.count, 1)
        XCTAssertEqual(haps[0].value, .string("a"))
        XCTAssertEqual(haps[0].whole, TimeSpan(.zero, .one))
        XCTAssertEqual(haps[0].part, TimeSpan(.zero, .one))
    }

    func testPureSpansCycles() {
        let haps = pure(.number(1)).queryArc(Fraction(0), Fraction(2))
        XCTAssertEqual(haps.count, 2)
        XCTAssertEqual(haps[1].whole, TimeSpan(.one, Fraction(2)))
    }

    func testFastcat() {
        let pat = fastcat("a", "b", "c")
        let haps = pat.sortHapsByPart().firstCycle()
        XCTAssertEqual(haps.count, 3)
        XCTAssertEqual(haps[0].value, .string("a"))
        XCTAssertEqual(haps[0].whole, TimeSpan(.zero, Fraction(1, 3)))
        XCTAssertEqual(haps[1].value, .string("b"))
        XCTAssertEqual(haps[1].whole, TimeSpan(Fraction(1, 3), Fraction(2, 3)))
        XCTAssertEqual(pat.steps, Fraction(3))
    }

    func testSlowcatCycles() {
        let pat = slowcat("a", "b")
        XCTAssertEqual(pat.firstCycle()[0].value, .string("a"))
        let second = pat.queryArc(Fraction(1), Fraction(2))
        XCTAssertEqual(second[0].value, .string("b"))
        let third = pat.queryArc(Fraction(2), Fraction(3))
        XCTAssertEqual(third[0].value, .string("a"))
    }

    func testStack() {
        let pat = stack("a", "b")
        XCTAssertEqual(pat.firstCycle().count, 2)
    }

    func testFastAndSlow() {
        XCTAssertEqual(pure(.string("x"))._fast(Fraction(4)).firstCycle().count, 4)
        let slowed = fastcat("a", "b")._slow(Fraction(2))
        let haps = slowed.sortHapsByPart().firstCycle()
        XCTAssertEqual(haps.count, 1)
        XCTAssertEqual(haps[0].value, .string("a"))
    }

    func testRev() {
        let pat = fastcat("a", "b", "c").rev()
        let values = pat.sortHapsByPart().firstCycleValues
        XCTAssertEqual(values, [.string("c"), .string("b"), .string("a")])
    }

    func testEarlyLate() {
        let pat = fastcat("a", "b")._late(Fraction(1, 4))
        let haps = pat.sortHapsByPart().firstCycle().filter { $0.hasOnset() }
        XCTAssertEqual(haps[0].whole?.begin, Fraction(1, 4))
    }

    func testAppBothWholeIntersection() {
        // fastcat(0,1).add(fastcat(10)) via appLeft keeps left structure
        let left = fastcat(0, 1)
        let sum = left.add(10)
        let values = sum.sortHapsByPart().firstCycleValues
        XCTAssertEqual(values, [.number(10), .number(11)])
    }

    func testAddMixAlignment() {
        let mixed = fastcat(0, 1).add.mix(.pattern(fastcat(10, 20, 30)))
        let haps = mixed.sortHapsByPart().firstCycle()
        // intersecting parts: [0,1/3)=10, [1/3,1/2)=30? -- values 0+10, 0+20, 1+20, 1+30
        let expected: [PatternValue] = [.number(10), .number(20), .number(21), .number(31)]
        XCTAssertEqual(haps.map { $0.value }, expected)
    }

    func testEveryRev() {
        let pat = fastcat("a", "b").every(2) { $0.rev() }
        // First cycle: reversed
        XCTAssertEqual(pat.sortHapsByPart().firstCycleValues, [.string("b"), .string("a")])
        let second = pat.queryArc(Fraction(1), Fraction(2)).sorted { $0.part.begin < $1.part.begin }
        let expectedSecond: [PatternValue] = [.string("a"), .string("b")]
        XCTAssertEqual(second.map { $0.value }, expectedSecond)
    }

    func testEuclid() {
        let pat = pure(.string("bd")).euclid(3, 8)
        let onsets = pat.sortHapsByPart().firstCycle().filter { $0.hasOnset() }
        XCTAssertEqual(onsets.count, 3)
        let expectedOnsets: [Fraction] = [Fraction(0), Fraction(3, 8), Fraction(6, 8)]
        XCTAssertEqual(onsets.map { $0.whole!.begin }, expectedOnsets)
    }

    func testEuclidLegato() {
        let pat = pure(.string("c3")).euclidLegato(3, 8)
        let onsets = pat.sortHapsByPart().firstCycle().filter { $0.hasOnset() }
        XCTAssertEqual(onsets.count, 3)
        XCTAssertEqual(onsets[0].whole, TimeSpan(.zero, Fraction(3, 8)))
    }

    func testSqueezeJoinPly() {
        let pat = fastcat("a", "b").ply(2)
        let values = pat.sortHapsByPart().firstCycleValues
        XCTAssertEqual(values, [.string("a"), .string("a"), .string("b"), .string("b")])
    }

    func testStructAndMask() {
        let pat = pure(.string("x")).structure(.pattern(fastcat(true, false, true)))
        let onsets = pat.sortHapsByPart().firstCycle().filter { $0.hasOnset() }
        XCTAssertEqual(onsets.count, 2)

        let masked = fastcat("a", "b").mask(.pattern(fastcat(true, false)))
        let values = masked.sortHapsByPart().firstCycle().filter { $0.hasOnset() }.map(\.value)
        XCTAssertEqual(values, [.string("a")])
    }

    func testSegmentAndRange() {
        // Verified against JS strudel: saw samples at span begin.
        let pat = saw.range(0, 8).segment(4)
        let values = pat.sortHapsByPart().firstCycleValues.compactMap(\.doubleValue)
        XCTAssertEqual(values, [0, 2, 4, 6])
    }

    func testIter() {
        let pat = fastcat("a", "b", "c", "d").iter(4)
        let cycle2 = pat.queryArc(Fraction(1), Fraction(2)).sorted { $0.part.begin < $1.part.begin }
        let expectedC2: [PatternValue] = [.string("b"), .string("c"), .string("d"), .string("a")]
        XCTAssertEqual(cycle2.map { $0.value }, expectedC2)
    }

    func testChunk() {
        // chunk operates without error and produces full cycles
        let pat = fastcat(0, 1, 2, 3).chunk(4) { $0.add(10) }
        let values = pat.sortHapsByPart().firstCycleValues.compactMap(\.doubleValue)
        XCTAssertEqual(values, [10, 1, 2, 3])
    }

    func testOff() {
        let pat = pure(.number(0)).off(0.25) { $0.add(2) }
        let onsets = pat.sortHapsByPart().firstCycle().filter { $0.hasOnset() }
        XCTAssertEqual(onsets.count, 2)
        XCTAssertEqual(onsets[1].whole?.begin, Fraction(1, 4))
        XCTAssertEqual(onsets[1].value, .number(2))
    }

    func testStepcat() {
        // stepcat([3,"e3"],[1,"g3"]) == "e3@3 g3"
        let pat = stepcat((Fraction(3), "e3"), (Fraction(1), "g3"))
        let haps = pat.sortHapsByPart().firstCycle()
        XCTAssertEqual(haps.count, 2)
        XCTAssertEqual(haps[0].whole, TimeSpan(.zero, Fraction(3, 4)))
        XCTAssertEqual(haps[1].whole, TimeSpan(Fraction(3, 4), .one))
    }

    func testPolymeter() {
        // {a b c, d e}%3 -> first pattern 3 steps, second repeats to fit
        let pat = polymeter(steps: 3, [.list(["a", "b", "c"]), .list(["d", "e"])])
        let haps = pat.sortHapsByPart().firstCycle()
        XCTAssertEqual(haps.count, 6)
    }

    func testDegradeUndegradeComplementary() {
        let pat = pure(.string("x"))._fast(Fraction(8))
        let degraded = pat.degradeBy(0.5).firstCycle().count
        let undegraded = pat.undegradeBy(0.5).firstCycle().count
        XCTAssertEqual(degraded + undegraded, 8)
    }

    func testRandIsDeterministic() {
        let a = rand.segment(8).firstCycleValues.compactMap(\.doubleValue)
        let b = rand.segment(8).firstCycleValues.compactMap(\.doubleValue)
        XCTAssertEqual(a, b)
        XCTAssertEqual(a.count, 8)
        XCTAssertTrue(a.allSatisfy { $0 >= 0 && $0 < 1 })
        // Bit-exact against JS strudel (legacy RNG):
        let jsValues = [0, 0.6852155700325966, 0.36975969187915325, 0.40139251574873924,
                        0.2604806162416935, 0.1356358677148819, 0.19582648016512394, 0.3976310808211565]
        for (mine, theirs) in Swift.zip(a, jsValues) {
            XCTAssertEqual(mine, theirs, accuracy: 1e-12)
        }
    }

    func testUnionWithMaps() {
        let notes = pure(.map(["note": .number(60)]))
        let gains = pure(.map(["gain": .number(0.5)]))
        let combined = notes.add(.pattern(gains))
        let value = combined.firstCycleValues[0]
        XCTAssertEqual(value.mapValue?["note"], .number(60))
        XCTAssertEqual(value.mapValue?["gain"], .number(0.5))
    }

    func testAddNoteNames() {
        // note names parse to midi under arithmetic: "c3".add(12)
        let sum = pure(.string("c3")).add(12)
        XCTAssertEqual(sum.firstCycleValues[0].doubleValue, noteToMidi("c3") + 12)
    }

    func testCompressAndZoom() {
        let compressed = fastcat("a", "b").compress(0.25, 0.75)
        let onsets = compressed.sortHapsByPart().firstCycle().filter { $0.hasOnset() }
        XCTAssertEqual(onsets.count, 2)
        XCTAssertEqual(onsets[0].whole?.begin, Fraction(1, 4))

        let zoomed = fastcat("a", "b", "c", "d").zoom(0.25, 0.75)
        let zoomValues = zoomed.sortHapsByPart().firstCycleValues
        XCTAssertEqual(zoomValues, [.string("b"), .string("c")])
    }

    func testLinger() {
        let pat = fastcat("a", "b", "c", "d").linger(0.25)
        let values = pat.sortHapsByPart().firstCycleValues
        XCTAssertEqual(values, [.string("a"), .string("a"), .string("a"), .string("a")])
    }

    func testShuffleIsPermutation() {
        let pat = fastcat(0, 1, 2, 3).shuffle(4)
        let values = Set(pat.sortHapsByPart().firstCycleValues.compactMap(\.intValue))
        XCTAssertEqual(values, Set([0, 1, 2, 3]))
    }
}
