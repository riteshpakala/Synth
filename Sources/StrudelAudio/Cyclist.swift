// Cyclist.swift — the real-time pattern scheduler.
// Ported from Strudel <https://codeberg.org/uzu/strudel> (packages/core/cyclist.mjs)
// — AGPL-3.0-or-later.
//
// A repeating tick queries the pattern for the span covered since the last
// tick (in cycles), and hands every onset hap to `onTrigger` with its precise
// target time in seconds — the audio output schedules it sample-accurately.

import Foundation
import StrudelCore

public final class Cyclist: @unchecked Sendable {
    public typealias Trigger = (Hap, _ deadline: Double, _ duration: Double,
                                _ cps: Double, _ targetTime: Double) -> Void

    private let queue = DispatchQueue(label: "strudel.cyclist")
    private var timer: DispatchSourceTimer?
    private let interval: Double
    private let latency: Double
    private let getTime: () -> Double
    private let onTrigger: Trigger

    public private(set) var started = false
    private var cps: Double = 0.5
    private var pattern: StrudelCore.Pattern?

    private var numTicksSinceCpsChange = 0
    private var numCyclesAtCpsChange = Fraction.zero
    private var secondsAtCpsChange: Double = 0
    private var lastTick: Double = 0
    private var lastBegin = Fraction.zero
    private var lastEnd = Fraction.zero

    public init(interval: Double = 0.05, latency: Double = 0.1,
                getTime: @escaping () -> Double,
                onTrigger: @escaping Trigger) {
        self.interval = interval
        self.latency = latency
        self.getTime = getTime
        self.onTrigger = onTrigger
    }

    /// The current position in cycles.
    public func now() -> Double {
        guard started else { return 0 }
        let secondsSinceLastTick = getTime() - lastTick - interval
        return lastBegin.doubleValue + secondsSinceLastTick * cps
    }

    public func setPattern(_ pat: StrudelCore.Pattern, autostart: Bool = false) {
        queue.sync { self.pattern = pat }
        if autostart && !started { start() }
    }

    public func setCps(_ newCps: Double) {
        queue.sync {
            guard cps != newCps else { return }
            cps = newCps
            numTicksSinceCpsChange = 0
        }
    }

    public var currentCps: Double {
        queue.sync { cps }
    }

    public func start() {
        guard !started else { return }
        guard pattern != nil else { return }
        started = true
        queue.sync {
            numTicksSinceCpsChange = 0
            numCyclesAtCpsChange = .zero
            lastEnd = .zero
        }
        let t = DispatchSource.makeTimerSource(queue: queue)
        t.schedule(deadline: .now(), repeating: interval, leeway: .milliseconds(1))
        t.setEventHandler { [weak self] in self?.tick() }
        timer = t
        t.resume()
    }

    public func stop() {
        timer?.cancel()
        timer = nil
        started = false
        queue.sync { lastEnd = .zero }
    }

    public func pause() {
        timer?.cancel()
        timer = nil
        started = false
    }

    private func tick() {
        guard let pattern else { return }
        let phase = getTime()

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
        lastTick = phase

        guard end > begin else { return }

        let haps = pattern.queryArc(begin, end, controls: ["_cps": .number(cps)])
        for hap in haps where hap.hasOnset() {
            guard let whole = hap.whole else { continue }
            let targetTime = (whole.begin.doubleValue - numCyclesAtCpsChange.doubleValue) / cps
                + secondsAtCpsChange + latency
            let duration = hap.duration.doubleValue / cps
            let deadline = targetTime - phase
            onTrigger(hap, deadline, duration, cps, targetTime)
            // cps control on the hap changes the tempo
            if let hapCps = hap.value.mapValue?["cps"]?.doubleValue, hapCps != cps {
                cps = hapCps
                numTicksSinceCpsChange = 0
            }
        }
    }
}
