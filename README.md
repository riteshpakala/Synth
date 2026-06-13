# Synth

A base Swift package for playing tones through the speaker. It maps all 88 keys
of a piano and lets you queue them in a declarative pattern. The intent is to
grow this into a **manual vocal synthesizer**.

## Layout

```
Package.swift
Sources/
  SynthCore/            ← shared engine (used by BOTH the CLI and the GUI)
    PianoKey.swift        88-key mapping: number, MIDI, frequency, name
    Voice.swift           ★ Voice protocol + VoiceLibrary registry (sound options) ★
    OscillatorVoice.swift sine / triangle / square / sawtooth / synth-voice presets
    SteinwayGrandPianoVoice.swift  additive, inharmonic grand-piano synthesis
    Waveform.swift        raw oscillator shapes used by OscillatorVoice
    Envelope.swift        ADSR amplitude envelope
    NoteValue.swift       rhythmic durations (whole … thirty-second, dotted)
    Pattern.swift         declarative DSL: Note / Chord / Rest + @PatternBuilder
    Synthesizer.swift     renders a Pattern → PCM samples (pure DSP)
    SequencePlayer.swift  plays a Pattern through the speaker (AVAudioEngine)
    TestSequence.swift    ★ the SHARED, editable sequence both apps play ★
  SynthCLI/
    main.swift            terminal tool — plays sound and exits
  SynthApp/
    main.swift            launches the SwiftUI app
    SynthApplication.swift / AppModel.swift / ContentView.swift
run-cli.sh                build + run the CLI
run-app.sh                build + run the GUI
```

## The iteration loop

1. Open `Package.swift` in Xcode to edit and iterate.
2. Edit the shared sequence in
   [Sources/SynthCore/TestSequence.swift](Sources/SynthCore/TestSequence.swift).
3. Hear it from the terminal:

   ```sh
   ./run-cli.sh
   ```

   The CLI renders the sequence, plays it through the speaker, and exits.

The same `Pattern.test` is what the GUI's **Play Test Sequence** button plays,
so there is exactly one place to edit.

## CLI usage

```sh
./run-cli.sh                             # play the shared test sequence
./run-cli.sh C4 E4 G4 C5                 # play specific notes
./run-cli.sh -v steinway -t 90 A4 B4     # choose voice + tempo
./run-cli.sh --list-voices               # list available sounds
./run-cli.sh --list                      # list all 88 keys with frequencies
./run-cli.sh --help
```

## GUI

```sh
./run-app.sh
```

Click any key to sound it, pick a voice, set the tempo, or play the shared
test sequence (Space).

## Sounds (voices)

A **voice** is a selectable sound — the thing that turns a note into audio. It
owns its own waveform/spectrum and envelope, so different voices can synthesize
in completely different ways behind one interface. Built-in voices:

- `Sine`, `Triangle`, `Square`, `Sawtooth` — basic oscillators
- `Synth Voice` — an additive harmonic stack (seed for the vocal synth)
- `Steinway Grand Piano` — additive, inharmonic grand-piano synthesis (default)

### Adding a voice (extension point)

1. Conform a type to [`Voice`](Sources/SynthCore/Voice.swift) and implement
   `render(frequency:duration:velocity:sampleRate:)`.
2. Add a preset in a `extension Voice where Self == YourVoice { … }` block (so
   it's usable as `.yourVoice`).
3. List it in `VoiceLibrary.all` — it then appears in the CLI (`--list-voices`,
   `-v`) and the GUI picker automatically.

This is how future vocal styles will plug in.

## Writing patterns

```swift
import SynthCore

let pattern = Pattern(tempo: 120, voice: .steinwayGrand) {
    Note("C4", .quarter)
    Chord(["C4", "E4", "G4"], .half)
    Rest(.eighth)
    for name in ["D4", "E4", "F4"] {
        Note(name, .eighth)
    }
    Note("C4", .half, voice: .sine)   // per-note voice override
}

try SequencePlayer().playAndWait(pattern)   // blocks until finished (CLI)
// or
try SequencePlayer().play(pattern)          // fire-and-forget (GUI)
```

## Toward a vocal synth

The `Voice` protocol is the seam for vocal styles: a future `VocalVoice` would
do formant-based vowel synthesis (sculpting the harmonics in `Synth Voice` with
formant filtering and per-note vowel parameters) and slot into `VoiceLibrary`
alongside the piano.
```
