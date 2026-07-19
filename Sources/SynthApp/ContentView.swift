import Strudel
import SwiftUI

struct ContentView: View {
    @StateObject private var model = AppModel()

    var body: some View {
        VStack(spacing: 16) {
            header
            controls
            livePattern
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
                Text("Strudel patterns in Swift — click a key, or play a pattern.")
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
                model.togglePlayback()
            } label: {
                Label(model.isPlaying ? "Stop" : "Play",
                      systemImage: model.isPlaying ? "stop.fill" : "play.fill")
            }
            .keyboardShortcut(.space, modifiers: [])

            Picker("Sound", selection: $model.soundName) {
                ForEach(model.availableSounds, id: \.self) { name in
                    Text(name).tag(name)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 240)
            .onChange(of: model.soundName) { _ in model.applyLiveEdits() }

            HStack(spacing: 8) {
                Text("Tempo")
                Slider(value: $model.cpm, in: 2...120, step: 1)
                    .frame(width: 160)
                    .onChange(of: model.cpm) { _ in model.applyLiveEdits() }
                Text("\(Int(model.cpm)) cpm")
                    .font(.caption.monospaced())
                    .frame(width: 64, alignment: .leading)
            }
        }
    }

    /// Mini-notation is parsed at runtime, so edits apply while playing.
    private var livePattern: some View {
        HStack(spacing: 8) {
            TextField(
                "mini-notation, e.g.  c3 [e3 g3]*2 <a3 b3>   (empty = test pattern)",
                text: $model.miniCode
            )
            .font(.body.monospaced())
            .textFieldStyle(.roundedBorder)
            .onSubmit { model.applyLiveEdits() }

            Button("Update") { model.applyLiveEdits() }
                .disabled(!model.isPlaying)
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
