import SwiftUI

/// The SwiftUI application shell. Declared without `@main` so the entry point
/// can live in `main.swift` (a file named `main.swift` can't also be `@main`).
struct SynthApplication: App {
    var body: some Scene {
        WindowGroup("Synth") {
            ContentView()
        }
        .defaultSize(width: 1180, height: 760)
    }
}
