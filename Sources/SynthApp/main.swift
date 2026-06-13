import AppKit

// Entry point for the macOS GUI app.
//
// The `App` lives in `SynthApplication.swift`; this file just launches it, so
// both executables keep a small, parallel `main.swift`.
NSApplication.shared.setActivationPolicy(.regular)
SynthApplication.main()
