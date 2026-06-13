// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Synth",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        // Shared synthesis engine used by both the CLI and the GUI.
        .library(name: "SynthCore", targets: ["SynthCore"]),
        // The terminal tool: `swift run synth-cli` (or `./run-cli.sh`).
        .executable(name: "synth-cli", targets: ["SynthCLI"]),
        // The macOS GUI app: `swift run synth-app` (or `./run-app.sh`).
        .executable(name: "synth-app", targets: ["SynthApp"]),
    ],
    targets: [
        .target(name: "SynthCore"),
        .executableTarget(
            name: "SynthCLI",
            dependencies: ["SynthCore"]
        ),
        .executableTarget(
            name: "SynthApp",
            dependencies: ["SynthCore"]
        ),
    ]
)
