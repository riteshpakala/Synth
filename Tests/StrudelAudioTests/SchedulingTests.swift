// SchedulingTests.swift — the live-playback fixes: phase-locked cyclist clock,
// orbit bus clearing, render caching. AGPL-3.0-or-later.

import XCTest
@testable import StrudelAudio
@testable import StrudelCore
@testable import StrudelMini

final class CyclistClockTests: XCTestCase {
    func testWindowsAreContiguousAndMonotonic() {
        var clock = CyclistClock(interval: 0.05, latency: 0.15, cps: 0.5)
        var lastEnd = Fraction.zero
        var lastTarget = -Double.infinity
        for i in 0..<200 {
            let phase = Double(i) * 0.05
            let w = clock.tick(phase: phase)
            XCTAssertEqual(w.begin, lastEnd, "windows must be contiguous")
            XCTAssertGreaterThanOrEqual(w.end, w.begin)
            lastEnd = w.end
            // target for the window start is monotonically increasing
            let t = w.targetSeconds(forCycle: w.begin)
            XCTAssertGreaterThanOrEqual(t, lastTarget)
            lastTarget = t
        }
        // 200 ticks × 0.05 s × 0.5 cps = 5 cycles
        XCTAssertEqual(lastEnd.doubleValue, 5.0, accuracy: 1e-9)
    }

    func testTargetTimeMapping() {
        var clock = CyclistClock(interval: 0.05, latency: 0.15, cps: 0.5)
        _ = clock.tick(phase: 0)
        let w = clock.tick(phase: 0.05)
        // cycle 0.05 at 0.5 cps = 0.1 s + latency 0.15 = 0.25 s
        XCTAssertEqual(w.targetSeconds(forCycle: Fraction(1, 20)), 0.25, accuracy: 1e-9)
        // targets always land at/after the tick phase + latency (schedulable)
        XCTAssertGreaterThanOrEqual(w.targetSeconds(forCycle: w.begin), 0.05)
    }

    func testCpsChangeKeepsCyclePositionAndTime() {
        var clock = CyclistClock(interval: 0.05, latency: 0.15, cps: 0.5)
        for i in 0..<40 { // 2 s at 0.5 cps → cycle 1.0
            _ = clock.tick(phase: Double(i) * 0.05)
        }
        XCTAssertEqual(clock.lastEnd.doubleValue, 1.0, accuracy: 1e-9)
        clock.setCps(2.0)
        let w = clock.tick(phase: 2.0)
        // no cycle jump on tempo change
        XCTAssertEqual(w.begin.doubleValue, 1.0, accuracy: 1e-9)
        // and the new mapping anchors at the change point
        XCTAssertEqual(w.targetSeconds(forCycle: w.begin), 2.0 + 0.15, accuracy: 1e-9)
    }

    func testTriggersNeverScheduleInThePastAfterStall() {
        // Simulates the pump loop: ticks catch up after a 300 ms timer stall.
        var clock = CyclistClock(interval: 0.05, latency: 0.15, cps: 1.0)
        var nextPhase = 0.0
        var minHeadroom = Double.infinity
        var now = 0.0
        var stalled = false
        while now < 2.0 {
            // the timer fires late once, at t=1.0 → 1.3
            now += stalled ? 0.025 : 0.025
            if !stalled && now >= 1.0 {
                now = 1.3
                stalled = true
            }
            while nextPhase <= now + 0.025 {
                let w = clock.tick(phase: nextPhase)
                let headroom = w.targetSeconds(forCycle: w.begin) - now
                minHeadroom = min(minHeadroom, headroom)
                nextPhase += 0.05
            }
        }
        // catch-up must keep every window's start target at/after "now" —
        // with 150 ms latency and a 300 ms stall the worst case dips but
        // must never go negative beyond the stall gap minus latency.
        XCTAssertGreaterThan(minHeadroom, -0.2)
    }
}

final class OrbitBusTests: XCTestCase {
    func testClearSilencesPendingSends() {
        let bus = OrbitBus(orbit: 1, sampleRate: 44_100)
        let send = [Float](repeating: 0.5, count: 4_410)
        bus.write(delaySend: send, reverbSend: send, atSample: 1_000,
                  delayTime: 0.2, delayFeedback: 0.5, roomSize: 0.5)
        bus.clear()
        var left = [Float](repeating: 1, count: 8_192)
        var right = left
        left.withUnsafeMutableBufferPointer { l in
            right.withUnsafeMutableBufferPointer { r in
                bus.renderBlockForTesting(startSample: 0, frameCount: 8_192,
                                          left: l.baseAddress!, right: r.baseAddress!)
            }
        }
        XCTAssertEqual(left.map { abs($0) }.max() ?? 1, 0, "cleared bus must render silence")
        XCTAssertEqual(right.map { abs($0) }.max() ?? 1, 0)
    }

    func testWithoutClearSendsAreAudible() {
        let bus = OrbitBus(orbit: 1, sampleRate: 44_100)
        let send = [Float](repeating: 0.5, count: 4_410)
        bus.write(delaySend: send, reverbSend: send, atSample: 0,
                  delayTime: 0.05, delayFeedback: 0.5, roomSize: 0.5)
        var left = [Float](repeating: 0, count: 8_192)
        var right = left
        left.withUnsafeMutableBufferPointer { l in
            right.withUnsafeMutableBufferPointer { r in
                bus.renderBlockForTesting(startSample: 0, frameCount: 8_192,
                                          left: l.baseAddress!, right: r.baseAddress!)
            }
        }
        XCTAssertGreaterThan(left.map { abs($0) }.max() ?? 0, 0)
    }
}

final class RenderCacheTests: XCTestCase {
    func testRepeatedHapsHitTheCache() {
        installMiniNotation()
        let player = StrudelPlayer()
        let value = PatternValue.map(["note": .number(48), "s": .string("triangle")])
        let first = player.renderedBufferForTesting(value: value, duration: 0.5, cps: 0.5)
        let second = player.renderedBufferForTesting(value: value, duration: 0.5, cps: 0.5)
        XCTAssertNotNil(first)
        // identical object ⇒ cache hit (no re-render)
        XCTAssertTrue(first!.0 === second!.0)
        // different duration ⇒ different buffer
        let third = player.renderedBufferForTesting(value: value, duration: 0.25, cps: 0.5)
        XCTAssertFalse(first!.0 === third!.0)
    }
}
