// PatternScriptTests.swift — the DSL interpreter behind the app's code pad.
// AGPL-3.0-or-later.

import XCTest
@testable import Strudel
import StrudelCore
import StrudelMini

final class PatternScriptTests: XCTestCase {
    override func setUp() { installMiniNotation() }

    func firstCycle(_ source: String) throws -> [Hap] {
        try PatternScript.evaluate(source).sortHapsByPart().firstCycle()
    }

    func testSimpleChain() throws {
        let scripted = try firstCycle(#"note("c3 e3").s("sawtooth")"#)
        let direct = note("c3 e3").s("sawtooth").sortHapsByPart().firstCycle()
        XCTAssertEqual(scripted.count, direct.count)
        for (a, b) in zip(scripted, direct) {
            XCTAssertTrue(a.equals(b), "\(a) vs \(b)")
        }
    }

    func testControlFallbackAndNumbers() throws {
        let haps = try firstCycle(#"note("c3").lpf(800).room(0.5).gain(0.9)"#)
        XCTAssertEqual(haps.count, 1)
        let m = haps[0].value.mapValue
        XCTAssertEqual(m?["cutoff"]?.doubleValue, 800)
        XCTAssertEqual(m?["room"]?.doubleValue, 0.5)
        XCTAssertEqual(m?["gain"]?.doubleValue, 0.9)
    }

    func testTrailingClosure() throws {
        let scripted = try PatternScript.evaluate(#"note("c3 e3 g3").every(2) { $0.rev() }"#)
        let direct = note("c3 e3 g3").every(2) { $0.rev() }
        for cycle in 0..<2 {
            let a = scripted.queryArc(Fraction(cycle), Fraction(cycle + 1)).map(\.value)
            let b = direct.queryArc(Fraction(cycle), Fraction(cycle + 1)).map(\.value)
            XCTAssertEqual(a, b, "cycle \(cycle)")
        }
    }

    func testCurriedFunctionArgument() throws {
        // jux(rev) — bare combinator identifier becomes a transform
        let scripted = try PatternScript.evaluate(#"s("white*4").jux(rev)"#)
        let direct = s("white*4").jux { $0.rev() }
        XCTAssertEqual(scripted.firstCycle().count, direct.firstCycle().count)
    }

    func testStackAndSignals() throws {
        let scripted = try PatternScript.evaluate(#"stack(note("c3"), s("white*2")).lpf(sine.range(400, 2000))"#)
        XCTAssertGreaterThan(scripted.firstCycle().count, 2)
    }

    func testMethodWithoutParens() throws {
        let scripted = try PatternScript.evaluate(#"note("c3 e3").rev"#)
        let direct = note("c3 e3").rev()
        XCTAssertEqual(scripted.firstCycle().map(\.value), direct.firstCycle().map(\.value))
    }

    func testParseErrorReported() {
        XCTAssertThrowsError(try PatternScript.evaluate(#"note("c3"#))
        XCTAssertThrowsError(try PatternScript.evaluate(#"note("c3").nonsense(1)"#))
    }

    func testCommentsAndWhitespace() throws {
        let source = """
        // a comment
        note("c3 e3")   // trailing
          .s("triangle")
        """
        XCTAssertEqual(try firstCycle(source).count, 2)
    }

    // MARK: tunables

    func testTunableExtraction() throws {
        let source = #"note("c3").lpf(800).fast(2).room(0.5)"#
        let tunables = PatternScript.tunables(in: source)
        XCTAssertEqual(tunables.map(\.context), ["lpf", "fast", "room"])
        XCTAssertEqual(tunables.map(\.value), [800, 2, 0.5])
        XCTAssertEqual(tunables[0].range, 20...8000)
        XCTAssertEqual(tunables[2].range, 0...1)
        // ids stable across value changes
        XCTAssertEqual(tunables[0].id, "lpf#0")
    }

    func testTunableReplacementRoundTrip() throws {
        var source = #"note("c3").lpf(800).fast(2)"#
        let tunables = PatternScript.tunables(in: source)
        source = PatternScript.replacing(tunables[0], with: 1234, in: source)
        XCTAssertTrue(source.contains("lpf(1234)"), source)
        // re-extract: offsets shifted but ids stable
        let again = PatternScript.tunables(in: source)
        XCTAssertEqual(again[0].id, "lpf#0")
        XCTAssertEqual(again[0].value, 1234)
        XCTAssertEqual(again[1].value, 2)
        // evaluation still works
        XCTAssertNoThrow(try PatternScript.evaluate(source))
    }

    func testTunablesInsideListsAndClosures() throws {
        let source = #"note("c3").every(4) { $0.lpf(600) }.adsr([0.01, 0.1, 0.5, 0.2])"#
        let tunables = PatternScript.tunables(in: source)
        XCTAssertEqual(tunables.map(\.context), ["every", "lpf", "adsr", "adsr", "adsr", "adsr"])
    }

    func testNegativeAndFractionalNumbers() throws {
        let haps = try firstCycle(#"note("c3").add(-12).pan(0.25)"#)
        XCTAssertEqual(haps.count, 1)
        XCTAssertEqual(haps[0].value.mapValue?["pan"]?.doubleValue, 0.25)
    }
}

// MARK: - The app's example snippets, end to end

import StrudelAudio

final class ExampleSnippetTests: XCTestCase {
    override func setUp() { installMiniNotation() }

    /// Every snippet the app ships must parse, evaluate, and produce audio.
    func testExamplesEvaluateAndRender() throws {
        let examples = [
            """
            note("c2 [c2 eb2]*2 g1 <bb1 c2>")
              .s("sawtooth")
              .lpf(700).lpenv(3)
              .cubic(1.2)
              .room(0.3)
              .every(4) { $0.rev() }
            """,
            """
            stack(
              s("z_triangle*4").note("c1").decay(0.18),
              s("white*8").decay(0.05).gain(0.5).pan(sine),
              s("pink").euclid(3, 8).decay(0.1)
            ).room(0.2)
            """,
            """
            mini("<C^7 A7 Dm7 G7>")
              .voicings()
              .note()
              .s("steinway")
              .slow(2)
              .room(0.4)
            """,
        ]
        for (i, source) in examples.enumerated() {
            let pattern = try PatternScript.evaluate(source)
            let (left, _) = StrudelPlayer().renderOffline(pattern, cycles: 1, cps: 0.5)
            let rms = sqrt(left.reduce(0.0) { $0 + Double($1) * Double($1) } / Double(max(left.count, 1)))
            XCTAssertGreaterThan(rms, 1e-4, "example \(i) is silent")
        }
    }

    /// Slider round-trip on the shipped default: tweak lpf, still audible.
    func testTunableTweakKeepsRendering() throws {
        var source = """
        note("c2 g1").s("sawtooth").lpf(700).room(0.3)
        """
        let tunables = PatternScript.tunables(in: source)
        let lpf = tunables.first { $0.context == "lpf" }!
        source = PatternScript.replacing(lpf, with: 2400, in: source)
        let pattern = try PatternScript.evaluate(source)
        let (left, _) = StrudelPlayer().renderOffline(pattern, cycles: 1, cps: 0.5)
        let rms = sqrt(left.reduce(0.0) { $0 + Double($1) * Double($1) } / Double(max(left.count, 1)))
        XCTAssertGreaterThan(rms, 1e-4)
    }
}
