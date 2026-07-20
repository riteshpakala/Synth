// Cyclist.swift — the real-time pattern scheduler.
// Ported from Strudel <https://codeberg.org/uzu/strudel> (packages/core/cyclist.mjs
// + zyklus) — AGPL-3.0-or-later.
//
// A phase-locked tick loop (zyklus-style: ticks advance by a fixed interval and
// catch up to real time, so timer drift/stalls never push targets into the
// past) queries the pattern per tick window and hands every onset hap to
// `onTrigger` with its precise target time in seconds.

import Foundation
import StrudelCore

/// The pure scheduling math of cyclist.mjs, separated from timers so it can
/// be tested with simulated time.
public struct CyclistClock {
    public let interval: Double
    public let latency: Double
    public private(set) var cps: Double

    private var numTicksSinceCpsChange = 0
    private var numCyclesAtCpsChange = Fraction.zero
    private var secondsAtCpsChange: Double = 0
    public private(set) var lastBegin = Fraction.zero
    public private(set) var lastEnd = Fraction.zero
    public private(set) var lastPhase: Double = 0

    public init(interval: Double = 0.05, latency: Double = 0.15, cps: Double = 0.5) {
        self.interval = interval
        self.latency = latency
        self.cps = cps
    }

    /// One query window: the cycle span to query plus everything needed to
    /// convert cycle positions into wall-clock target seconds.
    public struct Window {
        public let begin: Fraction
        public let end: Fraction
        public let cps: Double
        let cyclesAtCpsChange: Fraction
        let secondsAtCpsChange: Double
        let latency: Double

        /// Target time (seconds on the getTime clock) for a cycle position.
        public func targetSeconds(forCycle cycle: Fraction) -> Double {
            (cycle.doubleValue - cyclesAtCpsChange.doubleValue) / cps
                + secondsAtCpsChange + latency
        }
    }

    /// Advances one tick at the given phase; returns the window to query.
    /// `phase` must advance by exactly `interval` per call (phase-locked).
    public mutating func tick(phase: Double) -> Window {
        if numTicksSinceCpsChange == 0 {
            numCyclesAtCpsChange = lastEnd
            secondsAtCpsChange = phase
        }
        numTicksSinceCpsChange += 1
        let secondsSinceCpsChange = Double(numTicksSinceCpsChange) * interval
        let numCyclesSinceCpsChange = secondsSinceCpsChange * cps

        let begin = lastEnd
        lastBegin = begin
        let end = numCyclesAtCpsChange.add(Fraction(numCyclesSinceCpsChange))
        lastEnd = end
        lastPhase = phase

        return Window(begin: begin, end: end, cps: cps,
                      cyclesAtCpsChange: numCyclesAtCpsChange,
                      secondsAtCpsChange: secondsAtCpsChange,
                      latency: latency)
    }

    public mutating func setCps(_ newCps: Double) {
        guard cps != newCps else { return }
        cps = newCps
        numTicksSinceCpsChange = 0
    }

    public mutating func reset() {
        numTicksSinceCpsChange = 0
        numCyclesAtCpsChange = .zero
        lastBegin = .zero
        lastEnd = .zero
    }

    /// Current position in cycles at the given time.
    public func now(at time: Double) -> Double {
        lastBegin.doubleValue + (time - lastPhase - interval) * cps
    }
}

public final class Cyclist: @unchecked Sendable {
    public typealias Trigger = (Hap, _ deadline: Double, _ duration: Double,
                                _ cps: Double, _ targetTime: Double) -> Void

    private let queue = DispatchQueue(label: "strudel.cyclist", qos: .userInteractive)
    private var timer: DispatchSourceTimer?
    private let getTime: () -> Double
    private let onTrigger: Trigger

    public private(set) var started = false
    private var clock: CyclistClock
    private var pattern: StrudelCore.Pattern?
    /// The phase of the next tick — advances by exactly `interval` per tick,
    /// catching up to real time when the timer is late.
    private var nextPhase: Double = 0

    public init(interval: Double = 0.05, latency: Double = 0.15,
                getTime: @escaping () -> Double,
                onTrigger: @escaping Trigger) {
        self.clock = CyclistClock(interval: interval, latency: latency)
        self.getTime = getTime
        self.onTrigger = onTrigger
    }

    /// The current position in cycles.
    public func now() -> Double {
        guard started else { return 0 }
        return queue.sync { clock.now(at: getTime()) }
    }

    public func setPattern(_ pat: StrudelCore.Pattern, autostart: Bool = false) {
        queue.sync { self.pattern = pat }
        if autostart && !started { start() }
    }

    public func setCps(_ newCps: Double) {
        queue.sync { clock.setCps(newCps) }
    }

    public var currentCps: Double {
        queue.sync { clock.cps }
    }

    public func start() {
        guard !started else { return }
        guard pattern != nil else { return }
        started = true
        queue.sync {
            clock.reset()
            nextPhase = getTime()
        }
        let t = DispatchSource.makeTimerSource(queue: queue)
        t.schedule(deadline: .now(), repeating: clock.interval / 2, leeway: .milliseconds(1))
        t.setEventHandler { [weak self] in self?.pump() }
        timer = t
        t.resume()
    }

    public func stop() {
        timer?.cancel()
        timer = nil
        started = false
        queue.sync { clock.reset() }
    }

    public func pause() {
        timer?.cancel()
        timer = nil
        started = false
    }

    /// Fires every due tick, catching up when the timer was late so tick time
    /// stays phase-locked to real time (zyklus behavior).
    private func pump() {
        let now = getTime()
        // If we've stalled far beyond the latency horizon (app suspended,
        // debugger pause), jump forward instead of replaying missed windows.
        if now - nextPhase > clock.latency + 4 * clock.interval {
            nextPhase = now
        }
        while nextPhase <= now + clock.interval / 2 {
            tick(phase: nextPhase)
            nextPhase += clock.interval
        }
    }

    private func tick(phase: Double) {
        guard let pattern else { return }
        let window = clock.tick(phase: phase)
        guard window.end > window.begin else { return }

        let haps = pattern.queryArc(window.begin, window.end,
                                    controls: ["_cps": .number(window.cps)])
        for hap in haps where hap.hasOnset() {
            guard let whole = hap.whole else { continue }
            let targetTime = window.targetSeconds(forCycle: whole.begin)
            let duration = hap.duration.doubleValue / window.cps
            let deadline = targetTime - phase
            onTrigger(hap, deadline, duration, window.cps, targetTime)
            // a cps control on the hap changes the tempo
            if let hapCps = hap.value.mapValue?["cps"]?.doubleValue, hapCps != clock.cps {
                clock.setCps(hapCps)
            }
        }
    }
}
