import Foundation
import Strudel

// The CLI tool. By default it renders and plays the shared test pattern and
// exits when the sound finishes. Pass mini-notation to play that instead.
//
//   swift run synth-cli                             # play the shared test pattern
//   swift run synth-cli 'c3 e3 g3 c4'               # play mini-notation as notes
//   swift run synth-cli -s sawtooth 'c2 [e2 g2]*2'  # choose a sound
//   swift run synth-cli --cycles 4 --cpm 60 'c3*4'  # cycles + tempo
//   swift run synth-cli --render out.wav 'c3 e3'    # write a WAV instead of playing
//   swift run synth-cli --list-sounds               # list available sounds
//   swift run synth-cli --help

func printUsage() {
    print("""
    synth-cli — play strudel patterns through the speaker

    USAGE:
        synth-cli [options] [mini-notation]

    With no pattern, plays the shared test pattern
    (edit Sources/Strudel/TestPattern.swift to change it).

    The pattern argument is strudel mini-notation, interpreted as notes:
        'c3 [e3 g3]*2 <a3 b3>'   'c3,e3,g3'   'c3(3,8)'

    OPTIONS:
        -s, --sound <name>    sound to use (default: steinway); see --list-sounds
        -c, --cycles <n>      number of cycles to play (default: 2)
            --cps <x>         cycles per second (default: \(String(format: "%.3f", testCps)))
            --cpm <x>         cycles per minute (overrides --cps)
            --render <file>   write a WAV file instead of playing
            --samples <dir>   load a folder of samples into the registry
            --list-sounds     list available sounds, then exit
        -h, --help            show this help, then exit
    """)
}

installMiniNotation()

let arguments = Array(CommandLine.arguments.dropFirst())

if arguments.contains("-h") || arguments.contains("--help") {
    printUsage()
    exit(0)
}

var soundName = "steinway"
var cycles = 2.0
var cps = testCps
var renderPath: String? = nil
var patternTokens: [String] = []
var listSounds = false

var index = 0
while index < arguments.count {
    let argument = arguments[index]
    switch argument {
    case "-s", "--sound":
        index += 1
        guard index < arguments.count else { fail("missing sound name") }
        soundName = arguments[index]
    case "-c", "--cycles":
        index += 1
        guard index < arguments.count, let parsed = Double(arguments[index]), parsed > 0 else {
            fail("invalid cycle count")
        }
        cycles = parsed
    case "--cps":
        index += 1
        guard index < arguments.count, let parsed = Double(arguments[index]), parsed > 0 else {
            fail("invalid cps")
        }
        cps = parsed
    case "--cpm":
        index += 1
        guard index < arguments.count, let parsed = Double(arguments[index]), parsed > 0 else {
            fail("invalid cpm")
        }
        cps = parsed / 60
    case "--render":
        index += 1
        guard index < arguments.count else { fail("missing output file") }
        renderPath = arguments[index]
    case "--samples":
        index += 1
        guard index < arguments.count else { fail("missing samples directory") }
        do {
            try SampleLoader.loadDirectory(URL(fileURLWithPath: arguments[index]))
        } catch {
            fail("could not load samples: \(error)")
        }
    case "--list-sounds":
        listSounds = true
    default:
        patternTokens.append(argument)
    }
    index += 1
}

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("\(message)\n".utf8))
    exit(2)
}

if listSounds {
    print("Available sounds:")
    for name in SoundRegistry.shared.names {
        print("  \(name)")
    }
    exit(0)
}

// Build the pattern: mini-notation if given, otherwise the shared test pattern.
let pattern: StrudelCore.Pattern
if patternTokens.isEmpty {
    print("♪ Playing the shared test pattern (\(String(format: "%.1f", cycles / cps))s)…")
    pattern = testPattern()
} else {
    let mini = patternTokens.joined(separator: " ")
    print("♪ Playing \"\(mini)\" on \(soundName)…")
    pattern = note(.string(mini)).s(.string(soundName))
}

do {
    let player = StrudelPlayer()
    if let renderPath {
        let url = URL(fileURLWithPath: renderPath)
        try player.renderToFile(pattern, cycles: cycles, cps: cps, url: url)
        print("✓ Rendered \(cycles) cycle(s) to \(renderPath).")
    } else {
        try player.renderAndPlay(pattern, cycles: cycles, cps: cps)
        print("✓ Done.")
    }
} catch {
    FileHandle.standardError.write(Data("Audio error: \(error)\n".utf8))
    exit(1)
}
