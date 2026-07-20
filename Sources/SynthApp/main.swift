import AppKit
import SwiftUI

// Entry point for the macOS GUI app.
//
// `SYNTH_SCREENSHOT=/path.png` renders the shell to a PNG and exits — used to
// produce the README header deterministically (no screen-capture permissions).

if let path = ProcessInfo.processInfo.environment["SYNTH_SCREENSHOT"] {
    MainActor.assumeIsolated {
        ScreenshotRenderer.render(to: path)
    }
    exit(0)
}

NSApplication.shared.setActivationPolicy(.regular)
SynthApplication.main()
