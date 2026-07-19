// RenderTests.swift — offline render smoke tests. AGPL-3.0-or-later.

import XCTest
@testable import StrudelAudio
@testable import StrudelCore
@testable import StrudelMini

final class RenderTests: XCTestCase {
    override func setUp() {
        installMiniNotation()
    }

    func rms(_ xs: [Float]) -> Double {
        guard !xs.isEmpty else { return 0 }
        return sqrt(xs.reduce(0.0) { $0 + Double($1) * Double($1) } / Double(xs.count))
    }

    func testRenderNotePattern() throws {
        let pat = note("c3 e3 g3 c4").s("triangle")
        let player = StrudelPlayer()
        let (left, right) = player.renderOffline(pat, cycles: 1, cps: 1)
        XCTAssertGreaterThan(left.count, 40_000)
        XCTAssertGreaterThan(rms(left), 0.001, "should not be silent")
        XCTAssertGreaterThan(rms(right), 0.001)
        XCTAssertTrue(left.allSatisfy { $0.isFinite })
    }

    func testRenderSteinway() throws {
        let pat = note("e5 e4").s("steinway")
        let player = StrudelPlayer()
        let (left, _) = player.renderOffline(pat, cycles: 1, cps: 0.5)
        XCTAssertGreaterThan(rms(left), 0.001)
    }

    func testVowelFilterChangesSound() throws {
        let plain = note("c3").s("sawtooth")
        let vowelized = note("c3").s("sawtooth").vowel("a")
        let player = StrudelPlayer()
        let (a, _) = player.renderOffline(plain, cycles: 1, cps: 1)
        let (b, _) = player.renderOffline(vowelized, cycles: 1, cps: 1)
        XCTAssertGreaterThan(rms(b), 0.0001)
        XCTAssertNotEqual(rms(a), rms(b))
    }

    func testEffectsTails() throws {
        let dryPat = s("triangle").note(60)
        let wetPat = s("triangle").note(60).delay(0.8).room(0.5)
        let player = StrudelPlayer()
        let (dry, _) = player.renderOffline(dryPat, cycles: 1, cps: 1)
        let (wet, _) = player.renderOffline(wetPat, cycles: 1, cps: 1)
        XCTAssertGreaterThan(wet.count, dry.count, "delay/reverb should extend the tail")
    }

    func testMiniIntegration() throws {
        let pat = try mini("c3 [e3 g3]*2").fmap { v in .map(["note": v]) }
        let player = StrudelPlayer()
        let (left, _) = player.renderOffline(pat, cycles: 1, cps: 1)
        XCTAssertGreaterThan(rms(left), 0.001)
    }

    func testGainControl() throws {
        let loud = note("c3").gain(1)
        let quiet = note("c3").gain(0.1)
        let player = StrudelPlayer()
        let (a, _) = player.renderOffline(loud, cycles: 1, cps: 1)
        let (b, _) = player.renderOffline(quiet, cycles: 1, cps: 1)
        XCTAssertGreaterThan(rms(a), rms(b) * 2)
    }
}
