// DeviationCoverageTests.swift — tests for the formerly-deviating features:
// exact distortion algorithms, phaser, compressor, partials, zzfx, wavetables,
// and shared orbit buses. Reference values captured from the JS sources.
// AGPL-3.0-or-later.

import XCTest
@testable import StrudelAudio
@testable import StrudelCore
@testable import StrudelMini

final class DistortionAlgorithmTests: XCTestCase {
    // k = expm1(1.5), values from helpers.mjs run under node
    func testAlgorithmsMatchJS() {
        let k = expm1(1.5)
        let cases: [(DistortionAlgorithm, Double, Double)] = [
            (.scurve, 0.657619125056, -0.912719207328),
            (.soft, 0.872750462292, -0.996239110322),
            (.hard, 1.0, -1.0),
            (.fold, 0.822253360551, -0.081408825382),
            (.sinefold, 0.961275176755, -0.127528452621),
            (.cubic, 0.928910022264, -0.998308340374),
        ]
        for (algo, expPos, expNeg) in cases {
            XCTAssertEqual(algo.apply(0.3, k), expPos, accuracy: 1e-9, "\(algo) +")
            XCTAssertEqual(algo.apply(-0.7, k), expNeg, accuracy: 1e-9, "\(algo) -")
        }
    }

    func testAlgorithmOrderMatchesDistorttype() {
        // distorttype indexes: scurve is 0 (superdough _algoNames[0])
        XCTAssertEqual(DistortionAlgorithm.indexed(0), .scurve)
        XCTAssertEqual(DistortionAlgorithm.indexed(1), .soft)
        XCTAssertEqual(DistortionAlgorithm.named("chebyshev"), .chebyshev)
    }
}

final class DeviationRenderTests: XCTestCase {
    override func setUp() { installMiniNotation() }

    func rms(_ xs: [Float]) -> Double {
        guard !xs.isEmpty else { return 0 }
        return sqrt(xs.reduce(0.0) { $0 + Double($1) * Double($1) } / Double(xs.count))
    }

    func render(_ pat: StrudelCore.Pattern, cycles: Double = 1) -> ([Float], [Float]) {
        StrudelPlayer().renderOffline(pat, cycles: cycles, cps: 1)
    }

    func testDistortionCombinators() {
        let plain = note("c2").s("sawtooth")
        let folded = note("c2").s("sawtooth").fold(2)
        let (a, _) = render(plain)
        let (b, _) = render(folded)
        XCTAssertGreaterThan(rms(b), 0.0001)
        XCTAssertNotEqual(rms(a), rms(b))
        // [amount, vol, algo] splats across the multi-name distort control
        let m = fold(2).firstCycleValues[0].mapValue
        XCTAssertEqual(m?["distort"]?.doubleValue, 2)
        XCTAssertEqual(m?["distortvol"]?.doubleValue, 1)
        XCTAssertEqual(m?["distorttype"]?.stringValue, "fold")
    }

    func testPhaserChangesSound() {
        let dry = note("c3").s("sawtooth")
        let wet = note("c3").s("sawtooth").phaser(2)
        let (a, _) = render(dry)
        let (b, _) = render(wet)
        XCTAssertGreaterThan(rms(b), 0.0001)
        XCTAssertNotEqual(rms(a), rms(b))
    }

    func testCompressorTamesPeaks() {
        let dry = note("c3").s("sawtooth").gain(1)
        let squashed = note("c3").s("sawtooth").gain(1).compressor(-30)
        let (a, _) = render(dry)
        let (b, _) = render(squashed)
        XCTAssertGreaterThan(rms(b), 0.0001)
        XCTAssertLessThan(b.map { abs($0) }.max() ?? 0, a.map { abs($0) }.max() ?? 0)
    }

    func testPartialsCustomWaveform() {
        // A "user" waveform with one partial is a pure sine
        let user = note("a3").s("user").partials(.list([1]))
        let (a, _) = render(user)
        XCTAssertGreaterThan(rms(a), 0.001)
        // more partials → different waveform
        let bright = note("a3").s("user").partials(.list([1, 0.8, 0.6, 0.4]))
        let (b, _) = render(bright)
        XCTAssertNotEqual(rms(a), rms(b))
    }

    func testZzfxRenders() {
        let pat = note("c3").s("z_sawtooth")
        let (a, _) = render(pat)
        XCTAssertGreaterThan(rms(a), 0.001)
        let zap = note("c4").s("z_square").slide(2).zcrush(2)
        let (b, _) = render(zap)
        XCTAssertGreaterThan(rms(b), 0.0005)
    }

    func testSharedOrbitDelayBus() {
        let pat = note(.pattern(fastcat("c3", "e3"))).s("triangle")
            .delay(0.8).delaytime(.pattern(fastcat(0.1, 0.3)))
        let (left, _) = render(pat)
        XCTAssertGreaterThan(rms(left), 0.001)
        // the tail extends past the dry cycle (delay ring-out)
        XCTAssertGreaterThan(left.count, 44_100)
    }

    func testReverbBusRingsOut() {
        let dry = note("c3").s("triangle")
        let wet = note("c3").s("triangle").room(0.8)
        let (a, _) = render(dry)
        let (b, _) = render(wet)
        XCTAssertGreaterThan(b.count, a.count)
        // energy exists well after the dry sound ends
        let tail = Array(b.suffix(from: min(a.count, b.count - 1)))
        XCTAssertGreaterThan(rms(tail), 1e-5)
    }

    func testWavetableSound() throws {
        // Build a synthetic 2-frame wavetable: frame 0 = sine, frame 1 = saw
        let frameLen = WavetableSound.frameLen
        var samples = [Float]()
        for i in 0..<frameLen { samples.append(Float(sin(2 * .pi * Double(i) / Double(frameLen)))) }
        for i in 0..<frameLen { samples.append(Float(2 * Double(i) / Double(frameLen) - 1)) }
        let sound = WavetableSound(name: "wt_test", files: [(samples, 44_100)])
        SoundRegistry.shared.register(sound, as: "wt_test")

        let pure0 = note("a3").s("wt_test").wt(0)
        let pure1 = note("a3").s("wt_test").wt(1)
        let (a, _) = render(pure0)
        let (b, _) = render(pure1)
        XCTAssertGreaterThan(rms(a), 0.001)
        XCTAssertGreaterThan(rms(b), 0.001)
        // different frames make audibly different waveforms
        XCTAssertNotEqual(rms(a), rms(b), accuracy: 1e-6)
    }
}
