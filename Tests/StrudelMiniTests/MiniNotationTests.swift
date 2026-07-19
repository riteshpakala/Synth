// MiniNotationTests.swift — expectations captured from running the actual
// JS strudel mini parser (packages/mini) under node. AGPL-3.0-or-later.

import XCTest
@testable import StrudelMini
@testable import StrudelCore

/// Renders haps the same way as the JS probe: begin-end:value, ~ for no whole.
func probe(_ pat: StrudelCore.Pattern, cycles: Int = 1) -> String {
    let haps = pat.queryArc(Fraction(0), Fraction(cycles))
    return haps.map { h in
        let cont = h.whole == nil ? "~" : ""
        return "\(cont)\(h.part.begin.show())-\(h.part.end.show()):\(h.value)"
    }.joined(separator: " ")
}

func probeSorted(_ pat: StrudelCore.Pattern, cycles: Int = 1) -> [String] {
    let haps = pat.queryArc(Fraction(0), Fraction(cycles))
    return haps.map { h in
        "\(h.part.begin.show())-\(h.part.end.show()):\(h.value)"
    }.sorted()
}

final class MiniNotationTests: XCTestCase {
    func p(_ s: String) -> StrudelCore.Pattern {
        try! mini(s)
    }

    func testSimpleSequence() {
        XCTAssertEqual(probe(p("a b c")),
                       "0/1-1/3:a 1/3-2/3:b 2/3-1/1:c")
    }

    func testRest() {
        XCTAssertEqual(probe(p("a ~ b")),
                       "0/1-1/3:a 2/3-1/1:b")
    }

    func testSubCycle() {
        XCTAssertEqual(probe(p("a [b c]")),
                       "0/1-1/2:a 1/2-3/4:b 3/4-1/1:c")
    }

    func testWeight() {
        // JS: "a b@2" -> 0/1-1/3:"a" 1/3-1/1:"b"
        XCTAssertEqual(probe(p("a b@2")), "0/1-1/3:a 1/3-1/1:b")
    }

    func testElongate() {
        XCTAssertEqual(probe(p("a _ b")), "0/1-2/3:a 2/3-1/1:b")
    }

    func testReplicate() {
        // JS: "a!3 b" -> quarters
        XCTAssertEqual(probe(p("a!3 b")),
                       "0/1-1/4:a 1/4-1/2:a 1/2-3/4:a 3/4-1/1:b")
    }

    func testDotGroups() {
        // JS: "a . b c . d" -> 0-1/3:a 1/3-1/2:b 1/2-2/3:c 2/3-1:d
        XCTAssertEqual(probe(p("a . b c . d")),
                       "0/1-1/3:a 1/3-1/2:b 1/2-2/3:c 2/3-1/1:d")
    }

    func testSlowSequence() {
        let pat = p("<a b>")
        XCTAssertEqual(probe(pat), "0/1-1/1:a")
        let second = pat.queryArc(Fraction(1), Fraction(2))
        XCTAssertEqual(second[0].value, .string("b"))
    }

    func testPolymeter() {
        // JS: "{a b c, d e}%4"
        XCTAssertEqual(probeSorted(p("{a b c, d e}%4")),
                       ["0/1-1/4:a", "0/1-1/4:d", "1/4-1/2:b", "1/4-1/2:e",
                        "1/2-3/4:c", "1/2-3/4:d", "3/4-1/1:a", "3/4-1/1:e"].sorted())
    }

    func testEuclid() {
        // JS: "a(3,8)" -> 0-1/8, 3/8-1/2, 3/4-7/8
        XCTAssertEqual(probe(p("a(3,8)")),
                       "0/1-1/8:a 3/8-1/2:a 3/4-7/8:a")
    }

    func testEuclidWithRotation() {
        let onsets = p("a(3,8,2)").firstCycle().filter { $0.hasOnset() }
        XCTAssertEqual(onsets.count, 3)
    }

    func testTail() {
        // JS: "a:3 b:2" -> lists
        XCTAssertEqual(probe(p("a:3 b:2")),
                       "0/1-1/2:[a, 3] 1/2-1/1:[b, 2]")
    }

    func testRange() {
        // JS: "0 .. 3" -> quarters
        XCTAssertEqual(probe(p("0 .. 3")),
                       "0/1-1/4:0 1/4-1/2:1 1/2-3/4:2 3/4-1/1:3")
    }

    func testFastSlow() {
        // JS: "a*2 b/2" -> 0-1/4:a 1/4-1/2:a 1/2-1:b
        XCTAssertEqual(probe(p("a*2 b/2")),
                       "0/1-1/4:a 1/4-1/2:a 1/2-1/1:b")
    }

    func testStack() {
        XCTAssertEqual(probeSorted(p("a, b c")),
                       ["0/1-1/1:a", "0/1-1/2:b", "1/2-1/1:c"].sorted())
    }

    func testDegradeDeterministic() {
        // JS: "a b?" -> only "a" in first cycle (seed 0)
        XCTAssertEqual(probe(p("a b?")), "0/1-1/2:a")
        // JS: "bd hh?0.7" -> only "bd"
        XCTAssertEqual(probe(p("bd hh?0.7")), "0/1-1/2:bd")
    }

    func testChoose() {
        // "a | b" picks one per cycle deterministically; over 8 cycles both appear
        let pat = p("a | b")
        var seen = Set<String>()
        for c in 0..<8 {
            let haps = pat.queryArc(Fraction(c), Fraction(c + 1))
            XCTAssertEqual(haps.count, 1)
            if case .string(let s) = haps[0].value { seen.insert(s) }
        }
        XCTAssertEqual(seen, Set(["a", "b"]))
    }

    func testNumbers() {
        XCTAssertEqual(probe(p("1 -2 3.5")),
                       "0/1-1/3:1 1/3-2/3:-2 2/3-1/1:3.5")
    }

    func testNoteNamesWithSharp() {
        XCTAssertEqual(probe(p("c#4 eb3")),
                       "0/1-1/2:c#4 1/2-1/1:eb3")
    }

    func testNestedSubCyclesWithOps() {
        // "[a b]*2" == "a b a b" (hap order differs; sets match)
        XCTAssertEqual(probeSorted(p("[a b]*2")),
                       probeSorted(p("a b a b")))
    }

    func testStringsAsMiniViaReify() {
        installMiniNotation()
        defer { StrudelRuntime.stringParser = nil }
        let pat = reify(.string("a b"))
        XCTAssertEqual(probe(pat), "0/1-1/2:a 1/2-1/1:b")
    }
}
