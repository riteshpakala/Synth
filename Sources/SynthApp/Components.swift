// Components.swift — shared building blocks in the warm design language.

import AppKit
import SwiftUI

/// A floating card surface.
struct SynthCard<Content: View>: View {
    var padding: CGFloat = 18
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.synthCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .strokeBorder(Color.synthBorder, lineWidth: 1))
            )
            .shadow(color: Color.synthInk.opacity(0.06), radius: 5, y: 2)
    }
}

/// Small uppercase section label.
struct SectionLabel: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text.uppercased())
            .font(.synthSans(10, weight: .semibold))
            .tracking(0.8)
            .foregroundStyle(Color.synthInk.opacity(0.45))
    }
}

/// Gold primary-action button style.
struct SynthButtonStyle: ButtonStyle {
    var prominent: Bool = true
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.synthSans(13, weight: .medium))
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .foregroundStyle(prominent ? Color.white : Color.synthInk)
            .background(
                RoundedRectangle(cornerRadius: 9)
                    .fill(prominent ? Color.synthGold : Color.synthFill)
                    .opacity(configuration.isPressed ? 0.8 : 1)
            )
            .shadow(
                color: prominent ? Color.synthGold.opacity(0.30) : .clear,
                radius: 4, y: 2)
    }
}

extension ButtonStyle where Self == SynthButtonStyle {
    static var synth: SynthButtonStyle { SynthButtonStyle(prominent: true) }
    static var synthQuiet: SynthButtonStyle { SynthButtonStyle(prominent: false) }
}

/// Colored status dot.
struct StatusDot: View {
    let color: Color
    var body: some View {
        Circle().fill(color).frame(width: 8, height: 8)
    }
}

/// Open a folder picker and return the chosen directory.
enum FolderPicker {
    static func pickFolder() -> URL? {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        return panel.runModal() == .OK ? panel.urls.first : nil
    }
}

/// A pure-SwiftUI slider in the gold design language (also renders correctly
/// under ImageRenderer, unlike the AppKit-backed stock Slider).
struct GoldSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    var step: Double? = nil

    private func fraction(_ v: Double) -> Double {
        let span = range.upperBound - range.lowerBound
        guard span > 0 else { return 0 }
        return min(max((v - range.lowerBound) / span, 0), 1)
    }

    var body: some View {
        GeometryReader { geo in
            let f = fraction(value)
            let knobX = f * (geo.size.width - 14)
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.synthInk.opacity(0.10))
                    .frame(height: 4)
                Capsule()
                    .fill(Color.synthGold.opacity(0.55))
                    .frame(width: max(knobX + 7, 7), height: 4)
                Circle()
                    .fill(Color.white)
                    .overlay(Circle().strokeBorder(Color.synthGold, lineWidth: 1.5))
                    .shadow(color: Color.synthInk.opacity(0.15), radius: 1.5, y: 1)
                    .frame(width: 14, height: 14)
                    .offset(x: knobX)
            }
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        let span = range.upperBound - range.lowerBound
                        let raw = range.lowerBound
                            + span * min(max(drag.location.x / max(geo.size.width - 14, 1), 0), 1)
                        if let step, step > 0 {
                            value = min(max((raw / step).rounded() * step,
                                            range.lowerBound), range.upperBound)
                        } else {
                            value = raw
                        }
                    }
            )
        }
        .frame(height: 18)
    }
}
