// ContentView.swift — the two-screen shell: sidebar (Player / Settings) +
// detail, in the warm Synth design language.

import SwiftUI

struct ContentView: View {
    @StateObject private var model = AppModel()

    var body: some View {
        HStack(spacing: 0) {
            sidebar
                .frame(width: 220)
            Divider().overlay(Color.synthBorder)
            detail
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.synthBG)
        }
        .environmentObject(model)
        .preferredColorScheme(.light)  // the palette is light-only
        .frame(minWidth: 1080, minHeight: 700)
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 10) {
                SynthMark(size: 22)
                VStack(alignment: .leading, spacing: 0) {
                    Text("Synth")
                        .font(.synthSerif(20, weight: .light, italic: true))
                        .foregroundStyle(Color.synthInk)
                    Text("pattern engine")
                        .font(.synthSans(9, weight: .medium))
                        .foregroundStyle(Color.synthInk.opacity(0.4))
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 18)

            ForEach(Screen.allCases) { screen in
                Button {
                    model.screen = screen
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: screen.symbol)
                            .frame(width: 18)
                            .foregroundStyle(model.screen == screen ? Color.synthGold : Color.synthInk.opacity(0.6))
                        Text(screen.rawValue)
                            .font(.synthSans(13, weight: model.screen == screen ? .semibold : .regular))
                            .foregroundStyle(Color.synthInk)
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(model.screen == screen ? Color.synthGold.opacity(0.12) : .clear)
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 8)
            }

            Spacer()

            Text("a Swift port of strudel.cc")
                .font(.synthMono(8.5))
                .foregroundStyle(Color.synthInk.opacity(0.3))
                .padding(12)
        }
        .background(Color.synthBG)
    }

    @ViewBuilder
    private var detail: some View {
        switch model.screen {
        case .player: PlayerView()
        case .settings: SettingsView()
        }
    }
}

#Preview {
    ContentView()
}
