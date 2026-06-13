import Foundation
import SynthCore

// The CLI tool. By default it plays the shared `Pattern.test` sequence and
// exits once the sound has finished. Pass note names to play them instead.
//
//   swift run synth-cli                      # play the shared test sequence
//   swift run synth-cli C4 E4 G4 C5          # play these notes
//   swift run synth-cli -w sine -t 90 A4 B4  # pick waveform + tempo
//   swift run synth-cli --list               # list all 88 keys
//   swift run synth-cli --help

func printUsage() {
    print("""
    synth-cli — play tones through the speaker

    USAGE:
        synth-cli [options] [notes...]

    With no notes, plays the shared Pattern.test sequence
    (edit Sources/SynthCore/TestSequence.swift to change it).

    NOTES:
        Note names like C4, F#5, Eb3, A4. Each plays as a quarter note.

    OPTIONS:
        -w, --waveform <name>   sine | square | triangle | sawtooth | voice (default: voice)
        -t, --tempo <bpm>       beats per minute (default: 120)
        -l, --list              list all 88 keys with frequencies, then exit
        -h, --help              show this help, then exit
    """)
}

let arguments = Array(CommandLine.arguments.dropFirst())

if arguments.contains("-h") || arguments.contains("--help") {
    printUsage()
    exit(0)
}

if arguments.contains("-l") || arguments.contains("--list") {
    print("#\tNote\tFrequency")
    for key in PianoKey.all {
        print("\(key.number)\t\(key.name)\t\(String(format: "%7.2f", key.frequency)) Hz")
    }
    exit(0)
}

// Parse options and collect bare note tokens.
var waveform: Waveform = .voice
var tempo = 120.0
var noteTokens: [String] = []

var index = 0
while index < arguments.count {
    let argument = arguments[index]
    switch argument {
    case "-w", "--waveform":
        index += 1
        if index < arguments.count, let parsed = Waveform(rawValue: arguments[index]) {
            waveform = parsed
        } else {
            FileHandle.standardError.write(Data("Unknown waveform.\n".utf8))
            exit(2)
        }
    case "-t", "--tempo":
        index += 1
        if index < arguments.count, let parsed = Double(arguments[index]), parsed > 0 {
            tempo = parsed
        } else {
            FileHandle.standardError.write(Data("Invalid tempo.\n".utf8))
            exit(2)
        }
    default:
        noteTokens.append(argument)
    }
    index += 1
}

// Build the pattern: explicit notes if given, otherwise the shared sequence.
let pattern: Pattern
if noteTokens.isEmpty {
    print("♪ Playing the shared test sequence (\(String(format: "%.1f", Pattern.test.duration))s)…")
    pattern = .test
} else {
    var keys: [PianoKey] = []
    for token in noteTokens {
        guard let key = PianoKey(name: token) else {
            FileHandle.standardError.write(Data("'\(token)' is not a valid note name.\n".utf8))
            exit(2)
        }
        keys.append(key)
    }
    print("♪ Playing \(keys.count) note(s) as \(waveform.rawValue) @ \(Int(tempo)) BPM…")
    pattern = Pattern(tempo: tempo, waveform: waveform, steps: keys.map { Note($0, .quarter) })
}

do {
    let player = SequencePlayer()
    try player.playAndWait(pattern)
    print("✓ Done.")
} catch {
    FileHandle.standardError.write(Data("Audio error: \(error)\n".utf8))
    exit(1)
}
