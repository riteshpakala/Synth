// PlayerView.swift — the live-coding pad: DSL code, auto-generated tunable
// sliders, and transport. Numbers in the code become sliders; both modulate
// the running loop in realtime.

import Strudel
import SwiftUI

struct PlayerView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header

            if !model.tunables.isEmpty {
                tunablesCard
            }

            codeCard

            transport

            Spacer(minLength: 0)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Player")
                .font(.synthSerif(26, weight: .light, italic: true))
                .foregroundStyle(Color.synthInk)
            Text("Write pattern code, loop it forever, and tune it live — every number becomes a slider.")
                .font(.synthSans(12))
                .foregroundStyle(Color.synthInk.opacity(0.5))
        }
    }

    // MARK: Tunables

    private var tunablesCard: some View {
        SynthCard(padding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                SectionLabel("Tunables")
                // Dense patterns can produce more sliders than fit — the grid
                // scrolls within the card so everything stays reachable.
                // (ImageRenderer can't rasterize NSScrollView; the README
                // capture renders the bare grid.)
                if model.isScreenshot {
                    tunablesGrid
                } else {
                    ScrollView {
                        tunablesGrid
                    }
                    .frame(maxHeight: 236)
                }
            }
        }
    }

    private var tunablesGrid: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 210), spacing: 14)],
            alignment: .leading, spacing: 12
        ) {
            ForEach(model.tunables) { tunable in
                TunableSlider(tunable: tunable) { newValue in
                    model.setTunable(tunable, to: newValue)
                }
            }
        }
    }

    // MARK: Code pad

    private var codeCard: some View {
        SynthCard(padding: 16) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    SectionLabel("Pattern")
                    Spacer()
                    if model.isScreenshot {
                        Label("Examples", systemImage: "text.badge.plus")
                            .font(.synthSans(11, weight: .medium))
                            .foregroundStyle(Color.synthInk.opacity(0.6))
                    } else {
                        Menu {
                            ForEach(AppModel.examples) { example in
                                Button(example.id) { model.loadExample(example) }
                            }
                        } label: {
                            Label("Examples", systemImage: "text.badge.plus")
                                .font(.synthSans(11, weight: .medium))
                        }
                        .menuStyle(.borderlessButton)
                        .frame(width: 110)
                        .foregroundStyle(Color.synthInk.opacity(0.6))
                    }
                }

                Group {
                    if model.isScreenshot {
                        // ImageRenderer can't rasterize NSTextView; show a
                        // faithful static stand-in for the README capture.
                        Text(model.code)
                            .font(.synthMono(13))
                            .foregroundStyle(Color.synthLabel)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                    } else {
                        TextEditor(text: $model.code)
                            .font(.synthMono(13))
                            .foregroundStyle(Color.synthLabel)
                            .scrollContentBackground(.hidden)
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, minHeight: 180, maxHeight: 260, alignment: .topLeading)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.synthFill))

                if let error = model.parseError {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 10))
                        Text(error)
                            .font(.synthMono(10.5))
                            .lineLimit(2)
                    }
                    .foregroundStyle(Color.synthError)
                } else {
                    Text("Edits apply live — the loop hot-swaps on the next tick.")
                        .font(.synthSans(10))
                        .foregroundStyle(Color.synthInk.opacity(0.35))
                }
            }
        }
    }

    // MARK: Transport

    private var transport: some View {
        SynthCard(padding: 16) {
            HStack(spacing: 16) {
                Button {
                    model.togglePlayback()
                } label: {
                    Label(model.isPlaying ? "Stop" : "Play",
                          systemImage: model.isPlaying ? "stop.fill" : "play.fill")
                        .frame(width: 70)
                }
                .buttonStyle(.synth)
                .keyboardShortcut(.space, modifiers: [])

                HStack(spacing: 8) {
                    StatusDot(color: model.isPlaying ? .synthGreen : .synthInk.opacity(0.2))
                    Text(model.isPlaying ? "looping" : "stopped")
                        .font(.synthSans(11, weight: .medium))
                        .foregroundStyle(Color.synthInk.opacity(0.55))
                }

                Divider().frame(height: 22)

                SectionLabel("Tempo")
                GoldSlider(value: $model.bpm, range: 30...240, step: 1)
                    .frame(maxWidth: 220)
                    .onChange(of: model.bpm) { _ in model.tempoChanged() }
                Text("\(Int(model.bpm)) bpm")
                    .font(.synthMono(11))
                    .foregroundStyle(Color.synthInk.opacity(0.6))
                    .frame(width: 60, alignment: .leading)

                Spacer()
            }
        }
    }
}

/// One auto-generated slider for a numeric literal in the code.
struct TunableSlider: View {
    let tunable: Tunable
    let onChange: (Double) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(tunable.label.uppercased())
                    .font(.synthSans(9, weight: .semibold))
                    .tracking(0.6)
                    .foregroundStyle(Color.synthGold)
                Spacer()
                Text(PatternScript.format(tunable.value, isInt: tunable.integer))
                    .font(.synthMono(10))
                    .foregroundStyle(Color.synthInk.opacity(0.6))
            }
            GoldSlider(
                value: Binding(
                    get: { tunable.value },
                    set: { onChange($0) }
                ),
                range: tunable.range,
                step: tunable.integer ? 1 : nil
            )
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.synthFill))
    }
}
