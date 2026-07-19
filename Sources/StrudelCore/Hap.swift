// Hap.swift — a pattern event ("hap" — 'Event' being reserved in JS was the
// original naming reason; kept for fidelity with Tidal/Strudel).
// Ported from Strudel <https://codeberg.org/uzu/strudel> (packages/core/hap.mjs)
// — AGPL-3.0-or-later.

import Foundation

/// Trigger callback attached via `.onTrigger()`: (hap, deadline, duration, cps, targetTime).
public typealias HapTrigger = @Sendable (Hap, Double, Double, Double, Double) -> Void

/// Side-band metadata carried by a hap (source tags, color, custom triggers).
public struct HapContext: @unchecked Sendable {
    public var tags: [String]?
    public var color: String?
    public var scale: String?
    public var onTrigger: HapTrigger?
    public var dominantTrigger: Bool?

    public init(tags: [String]? = nil, color: String? = nil, scale: String? = nil,
                onTrigger: HapTrigger? = nil, dominantTrigger: Bool? = nil) {
        self.tags = tags
        self.color = color
        self.scale = scale
        self.onTrigger = onTrigger
        self.dominantTrigger = dominantTrigger
    }

    /// JS `{ ...a, ...b }` semantics: b's fields win when present.
    public func merging(_ b: HapContext) -> HapContext {
        HapContext(
            tags: b.tags ?? tags,
            color: b.color ?? color,
            scale: b.scale ?? scale,
            onTrigger: b.onTrigger ?? onTrigger,
            dominantTrigger: b.dominantTrigger ?? dominantTrigger
        )
    }
}

/// A value active during the timespan `part`. This might be a fragment of an
/// event, in which case `part` is smaller than the `whole` timespan, otherwise
/// the two are the same. `part` never extends outside `whole`. A continuously
/// changing value (signal) has no `whole`; its value was sampled at the
/// midpoint of `part`.
public struct Hap: @unchecked Sendable {
    public let whole: TimeSpan?
    public let part: TimeSpan
    public let value: PatternValue
    public let context: HapContext

    public init(whole: TimeSpan?, part: TimeSpan, value: PatternValue,
                context: HapContext = HapContext()) {
        self.whole = whole
        self.part = part
        self.value = value
        self.context = context
    }

    /// Event duration; a `duration` control overrides the whole's length, and a
    /// `clip` control scales it.
    public var duration: Fraction {
        var dur: Fraction
        if case .map(let m) = value, let d = m["duration"]?.fractionValue {
            dur = d
        } else if let whole {
            dur = whole.end.sub(whole.begin)
        } else {
            dur = part.end.sub(part.begin)
        }
        if case .map(let m) = value, let clip = m["clip"]?.fractionValue {
            return dur.mul(clip)
        }
        return dur
    }

    public var endClipped: Fraction {
        (whole?.begin ?? part.begin).add(duration)
    }

    public func isActive(currentTime: Fraction) -> Bool {
        guard let whole else { return false }
        return whole.begin <= currentTime && endClipped >= currentTime
    }

    public func isInPast(currentTime: Fraction) -> Bool {
        currentTime > endClipped
    }

    public func isInFuture(currentTime: Fraction) -> Bool {
        guard let whole else { return false }
        return currentTime < whole.begin
    }

    public func wholeOrPart() -> TimeSpan { whole ?? part }

    /// Whether the hap contains its onset (the beginning of the part coincides
    /// with the beginning of the whole).
    public func hasOnset() -> Bool {
        guard let whole else { return false }
        return whole.begin == part.begin
    }

    public func hasTag(_ tag: String) -> Bool {
        context.tags?.contains(tag) ?? false
    }

    public func withSpan(_ f: (TimeSpan) -> TimeSpan) -> Hap {
        Hap(whole: whole.map(f), part: f(part), value: value, context: context)
    }

    public func withValue(_ f: (PatternValue) -> PatternValue) -> Hap {
        Hap(whole: whole, part: part, value: f(value), context: context)
    }

    public func setContext(_ context: HapContext) -> Hap {
        Hap(whole: whole, part: part, value: value, context: context)
    }

    public func combineContext(_ b: Hap) -> HapContext {
        context.merging(b.context)
    }

    public func spanEquals(_ other: Hap) -> Bool {
        (whole == nil && other.whole == nil) || whole == other.whole
    }

    public func equals(_ other: Hap) -> Bool {
        spanEquals(other) && part == other.part && value == other.value
    }

    public func show(compact: Bool = false) -> String {
        var spans = ""
        if let whole {
            let isWhole = whole.begin == part.begin && whole.end == part.end
            if whole.begin != part.begin { spans = whole.begin.show() + " ⇜ " }
            if !isWhole { spans += "(" }
            spans += part.show()
            if !isWhole { spans += ")" }
            if whole.end != part.end { spans += " ⇝ " + whole.end.show() }
        } else {
            spans = "~" + part.show()
        }
        return "[ \(spans) | \(value) ]"
    }
}

extension Hap: CustomStringConvertible {
    public var description: String { show() }
}
