import Foundation
import SwiftUI
import SynthCore

/// Holds GUI state and drives the shared `SequencePlayer`.
@MainActor
final class AppModel: ObservableObject {
    @Published var waveform: Waveform = .voice
    @Published var tempo: Double = 120
    @Published var lastPlayed: String = "—"

    private let player = SequencePlayer()

    /// Plays the shared `Pattern.test` sequence — the same one the CLI plays.
    func playTestSequence() {
        lastPlayed = "test sequence"
        submit(SynthCore.Pattern.test)
    }

    /// Plays a single key with the currently selected waveform and tempo.
    func play(key: PianoKey) {
        lastPlayed = key.name
        submit(SynthCore.Pattern.single(key, value: .quarter, tempo: tempo, waveform: waveform))
    }

    // `Pattern` is qualified because AppKit re-exports a C `struct Pattern`
    // (Quickdraw) that would otherwise be ambiguous in this target.
    private func submit(_ pattern: SynthCore.Pattern) {
        do {
            try player.play(pattern)
        } catch {
            lastPlayed = "audio error: \(error.localizedDescription)"
        }
    }
}
