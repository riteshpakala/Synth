import SwiftUI
import SynthCore

struct ContentView: View {
    @StateObject private var model = AppModel()

    var body: some View {
        VStack(spacing: 16) {
            header
            controls
            PianoKeyboardView { key in
                model.play(key: key)
            }
            .frame(height: 150)
        }
        .padding(20)
        .frame(minWidth: 720)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Synth").font(.title).bold()
                Text("Click a key, or play the shared test sequence.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("Last: \(model.lastPlayed)")
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
        }
    }

    private var controls: some View {
        HStack(spacing: 16) {
            Button {
                model.playTestSequence()
            } label: {
                Label("Play Test Sequence", systemImage: "play.fill")
            }
            .keyboardShortcut(.space, modifiers: [])

            Picker("Waveform", selection: $model.waveform) {
                ForEach(Waveform.allCases, id: \.self) { waveform in
                    Text(waveform.rawValue.capitalized).tag(waveform)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 200)

            HStack(spacing: 8) {
                Text("Tempo")
                Slider(value: $model.tempo, in: 40...240, step: 1)
                    .frame(width: 160)
                Text("\(Int(model.tempo)) BPM")
                    .font(.caption.monospaced())
                    .frame(width: 64, alignment: .leading)
            }
        }
    }
}

/// A scrollable, clickable 88-key piano keyboard with black keys overlaid in
/// their correct positions.
struct PianoKeyboardView: View {
    let onPress: (PianoKey) -> Void

    private let whiteKeys = PianoKey.all.filter { !$0.isSharp }
    private let blackKeys = PianoKey.all.filter { $0.isSharp }

    private let whiteWidth: CGFloat = 26
    private let blackWidth: CGFloat = 16
    private let whiteHeight: CGFloat = 150
    private let blackHeight: CGFloat = 95

    var body: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            ZStack(alignment: .topLeading) {
                HStack(spacing: 0) {
                    ForEach(whiteKeys, id: \.number) { key in
                        WhiteKey(key: key, width: whiteWidth, height: whiteHeight)
                            .onTapGesture { onPress(key) }
                    }
                }
                ForEach(blackKeys, id: \.number) { key in
                    BlackKey(width: blackWidth, height: blackHeight)
                        .offset(x: blackKeyX(for: key))
                        .onTapGesture { onPress(key) }
                }
            }
            .frame(width: CGFloat(whiteKeys.count) * whiteWidth, alignment: .leading)
        }
    }

    /// A black key sits on the boundary just right of the natural below it.
    private func blackKeyX(for key: PianoKey) -> CGFloat {
        let leftWhiteMidi = key.midiNoteNumber - 1
        guard let leftIndex = whiteKeys.firstIndex(where: { $0.midiNoteNumber == leftWhiteMidi }) else {
            return 0
        }
        return CGFloat(leftIndex + 1) * whiteWidth - blackWidth / 2
    }
}

private struct WhiteKey: View {
    let key: PianoKey
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.gray.opacity(0.5)))
            if key.noteName == .c {
                Text(key.name)
                    .font(.system(size: 8))
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 4)
            }
        }
        .frame(width: width, height: height)
        .contentShape(Rectangle())
    }
}

private struct BlackKey: View {
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(Color.black)
            .frame(width: width, height: height)
            .contentShape(Rectangle())
    }
}

#Preview {
    ContentView()
}
