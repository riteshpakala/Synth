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

/// A ready-to-load example snippet for the pad, with its intended tempo.
struct ExampleSnippet: Identifiable {
    let id: String
    let code: String
    let bpm: Double
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
    /// Beats per minute, shown on the transport. Cycles are strudel's native
    /// unit; we use its `setcpm(bpm/4)` convention: 4 beats per cycle.
    @Published var bpm: Double = 120

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
        """, bpm: 120),
        ExampleSnippet(id: "Runaway", code: """
        // Kanye West — "Runaway", the solo piano line
        note("<[e5!3 e4@2] [d#5!3 d#4@2] [c#5!3 c#4@2] [a4 a4 g#4 e5@2]>")
          .s("steinway")
          .room(0.2)
        """, bpm: 128),
        ExampleSnippet(id: "Noise groove", code: """
        stack(
          s("z_triangle*4").note("c1").decay(0.18),
          s("white*8").decay(0.05).gain(0.5).pan(sine),
          s("pink").euclid(3, 8).decay(0.1)
        ).room(0.2)
        """, bpm: 140),
        ExampleSnippet(id: "Viva La Vida", code: """
        // Coldplay — "Viva La Vida" (instrumental arrangement)
        // one bar per cycle; Db–Eb–Ab–Fm at 138 bpm
        arrange(
          [8, stack(
            note("<[db4,f4,ab4]*8 [eb4,g4,bb4]*8 [ab3,c4,eb4]*8 [f3,ab3,c4]*8>")
              .s("sawtooth").lpf(2000).decay(0.16).sustain(0.2).gain(0.4).room(0.25),
            note("<db2 eb2 ab1 f2>").s("sawtooth").lpf(500).gain(0.7),
            s("z_sine*4").note("c1").decay(0.15),
            s("white*8").decay(0.03).gain(0.22)
          )],
          [8, stack(
            note("<[db4,f4,ab4]*8 [eb4,g4,bb4]*8 [ab3,c4,eb4]*8 [f3,ab3,c4]*8>")
              .s("sawtooth").lpf(3200).decay(0.16).sustain(0.25).gain(0.45).room(0.3),
            note("<[c5 db5 c5 ab4] [bb4 c5 bb4 g4] [ab4 bb4 c5 eb5] [f4 ab4 c5 ab4]>")
              .s("triangle").vib(5).release(0.15).gain(0.65).room(0.4).delay(0.2),
            note("<db2 eb2 ab1 f2>").s("sawtooth").lpf(600).gain(0.7),
            s("z_sine*4").note("c1").decay(0.15),
            s("[~ pink]*2").decay(0.07).gain(0.5),
            s("white*8").decay(0.03).gain(0.25)
          )]
        )
        """, bpm: 138),
        ExampleSnippet(id: "Piano chords", code: """
        mini("<C^7 A7 Dm7 G7>")
          .voicings()
          .note()
          .s("steinway")
          .slow(2)
          .room(0.4)
        """, bpm: 90),
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
                try player.play(pattern, cps: bpm / 240)
                isPlaying = true
            } catch let error as PatternScriptError {
                parseError = error.message
            } catch {
                parseError = error.localizedDescription
            }
        }
    }

    func tempoChanged() {
        player.setCps(bpm / 240)
    }

    /// A slider moved: rewrite the literal in the code and hot-swap instantly.
    ///
    /// The slider's captured Tunable can be stale mid-drag (each rewrite
    /// shifts source offsets), so the literal is re-located by its stable id
    /// against the *current* code, and the rewrite only commits if the result
    /// still parses — a slider can never corrupt the pad.
    func setTunable(_ tunable: Tunable, to newValue: Double) {
        guard let fresh = PatternScript.tunables(in: code).first(where: { $0.id == tunable.id }) else {
            return
        }
        let value = fresh.integer ? newValue.rounded() : newValue
        let updated = PatternScript.replacing(fresh, with: value, in: code)
        guard !PatternScript.tunables(in: updated).isEmpty else { return }
        applyingTunable = true
        code = updated
        applyingTunable = false
    }

    func loadExample(_ example: ExampleSnippet) {
        code = example.code
        bpm = example.bpm
        tempoChanged()
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
