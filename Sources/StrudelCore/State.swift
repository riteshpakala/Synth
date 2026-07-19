// State.swift — the input to a pattern query: a timespan plus controls.
// Ported from Strudel <https://codeberg.org/uzu/strudel> (packages/core/state.mjs)
// — AGPL-3.0-or-later.

import Foundation

public struct State: @unchecked Sendable {
    public let span: TimeSpan
    public let controls: ControlMap

    public init(span: TimeSpan, controls: ControlMap = [:]) {
        self.span = span
        self.controls = controls
    }

    public func setSpan(_ span: TimeSpan) -> State {
        State(span: span, controls: controls)
    }

    public func withSpan(_ f: (TimeSpan) -> TimeSpan) -> State {
        setSpan(f(span))
    }

    public func setControls(_ new: ControlMap) -> State {
        State(span: span, controls: controls.merging(new) { _, b in b })
    }
}
