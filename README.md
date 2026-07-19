# Synth

A Swift port of the [Strudel](https://strudel.cc) live-coding pattern engine
(the JavaScript port of [TidalCycles](https://tidalcycles.org)), playing
through native macOS audio. Patterns are functions of rational time,
mini-notation strings are parsed at runtime, and the original additive-synthesis
voices (Steinway grand, oscillators) are available as sounds — the long-term
goal remains a **manual vocal synthesizer**, and the ported vowel formant
filter (`.vowel("a e i o")`) is the seam for it.

```swift
import Strudel

installMiniNotation()

let pattern = note("c3 [e3 g3]*2 <a3 b3>")
    .s("sawtooth")
    .lpf(800)
    .every(4) { $0.rev() }
    .jux { $0.add(12) }

try StrudelPlayer().play(pattern, cps: 0.5)   // loops forever, like the REPL
```

## Layout

```
Package.swift
Sources/
  StrudelCore/          ← the pattern engine (port of strudel packages/core)
    Fraction.swift        exact rational time
    TimeSpan.swift        arcs of time
    Hap.swift             events (whole/part/value/context)
    Pattern.swift         Pattern = (State) -> [Hap], functor/applicative/monad
    PatternConstructors.swift  pure, stack, cat, seq, polymeter…
    PatternCombinators.swift   fast, slow, rev, every, jux, off, chop, iter…
    PatternOps.swift      add/sub/mul/…/set/keep with in/out/mix/squeeze/… alignments
    PatternStepwise.swift stepcat, pace, take/drop, extend, shrink/grow…
    Signal.swift          sine, saw, rand, perlin, degrade, sometimes… (RNG is
                          bit-exact with strudel.cc)
    Euclid.swift          bjorklund / euclidean rhythms
    Controls.swift        GENERATED: all 494 control functions (note, s, gain,
                          lpf, vowel, delay, room, …)
  StrudelMini/          ← mini-notation parser (port of the krill grammar)
                          "c3 [e3 g3]*2 <a3 b3>", {a b c}%4, a(3,8), a?0.3, 0 .. 7 …
  StrudelTonal/         ← scales, transpose, chords, voicings (port of packages/tonal)
  StrudelAudio/         ← superdough-equivalent audio output
    Cyclist.swift         the scheduler (port of cyclist.mjs)
    Sounds.swift          sound registry: synths, noises + the classic voices
    Sampler.swift         local sample folders: s("mysamples").n(3)
    HapRenderer.swift     source → ADSR → filters (+envelopes) → vowel formants
                          → shape/crush/coarse → gain/pan, delay + reverb tails
    StrudelPlayer.swift   AVAudioEngine playback + offline rendering
    Voice.swift & friends the original additive voices (steinway, synthvoice)
  Strudel/              ← umbrella module (import Strudel)
    TestPattern.swift     ★ the SHARED, editable pattern both apps play ★
  SynthCLI/               terminal tool — plays a pattern and exits
  SynthApp/               SwiftUI app: keyboard, sound picker, live mini-notation
Tools/                    codegen + verification harness
run-cli.sh                build + run the CLI
run-app.sh                build + run the GUI
```

## The iteration loop

1. Edit the shared pattern in
   [Sources/Strudel/TestPattern.swift](Sources/Strudel/TestPattern.swift).
2. Hear it from the terminal:

   ```sh
   ./run-cli.sh
   ```

The same `testPattern()` is what the GUI's **Play** button loops, so there is
exactly one place to edit. In the GUI you can also type mini-notation into the
text field and press **Update** while playing — mini-notation is runtime-parsed,
so this is live-codable without recompiling.

## CLI usage

```sh
./run-cli.sh                                  # play the shared test pattern
./run-cli.sh 'c3 e3 g3 c4'                    # play mini-notation as notes
./run-cli.sh -s sawtooth 'c2 [e2 g2]*2'       # choose a sound
./run-cli.sh --cycles 4 --cpm 60 'c3(3,8)'    # cycles + tempo
./run-cli.sh --render out.wav 'c3 e3'         # write a WAV instead of playing
./run-cli.sh --samples ~/samples 'bd*4'       # load a sample folder
./run-cli.sh --list-sounds
./run-cli.sh --help
```

## Writing patterns

Double-quoted strings in pattern positions are **mini-notation** — the full
krill grammar is supported:

| syntax | meaning |
|---|---|
| `"a b c"` | sequence within one cycle |
| `"a [b c]"` | sub-sequences |
| `"<a b>"` | one per cycle |
| `"{a b c, d e}%4"` | polymeter |
| `"a,e,g"` | stack (chord) |
| `"a\|b"` | random choice per cycle |
| `"a@3 b"`, `"a _ _ b"` | weights / elongation |
| `"a!3"` | replicate |
| `"a*2 b/2"` | fast / slow |
| `"a(3,8,1)"` | euclidean rhythm |
| `"a?0.3"` | degrade (random dropout) |
| `"bd:3"` | sample index (lists) |
| `"0 .. 7"` | ranges |

The combinator library is the strudel API in Swift: `fast, slow, rev, iter,
every, when, off, jux, echo, ply, chop, striate, euclid, degradeBy, sometimes,
palindrome, linger, zoom, compress, segment, range, add.mix(...), struct,
mask, scale, transpose, voicing…` plus all controls (`note, n, s, gain, pan,
attack, decay, sustain, release, lpf, hpf, vowel, delay, room, shape, crush,
coarse, speed, begin, end, …`).

```swift
n("0 2 4 <6 7>").scale("C:minor").s("triangle").room(0.3)
s("white*8").decay(0.05).sustain(0).degradeBy(0.3)
note("c2 e2").s("sawtooth").vowel("<a e i o>")     // formant filtering
"<C^7 A7 Dm7 G7>".voicing()                        // (via pure(...).voicing())
```

## Sounds

`--list-sounds` / the GUI picker show the registry: `sine, square, triangle,
sawtooth` (+ aliases), `white, pink, brown, crackle` noises, and the classic
additive voices `steinway` (default) and `synthvoice`. Add your own:

1. Conform to [`SoundSource`](Sources/StrudelAudio/Sounds.swift) (or the older
   [`Voice`](Sources/StrudelAudio/Voice.swift) protocol and wrap in `VoiceSound`),
2. `registerSound("myname", mySound)` — it's then playable as `s("myname")`.

Sample folders load with `SampleLoader.loadDirectory(...)` (CLI: `--samples`).

## Fidelity notes

Delay and reverb run as **shared per-orbit buses** (like superdough's orbits):
every hap sends into its orbit's continuously-running feedback delay and
Freeverb, whose parameters update at hap onsets — live via per-orbit
`AVAudioSourceNode`s, offline via the same streaming DSP. The distortion
algorithms (`soft`, `hard`, `cubic`, `diode`, `asym`, `fold`, `sinefold`,
`chebyshev`), phaser, compressor, ZzFX synths (`z_sine` … `z_noise`), custom
additive waveforms (`s("user").partials([...])`, `.phases`), wavetables
(`wt_` sample banks with `wt`/`wtenv` position sweeps), and the
chord-voicings voice-leading (`.voicings("lefthand")`) are all ported and
tested against the JS implementations. Remaining niche gaps: superdough's
supersaw/pulse worklet oscillators, the phase vocoder (`stretch`), Kabelsalat
worklets (`K`), and the modulator bus (`bmod`/`lfo` object configs).

## Verification

The engine is tested against strudel itself: unit tests port strudel's own
test expectations, the RNG is verified bit-exact, and
`Tools/differential` (see Tools/README.md) diffs `queryArc` output between
this port and the JS package running under node.

## License & attribution

This project is a Swift port of [Strudel](https://codeberg.org/uzu/strudel)
(AGPL-3.0-or-later, © Strudel contributors), which itself ports
[TidalCycles](https://tidalcycles.org) by Alex McLean and contributors. Scale
data derives from [tonaljs](https://github.com/tonaljs/tonal) (MIT). The whole
repository is licensed **AGPL-3.0-or-later** — see [LICENSE](LICENSE).
