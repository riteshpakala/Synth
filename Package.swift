// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Synth",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        // The Strudel engine, ported from https://codeberg.org/uzu/strudel (AGPL-3.0).
        .library(name: "Strudel", targets: ["Strudel"]),
        // The terminal tool: `swift run synth-cli` (or `./run-cli.sh`).
        .executable(name: "synth-cli", targets: ["SynthCLI"]),
        // The macOS GUI app: `swift run synth-app` (or `./run-app.sh`).
        .executable(name: "synth-app", targets: ["SynthApp"]),
    ],
    targets: [
        // Pattern engine: Fraction, TimeSpan, Hap, Pattern + combinators, signals, controls.
        .target(name: "StrudelCore"),
        // Mini-notation parser ("c3 [e3 g3]*2 <a3 b3>").
        .target(name: "StrudelMini", dependencies: ["StrudelCore"]),
        // Notes, scales, chords, voicings.
        .target(name: "StrudelTonal", dependencies: ["StrudelCore"]),
        // Scheduler + sounds + DSP output (superdough equivalent on AVAudioEngine).
        .target(name: "StrudelAudio", dependencies: ["StrudelCore", "StrudelMini", "StrudelTonal"]),
        // Umbrella module re-exporting everything above.
        .target(name: "Strudel", dependencies: ["StrudelCore", "StrudelMini", "StrudelTonal", "StrudelAudio"]),
        .executableTarget(name: "SynthCLI", dependencies: ["Strudel"]),
        .executableTarget(name: "SynthApp", dependencies: ["Strudel"]),
        .testTarget(name: "StrudelCoreTests", dependencies: ["StrudelCore", "StrudelMini"]),
        .testTarget(name: "StrudelMiniTests", dependencies: ["StrudelMini", "StrudelCore"],
                    resources: [.copy("Fixtures")]),
        .testTarget(name: "StrudelTonalTests", dependencies: ["StrudelTonal", "StrudelCore", "StrudelMini"]),
        .testTarget(name: "StrudelAudioTests", dependencies: ["StrudelAudio", "StrudelCore", "StrudelMini"]),
        .testTarget(name: "StrudelScriptTests", dependencies: ["Strudel", "StrudelAudio"]),
    ]
)
