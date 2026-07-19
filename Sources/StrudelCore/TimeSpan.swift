// TimeSpan.swift — an arc of time between two rational points.
// Ported from Strudel <https://codeberg.org/uzu/strudel> (packages/core/timespan.mjs)
// — AGPL-3.0-or-later.

import Foundation

/// A span (arc) of time, measured in cycles.
public struct TimeSpan: Sendable, Hashable {
    public let begin: Fraction
    public let end: Fraction

    public init(_ begin: Fraction, _ end: Fraction) {
        self.begin = begin
        self.end = end
    }

    /// Splits the span at cycle boundaries.
    public var spanCycles: [TimeSpan] {
        // Support zero-width timespans.
        if begin == end { return [TimeSpan(begin, end)] }

        var spans: [TimeSpan] = []
        var b = begin
        let endSam = end.sam()
        while end > b {
            // If begin and end are in the same cycle, we're done.
            if b.sam() == endSam {
                spans.append(TimeSpan(b, end))
                break
            }
            // Add a timespan up to the next sam and continue with the next cycle.
            let nextBegin = b.nextSam()
            spans.append(TimeSpan(b, nextBegin))
            b = nextBegin
        }
        return spans
    }

    public var duration: Fraction { end.sub(begin) }

    /// Shifts to a span of equal duration that starts within cycle zero.
    public func cycleArc() -> TimeSpan {
        let b = begin.cyclePos()
        return TimeSpan(b, b.add(duration))
    }

    /// Applies a function to both the begin and end times.
    public func withTime(_ f: (Fraction) -> Fraction) -> TimeSpan {
        TimeSpan(f(begin), f(end))
    }

    /// Applies a function to the end time only.
    public func withEnd(_ f: (Fraction) -> Fraction) -> TimeSpan {
        TimeSpan(begin, f(end))
    }

    /// Like `withTime`, but relative to the cycle (the sam of the span's start).
    public func withCycle(_ f: (Fraction) -> Fraction) -> TimeSpan {
        let sam = begin.sam()
        let b = sam.add(f(begin.sub(sam)))
        let e = sam.add(f(end.sub(sam)))
        return TimeSpan(b, e)
    }

    /// Intersection of two timespans; nil if they don't intersect.
    /// A zero-width intersection at the end of a non-zero-width span doesn't count.
    public func intersection(_ other: TimeSpan) -> TimeSpan? {
        let iBegin = begin.max(other.begin)
        let iEnd = end.min(other.end)
        if iBegin > iEnd { return nil }
        if iBegin == iEnd {
            if iBegin == end && begin < end { return nil }
            if iBegin == other.end && other.begin < other.end { return nil }
        }
        return TimeSpan(iBegin, iEnd)
    }

    /// Like `intersection`, but traps if the timespans don't intersect.
    public func intersectionE(_ other: TimeSpan) -> TimeSpan {
        guard let result = intersection(other) else {
            preconditionFailure("TimeSpans do not intersect")
        }
        return result
    }

    public func midpoint() -> Fraction {
        begin.add(duration.div(Fraction(2, 1)))
    }

    public func show() -> String { "\(begin.show()) → \(end.show())" }
}

extension TimeSpan: CustomStringConvertible {
    public var description: String { show() }
}
