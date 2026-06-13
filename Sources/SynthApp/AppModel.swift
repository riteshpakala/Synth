import Foundation
import SwiftUI
import SynthCore

/// Holds GUI state and drives the shared `SequencePlayer`.
@MainActor
final class AppModel: ObservableObject {
    /// Selected sound, tracked by name so the SwiftUI `Picker` has a `Hashable`
    /// value to bind to (existentials aren't directly bindable).
    @Published var voiceName: String = VoiceLibrary.default.name
    @Published var tempo: Double = 120
    @Published var lastPlayed: String = "—"

    private let player = SequencePlayer()

    /// The currently selected voice.
    var voice: any Voice {
        VoiceLibrary.all.first { $0.name == voiceName } ?? VoiceLibrary.default
    }

    /// Plays the shared `Pattern.test` sequence — the same one the CLI plays.
    func playTestSequence() {
        lastPlayed = "test sequence"
        submit(SynthCore.Pattern.test)
    }

    /// Plays a single key with the currently selected voice and tempo.
    func play(key: PianoKey) {
        lastPlayed = key.name
        submit(SynthCore.Pattern.single(key, value: .quarter, tempo: tempo, voice: voice))
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
