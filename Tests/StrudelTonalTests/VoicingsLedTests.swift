// VoicingsLedTests.swift — the chord-voicings voice-leading port, verified
// against the JS package running under node. AGPL-3.0-or-later.

import XCTest
@testable import StrudelTonal
@testable import StrudelCore
@testable import StrudelMini

final class VoicingsLedTests: XCTestCase {
    func testVoiceLeadingMatchesJS() throws {
        resetVoicings()
        let pat = try mini("<C^7 A7 Dm7 G7>").voicings("lefthand")
        // From node: cycle values of voicings('lefthand')
        let expected: [[String]] = [
            ["B3", "D4", "E4", "G4"],
            ["B3", "C#4", "F#4", "G3"],
            ["A3", "C4", "E4", "F3"],
            ["A3", "B3", "E4", "F3"],
        ]
        for cycle in 0..<4 {
            let values = pat.queryArc(Fraction(cycle), Fraction(cycle + 1))
                .compactMap { $0.value.stringValue }
                .sorted()
            XCTAssertEqual(values, expected[cycle].sorted(), "cycle \(cycle)")
        }
    }

    func testVoiceLeadingIsStateful() throws {
        resetVoicings()
        let pat = try mini("<C^7 A7>").voicings("lefthand")
        _ = pat.queryArc(Fraction(0), Fraction(1))
        let second = pat.queryArc(Fraction(1), Fraction(2))
            .compactMap { $0.value.stringValue }
        XCTAssertEqual(second.count, 4)
    }
}
