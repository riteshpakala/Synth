// AppModel.swift — GUI state: the DSL pad, its tunables, playback, settings.

import Foundation
import Strudel
import SwiftUI

enum Screen: String, CaseIterable, Identifiable {
    case player = "Player"
    case settings = "Settings"

    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .player: return "play.circle"
        case .settings: return "slider.horizontal.3"
        }
    }
}

/// A ready-to-load example snippet for the pad.
struct ExampleSnippet: Identifiable {
    let id: String
    let code: String
}

@MainActor
final class AppModel: ObservableObject {
    @Published var screen: Screen = .player

    // MARK: Player state

    /// The DSL source in the pad.
    @Published var code: String = AppModel.examples[0].code {
        didSet { codeChanged() }
    }
    /// Sliders derived from the code's numeric literals.
    @Published var tunables: [Tunable] = []
    @Published var parseError: String? = nil
    @Published var isPlaying = false
    /// Cycles per minute (the strudel-native tempo unit).
    @Published var cpm: Double = 30

    // MARK: Settings state

    @Published var masterVolume: Double = 0.9 {
        didSet { player.volume = masterVolume }
    }
    @Published var preciseRNG = false {
        didSet { useRNG(preciseRNG ? .precise : .legacy) }
    }
    @Published var sampleFolder: String? = nil
    @Published var soundNames: [String] = []

    /// Set when rendering the README screenshot (SYNTH_SCREENSHOT).
    let isScreenshot = ProcessInfo.processInfo.environment["SYNTH_SCREENSHOT"] != nil

    private let player = StrudelPlayer()
    private var evalTask: Task<Void, Never>? = nil
    /// Suppresses the debounce when a slider (not typing) rewrote the code.
    private var applyingTunable = false

    static let examples: [ExampleSnippet] = [
        ExampleSnippet(id: "Acid line", code: """
        note("c2 [c2 eb2]*2 g1 <bb1 c2>")
          .s("sawtooth")
          .lpf(700).lpenv(3)
          .cubic(1.2)
          .room(0.3)
          .every(4) { $0.rev() }
        """),
        ExampleSnippet(id: "Noise groove", code: """
        stack(
          s("z_triangle*4").note("c1").decay(0.18),
          s("white*8").decay(0.05).gain(0.5).pan(sine),
          s("pink").euclid(3, 8).decay(0.1)
        ).room(0.2)
        """),
        ExampleSnippet(id: "Piano chords", code: """
        mini("<C^7 A7 Dm7 G7>")
          .voicings()
          .note()
          .s("steinway")
          .slow(2)
          .room(0.4)
        """),
    ]

    init() {
        installMiniNotation()
        soundNames = SoundRegistry.shared.names
        tunables = PatternScript.tunables(in: code)
        player.volume = masterVolume
        if isScreenshot {
            // The capture should read as "live": transport on, loop running.
            isPlaying = true
        }
    }

    // MARK: Evaluation pipeline

    /// The pad's pattern; throws with a message for the error line.
    private func currentPattern() throws -> StrudelCore.Pattern {
        try PatternScript.evaluate(code)
    }

    /// Called on every code change: refresh sliders immediately; re-evaluate
    /// (debounced when typing, instant from a slider) if playing.
    private func codeChanged() {
        tunables = PatternScript.tunables(in: code)
        let immediate = applyingTunable
        evalTask?.cancel()
        evalTask = Task { [weak self] in
            if !immediate {
                try? await Task.sleep(nanoseconds: 400_000_000)
            }
            guard !Task.isCancelled else { return }
            self?.applyEdits()
        }
    }

    /// Re-evaluates the pad and hot-swaps the running pattern.
    private func applyEdits() {
        do {
            let pattern = try currentPattern()
            parseError = nil
            if isPlaying {
                player.setPattern(pattern)
            }
        } catch let error as PatternScriptError {
            parseError = error.message
        } catch {
            parseError = error.localizedDescription
        }
    }

    func togglePlayback() {
        if isPlaying {
            player.hush()
            isPlaying = false
        } else {
            do {
                let pattern = try currentPattern()
                parseError = nil
                try player.play(pattern, cps: cpm / 60)
                isPlaying = true
            } catch let error as PatternScriptError {
                parseError = error.message
            } catch {
                parseError = error.localizedDescription
            }
        }
    }

    func tempoChanged() {
        player.setCps(cpm / 60)
    }

    /// A slider moved: rewrite the literal in the code and hot-swap instantly.
    func setTunable(_ tunable: Tunable, to newValue: Double) {
        let value = tunable.integer ? newValue.rounded() : newValue
        applyingTunable = true
        code = PatternScript.replacing(tunable, with: value, in: code)
        applyingTunable = false
    }

    func loadExample(_ example: ExampleSnippet) {
        code = example.code
    }

    // MARK: Settings actions

    func loadSampleFolder() {
        guard let url = FolderPicker.pickFolder() else { return }
        try? SampleLoader.loadDirectory(url)
        sampleFolder = url.path
        soundNames = SoundRegistry.shared.names
    }

    /// Click-to-preview a sound from the registry list.
    func preview(sound: String) {
        player.playOnce(.map(["note": .string("c3"), "s": .string(sound)]))
    }
}
