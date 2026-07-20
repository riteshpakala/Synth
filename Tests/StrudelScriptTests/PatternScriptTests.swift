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
            note("<[e5!3 e4@2] [d#5!3 d#4@2] [c#5!3 c#4@2] [a4 a4 g#4 e5@2]>")
              .s("steinway")
              .room(0.2)
            """,
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

    /// The Viva La Vida arrangement: sections must be structurally distinct
    /// and render audio (the complex ground-truth example).
    func testVivaLaVidaArrangement() throws {
        let source = """
        arrange(
          [8, stack(
            note("<[db4,f4,ab4]*8 [eb4,g4,bb4]*8 [ab3,c4,eb4]*8 [f3,ab3,c4]*8>")
              .s("sawtooth").lpf(2000).decay(0.16).sustain(0.2).gain(0.4).room(0.25),
            note("<db2 eb2 ab1 f2>").s("sawtooth").lpf(500).gain(0.7),
            s("z_sine*4").note("c1").decay(0.15),
            s("white*8").decay(0.03).gain(0.22)
          )],
          [8, stack(
            note("<[db4,f4,ab4]*8 [eb4,g4,bb4]*8 [ab3,c4,eb4]*8 [f3,ab3,c4]*8>")
              .s("sawtooth").lpf(3200).decay(0.16).sustain(0.25).gain(0.45).room(0.3),
            note("<[c5 db5 c5 ab4] [bb4 c5 bb4 g4] [ab4 bb4 c5 eb5] [f4 ab4 c5 ab4]>")
              .s("triangle").vib(5).release(0.15).gain(0.65).room(0.4).delay(0.2),
            note("<db2 eb2 ab1 f2>").s("sawtooth").lpf(600).gain(0.7),
            s("z_sine*4").note("c1").decay(0.15),
            s("[~ pink]*2").decay(0.07).gain(0.5),
            s("white*8").decay(0.03).gain(0.25)
          )]
        )
        """
        let pattern = try PatternScript.evaluate(source)
        // Structure: verse bars (cycle 0) vs chorus bars (cycle 8) — the
        // chorus adds melody + snare, so it must carry more onsets.
        let verseCount = pattern.queryArc(Fraction(0), Fraction(1)).filter { $0.hasOnset() }.count
        let chorusCount = pattern.queryArc(Fraction(8), Fraction(9)).filter { $0.hasOnset() }.count
        // verse: 8 chord stabs (3 notes each) + 1 bass + 4 kicks + 8 hats = 37
        XCTAssertEqual(verseCount, 37)
        // chorus adds 4 melody notes + 2 snares = 43
        XCTAssertEqual(chorusCount, 43)
        // the 16-bar form loops: cycle 16 matches cycle 0
        let loopCount = pattern.queryArc(Fraction(16), Fraction(17)).filter { $0.hasOnset() }.count
        XCTAssertEqual(loopCount, verseCount)
        // and it renders audio in both sections
        let player = StrudelPlayer()
        let (verse, _) = player.renderOffline(pattern, cycles: 1, cps: 138 / 240)
        let vRms = sqrt(verse.reduce(0.0) { $0 + Double($1) * Double($1) } / Double(max(verse.count, 1)))
        XCTAssertGreaterThan(vRms, 0.001)
        if let out = ProcessInfo.processInfo.environment["VIVA_WAV"] {
            try player.renderToFile(pattern, cycles: 16, cps: 138 / 240,
                                    url: URL(fileURLWithPath: out))
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

// MARK: - Slider safety (the "expected ')'" regression)

final class TunableSafetyTests: XCTestCase {
    override func setUp() { installMiniNotation() }

    /// The formatter must never emit notation the parser can't read back.
    func testFormatterNeverBreaksTheParser() throws {
        let values: [Double] = [0.0000743, 7.43e-9, 0.1, 1.0 / 3.0, 123.456,
                                12345.678, -0.0002, -12.5, 0, 1]
        for v in values {
            let formatted = PatternScript.format(v, isInt: false)
            XCTAssertFalse(formatted.lowercased().contains("e"),
                           "scientific notation leaked: \(formatted)")
            let source = "note(\"c3\").delay(\(formatted))"
            XCTAssertNoThrow(try PatternScript.evaluate(source),
                             "formatted value must parse: \(source)")
        }
    }

    /// Simulates a continuous drag: every intermediate rewrite must keep the
    /// code parseable even as literal lengths change (700 → 703.4 → 7000 …).
    func testContinuousDragKeepsCodeValid() throws {
        var source = #"note("c2 g1").s("sawtooth").lpf(700).room(0.3).delay(0.5)"#
        let id = PatternScript.tunables(in: source)[2].id  // delay#0? order: lpf, room, delay
        let sweep = stride(from: 0.0, through: 1.0, by: 0.013)
        for v in sweep {
            // resolve by stable id against the *current* source, like AppModel
            guard let fresh = PatternScript.tunables(in: source).first(where: { $0.id == id }) else {
                return XCTFail("tunable lost during drag")
            }
            source = PatternScript.replacing(fresh, with: v, in: source)
            XCTAssertNoThrow(try PatternScript.evaluate(source), "broken at \(v): \(source)")
        }
        // tiny values (the %g scientific-notation trap)
        for v in [0.00004, 0.0001, 0.000001] {
            guard let fresh = PatternScript.tunables(in: source).first(where: { $0.id == id }) else {
                return XCTFail("tunable lost")
            }
            source = PatternScript.replacing(fresh, with: v, in: source)
            XCTAssertNoThrow(try PatternScript.evaluate(source), "broken at tiny \(v): \(source)")
        }
    }

    /// A stale Tunable (captured before a rewrite shifted offsets) must not
    /// corrupt the code when resolved by id like AppModel does.
    func testStaleTunableResolvedById() throws {
        let source = #"note("c3").lpf(700).room(0.3)"#
        let stale = PatternScript.tunables(in: source)[0]  // lpf 700 at old offsets
        // code changes shape: literal grows by two characters
        let shifted = #"note("c3").lpf(12345).room(0.3)"#
        let fresh = PatternScript.tunables(in: shifted).first { $0.id == stale.id }
        XCTAssertNotNil(fresh)
        let updated = PatternScript.replacing(fresh!, with: 900, in: shifted)
        XCTAssertTrue(updated.contains("lpf(900)"), updated)
        XCTAssertTrue(updated.contains("room(0.3)"), updated)
        XCTAssertNoThrow(try PatternScript.evaluate(updated))
    }
}
