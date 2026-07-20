// ScreenshotRenderer.swift — renders the app shell to a PNG for the README.
// Runs on the main thread without showing a window (ImageRenderer), with the
// player state pre-seeded so tunables and transport read as "live".

import AppKit
import SwiftUI

enum ScreenshotRenderer {
    @MainActor
    static func render(to path: String) {
        let view = ContentView()
            .frame(width: 1180, height: 760)
            .background(Color.synthBG)

        let renderer = ImageRenderer(content: view)
        renderer.scale = 2

        guard let image = renderer.nsImage,
              let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:]) else {
            FileHandle.standardError.write(Data("screenshot: render failed\n".utf8))
            exit(1)
        }
        let url = URL(fileURLWithPath: path)
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                                 withIntermediateDirectories: true)
        do {
            try png.write(to: url)
            print("screenshot written to \(path)")
        } catch {
            FileHandle.standardError.write(Data("screenshot: \(error)\n".utf8))
            exit(1)
        }
    }
}
