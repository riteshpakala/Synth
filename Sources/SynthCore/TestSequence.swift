import Foundation

// =============================================================================
//  ★ EDIT ME ★
//
//  This is the shared sequence played by BOTH the CLI tool (`synth-cli`) and
//  the GUI app (`synth-app`). Change the notes below, then either run
//  `./run-cli.sh` in the terminal to hear it, or hit "Play Test Sequence" in
//  the app. This is your iteration loop toward the manual vocal synth.
// =============================================================================

extension Pattern {
    /// The sequence under test. Shared by the CLI and GUI so there is exactly
    /// one place to edit while you iterate.
    ///
    /// Right now: Kanye West — "Runaway" main piano line, from the guitar tab.
    /// Each cycle is three high notes answered by a lower one, descending
    /// E → D# → C#, then A A G# E, looped `(x15)`, played on the Steinway grand.
    /// Tune the tempo, the repeat count, or swap `voice` for another sound.
    ///
    ///   e|--12-12-12----11-11-11----9-9-9----5-5-4-12--|
    ///   G|-----------9-----------8--------6------------|  (x15)
    public static var test: Pattern {
        return Pattern(tempo: 80, voice: .steinwayGrand) {
            // e: 12 12 12   →   G: 9   (E5 ×3, then E4)
            Note("E5", .eighth)
            Note("E5", .eighth)
            Note("E5", .eighth)
            Note("E4", .quarter)

            // e: 11 11 11   →   G: 8   (D#5 ×3, then D#4)
            Note("D#5", .eighth)
            Note("D#5", .eighth)
            Note("D#5", .eighth)
            Note("D#4", .quarter)

            // e: 9 9 9      →   G: 6   (C#5 ×3, then C#4)
            Note("C#5", .eighth)
            Note("C#5", .eighth)
            Note("C#5", .eighth)
            Note("C#4", .quarter)

            // e: 5 5 4 12   (A4, A4, G#4, then back up to E5)
            Note("A4", .eighth)
            Note("A4", .eighth)
            Note("G#4", .eighth)
            Note("E5", .quarter)
        }
    }
}
