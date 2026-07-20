// SettingsView.swift — output, randomness, sample library, and attribution.

import Strudel
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header

            SynthCard {
                VStack(alignment: .leading, spacing: 14) {
                    SectionLabel("Output")
                    HStack(spacing: 12) {
                        Image(systemName: "speaker.wave.2")
                            .foregroundStyle(Color.synthInk.opacity(0.4))
                        GoldSlider(value: $model.masterVolume, range: 0...1)
                            .frame(maxWidth: 260)
                        Text("\(Int(model.masterVolume * 100))%")
                            .font(.synthMono(11))
                            .foregroundStyle(Color.synthInk.opacity(0.6))
                    }
                }
            }

            SynthCard {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        SectionLabel("Random number generator")
                        Text("Legacy matches strudel.cc's classic RNG (repeats every 300 cycles); precise is the newer hash-based generator.")
                            .font(.synthSans(10))
                            .foregroundStyle(Color.synthInk.opacity(0.45))
                    }
                    Spacer()
                    Picker("", selection: $model.preciseRNG) {
                        Text("Legacy").tag(false)
                        Text("Precise").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 180)
                }
            }

            SynthCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            SectionLabel("Sample library")
                            Text(model.sampleFolder ?? "Load a folder — each subfolder becomes a sound, files selectable with .n(i)")
                                .font(.synthSans(10))
                                .foregroundStyle(Color.synthInk.opacity(0.45))
                                .lineLimit(1)
                        }
                        Spacer()
                        Button("Load folder…") { model.loadSampleFolder() }
                            .buttonStyle(.synthQuiet)
                    }
                }
            }

            SectionLabel("Sounds (click to preview)")
            ScrollView {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 130), spacing: 10)],
                    alignment: .leading, spacing: 10
                ) {
                    ForEach(model.soundNames, id: \.self) { name in
                        Button {
                            model.preview(sound: name)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "waveform")
                                    .font(.system(size: 9))
                                    .foregroundStyle(Color.synthGold)
                                Text(name)
                                    .font(.synthMono(11))
                                    .foregroundStyle(Color.synthInk)
                                Spacer(minLength: 0)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color.synthFill))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            SynthCard(padding: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    SectionLabel("About")
                    Text("A Swift port of Strudel — patterns as functions of rational time, from the TidalCycles family. AGPL-3.0-or-later; engine verified against strudel.cc.")
                        .font(.synthSans(10.5))
                        .foregroundStyle(Color.synthInk.opacity(0.55))
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Settings")
                .font(.synthSerif(26, weight: .light, italic: true))
                .foregroundStyle(Color.synthInk)
            Text("Output, randomness, and the sound library.")
                .font(.synthSans(12))
                .foregroundStyle(Color.synthInk.opacity(0.5))
        }
    }
}
