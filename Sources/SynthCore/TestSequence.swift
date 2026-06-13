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
    public static var test: Pattern {
        Pattern(tempo: 120, waveform: .voice) {
            Note("C4", .quarter)
            Note("D4", .quarter)
            Note("E4", .quarter)
            Note("G4", .quarter)

            Rest(.eighth)

            Chord(["C4", "E4", "G4"], .half)

            Note("A4", .eighth)
            Note("G4", .eighth)
            Note("E4", .quarter)
            Note("C4", .half, waveform: .sine)
        }
    }
}
