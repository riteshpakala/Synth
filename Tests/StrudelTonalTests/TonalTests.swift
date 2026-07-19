// TonalTests.swift — expectations captured from JS strudel's tonal package.
// AGPL-3.0-or-later.

import XCTest
@testable import StrudelTonal
@testable import StrudelCore
@testable import StrudelMini

final class PitchMathTests: XCTestCase {
    func testTranspose() {
        XCTAssertEqual(TonalPitch.transpose("C4", "3M"), "E4")
        XCTAssertEqual(TonalPitch.transpose("D", "3M"), "F#")
        XCTAssertEqual(TonalPitch.transpose("Eb3", "5P"), "Bb3")
        XCTAssertEqual(TonalPitch.transpose("C3", "2m"), "Db3")
        XCTAssertEqual(TonalPitch.transpose("G3", "-2m"), "F#3")
        XCTAssertEqual(TonalPitch.transpose("B3", "2M"), "C#4")
    }

    func testIntervalSemitones() {
        XCTAssertEqual(TonalPitch.semitones("3M"), 4)
        XCTAssertEqual(TonalPitch.semitones("5P"), 7)
        XCTAssertEqual(TonalPitch.semitones("7m"), 10)
        XCTAssertEqual(TonalPitch.semitones("12P"), 19)
        XCTAssertEqual(TonalPitch.semitones("-2M"), -2)
        XCTAssertEqual(TonalPitch.semitones("5d"), 6)
        XCTAssertEqual(TonalPitch.semitones("4A"), 6)
    }

    func testFromSemitones() {
        XCTAssertEqual(TonalPitch.fromSemitones(4), "3M")
        XCTAssertEqual(TonalPitch.fromSemitones(7), "5P")
        XCTAssertEqual(TonalPitch.fromSemitones(12), "8P")
        XCTAssertEqual(TonalPitch.fromSemitones(-2), "-2M")
    }

    func testAddIntervals() {
        XCTAssertEqual(TonalPitch.addIntervals("3m", "5P"), "7m")
        XCTAssertEqual(TonalPitch.addIntervals("3M", "8P"), "10M")
    }
}

final class ScaleTests: XCTestCase {
    func values(_ pat: StrudelCore.Pattern) -> [String] {
        pat.sortHapsByPart().firstCycle().map { hap in
            if let m = hap.value.mapValue, let note = m["note"] {
                return note.description
            }
            return hap.value.description
        }
    }

    func testScaleSteps() {
        // JS: n("0 2 4 7").scale("C:major") -> C3 E3 G3 C4
        let pat = n(.pattern(try! mini("0 2 4 7"))).scale("C:major")
        XCTAssertEqual(values(pat), ["C3", "E3", "G3", "C4"])
    }

    func testScaleNegativeSteps() {
        // JS: n("-1 -2").scale("C:major") -> B2 A2
        let pat = n(.pattern(try! mini("-1 -2"))).scale("C:major")
        XCTAssertEqual(values(pat), ["B2", "A2"])
    }

    func testScaleAccidentalSteps() {
        // JS: n("0# 4b").scale("C:major") -> Db3 F#3
        let pat = n(.pattern(try! mini("0# 4b"))).scale("C:major")
        XCTAssertEqual(values(pat), ["Db3", "F#3"])
    }

    func testTransposeSemitones() {
        // JS: note("c3 e3").transpose(12) -> C4 E4
        let pat = note(.pattern(try! mini("c3 e3"))).transpose(12)
        XCTAssertEqual(values(pat), ["C4", "E4"])
    }

    func testTransposeInterval() {
        // JS: note("c3").transpose("3M") -> E3
        let pat = note("c3").transpose("3M")
        XCTAssertEqual(values(pat), ["E3"])
    }

    func testScaleTranspose() {
        // JS: note("c3 e3").scale("C:major").scaleTranspose(2) -> E3 G3
        let pat = note(.pattern(try! mini("c3 e3"))).scale("C:major").scaleTranspose(2)
        XCTAssertEqual(values(pat), ["E3", "G3"])
    }

    func testVoicing() {
        // JS: "C^7".voicing() -> C3 E4 G4 B4
        let pat = pure(.string("C^7")).voicing()
        XCTAssertEqual(Set(values(pat)), Set(["C3", "E4", "G4", "B4"]))
    }

    func testRootNotes() {
        // JS: "C^7 A7".rootNotes(2) -> C2 A2
        let pat = fastcat("C^7", "A7").rootNotes(2)
        XCTAssertEqual(values(pat), ["C2", "A2"])
    }

    func testScaleQuantizesNotes() {
        // notes get snapped to the nearest scale note
        let pat = note("c#3").scale("C:major")
        let vals = values(pat)
        XCTAssertEqual(vals.count, 1)
        XCTAssertTrue(["C3", "D3"].contains(vals[0]), "got \(vals)")
    }
}
