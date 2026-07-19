import Foundation
import Strudel
import SwiftUI

/// Holds GUI state and drives the shared `StrudelPlayer`.
@MainActor
final class AppModel: ObservableObject {
    @Published var soundName: String = "steinway"
    /// Cycles per minute (the strudel-native tempo unit).
    @Published var cpm: Double = testCps * 60
    @Published var lastPlayed: String = "—"
    @Published var isPlaying = false
    /// Live-editable mini-notation; empty means "play the test pattern".
    @Published var miniCode: String = ""
    @Published var parseError: String? = nil

    private let player = StrudelPlayer()

    var availableSounds: [String] { SoundRegistry.shared.names }

    init() {
        installMiniNotation()
    }

    /// The pattern to play: the mini code if present, else the test pattern.
    private func currentPattern() -> StrudelCore.Pattern {
        guard !miniCode.trimmingCharacters(in: .whitespaces).isEmpty else {
            return testPattern()
        }
        return note(.string(miniCode)).s(.string(soundName))
    }

    /// Starts/stops looping playback of the current pattern.
    func togglePlayback() {
        if isPlaying {
            player.hush()
            isPlaying = false
            lastPlayed = "stopped"
        } else {
            do {
                try player.play(currentPattern(), cps: cpm / 60)
                isPlaying = true
                lastPlayed = miniCode.isEmpty ? "test pattern" : "live pattern"
            } catch {
                lastPlayed = "audio error: \(error.localizedDescription)"
            }
        }
    }

    /// Applies edits to the running pattern without stopping the clock —
    /// mini-notation is runtime-parsed, so this is live-codable.
    func applyLiveEdits() {
        parseError = nil
        guard isPlaying else { return }
        player.setPattern(currentPattern())
        player.setCps(cpm / 60)
        lastPlayed = "updated"
    }

    /// Plays a single key with the currently selected sound.
    func play(key: PianoKey) {
        lastPlayed = key.name
        player.playOnce(.map([
            "note": .number(Double(key.midiNoteNumber)),
            "s": .string(soundName),
        ]))
    }
}
