// =============================================================================
//  ★ EDIT ME ★
//
//  This is the shared pattern played by BOTH the CLI tool (`synth-cli`) and
//  the GUI app (`synth-app`). Edit the pattern below, then run `./run-cli.sh`
//  to hear it, or hit Play in the app. This is your iteration loop.
//
//  Patterns are strudel patterns (https://strudel.cc): double-quoted strings
//  are mini-notation, and the chained functions are the ported combinators.
//  Try things like:
//
//      note("c3 [e3 g3]*2 <a3 b3>").s("sawtooth").lpf(800)
//      n("0 2 4 <6 7>").scale("C:minor").s("triangle").room(0.3)
//      s("white*8").decay(0.05).sustain(0).degradeBy(0.3)
//      note("c2 e2").s("sawtooth").vowel("<a e i o>")   // the vocal seam
// =============================================================================

import Foundation
import StrudelCore
import StrudelMini

/// The pattern under test — Kanye West's "Runaway" main piano line.
/// Each cycle: three high notes answered by a lower one, descending
/// E → D# → C#, then A A G# E, on the additive Steinway grand.
///
///   e|--12-12-12----11-11-11----9-9-9----5-5-4-12--|
///   G|-----------9-----------8--------6------------|
public func testPattern() -> Pattern {
    installMiniNotation()
    return note("[e5!3 e4@2] [d#5!3 d#4@2] [c#5!3 c#4@2] [a4 a4 g#4 e5@2]")
        .s("steinway")
}

/// Cycles per second for the test pattern (8 cycles per minute — the original
/// 80 BPM feel).
public let testCps = 8.0 / 60.0
