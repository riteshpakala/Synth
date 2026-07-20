// Design.swift — the Synth design language, following the Fleet/Seer system:
// a warm paper background, ink text, gold accents, serif display type.

import SwiftUI

// MARK: - Palette

extension Color {
    static let synthBG = Color(red: 250 / 255, green: 249 / 255, blue: 246 / 255)
    static let synthInk = Color(red: 45 / 255, green: 49 / 255, blue: 66 / 255)
    static let synthGold = Color(red: 174 / 255, green: 144 / 255, blue: 96 / 255)
    static var synthBorder: Color { Color.synthGold.opacity(0.22) }
    static var synthCard: Color { Color.white.opacity(0.62) }
    static var synthFill: Color { Color.synthInk.opacity(0.05) }
    static let synthError = Color(red: 200 / 255, green: 60 / 255, blue: 60 / 255)
    static let synthGreen = Color(red: 70 / 255, green: 150 / 255, blue: 90 / 255)
    static let synthLabel = Color(red: 12 / 255, green: 12 / 255, blue: 12 / 255)
}

// MARK: - Typography

extension Font {
    static func synthSerif(_ size: CGFloat, weight: Font.Weight = .regular, italic: Bool = false) -> Font {
        let f = Font.system(size: size, weight: weight, design: .serif)
        return italic ? f.italic() : f
    }

    static func synthSans(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight)
    }

    static func synthMono(_ size: CGFloat) -> Font {
        .system(size: size, design: .monospaced)
    }
}

// MARK: - Synth mark

/// The Synth brand glyph — a gold waveform on the warm design system.
struct SynthMark: View {
    var size: CGFloat = 28
    var color: Color = .synthGold

    var body: some View {
        Image(systemName: "waveform")
            .font(.system(size: size, weight: .light))
            .foregroundStyle(color)
            .symbolRenderingMode(.hierarchical)
    }
}

// MARK: - Orbiting rings

struct SynthOrbitRings: View {
    let iconSize: CGFloat
    @State private var outerRotation = 0.0
    @State private var innerRotation = 0.0

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(
                    Color.synthGold.opacity(0.30),
                    style: StrokeStyle(lineWidth: 1, dash: [5, 3])
                )
                .frame(width: iconSize + 40, height: iconSize + 40)
                .rotationEffect(.degrees(outerRotation))
                .onAppear {
                    withAnimation(.linear(duration: 32).repeatForever(autoreverses: false)) {
                        outerRotation = -360
                    }
                }

            Circle()
                .strokeBorder(Color.synthGold.opacity(0.30), lineWidth: 1)
                .frame(width: iconSize + 14, height: iconSize + 14)
                .rotationEffect(.degrees(innerRotation))
                .onAppear {
                    withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                        innerRotation = 360
                    }
                }

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.synthGold.opacity(0.15), .clear],
                        center: .center, startRadius: 0, endRadius: iconSize * 0.6
                    )
                )
                .frame(width: iconSize + 8, height: iconSize + 8)
        }
        .frame(width: iconSize + 48, height: iconSize + 48)
    }
}

/// The mark inside the orbiting rings — used on empty states.
struct SynthEmblem: View {
    var iconSize: CGFloat = 64

    var body: some View {
        ZStack {
            SynthOrbitRings(iconSize: iconSize)
            SynthMark(size: iconSize * 0.7)
        }
    }
}
