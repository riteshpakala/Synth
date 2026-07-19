// ControlsTests.swift — control map semantics, verified against JS behavior.
// AGPL-3.0-or-later.

import XCTest
@testable import StrudelCore

final class ControlsTests: XCTestCase {
    func testBasicControl() {
        let pat = note("c3")
        let v = pat.firstCycleValues[0]
        XCTAssertEqual(v.mapValue?["note"], .string("c3"))
    }

    func testChainedControls() {
        let pat = note(60).s("piano").gain(0.5)
        let v = pat.firstCycleValues[0]
        XCTAssertEqual(v.mapValue?["note"], .number(60))
        XCTAssertEqual(v.mapValue?["s"], .string("piano"))
        XCTAssertEqual(v.mapValue?["gain"], .number(0.5))
    }

    func testMultiNameSplat() {
        // s takes ['s','n','gain'] — "bd:3:0.5" style lists splat across names
        let pat = s(.list(["bd", 3, 0.5]))
        let v = pat.firstCycleValues[0]
        XCTAssertEqual(v.mapValue?["s"], .string("bd"))
        XCTAssertEqual(v.mapValue?["n"], .number(3))
        XCTAssertEqual(v.mapValue?["gain"], .number(0.5))
    }

    func testControlStructureFromLeft() {
        // note("c3 e3").gain("0.5") — structure from note
        let pat = note(.pattern(fastcat("c3", "e3"))).gain(0.5)
        XCTAssertEqual(pat.firstCycle().count, 2)
    }

    func testAliases() {
        XCTAssertEqual(Controls.alias["lpf"], "cutoff")
        XCTAssertEqual(Controls.alias["sound"], "s")
        XCTAssertEqual(Controls.alias["ctf"], "cutoff")
        let pat = pure(.map([:])).lpf(800)
        XCTAssertEqual(pat.firstCycleValues[0].mapValue?["cutoff"], .number(800))
    }

    func testAddOnControlMaps() {
        let pat = n(.pattern(fastcat(0, 4))).add(.pattern(n(2)))
        let values = pat.sortHapsByPart().firstCycleValues
        XCTAssertEqual(values[0].mapValue?["n"] ?? .null, PatternValue.number(2))
        XCTAssertEqual(values[1].mapValue?["n"] ?? .null, PatternValue.number(6))
    }
}
