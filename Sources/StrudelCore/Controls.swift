// Controls.swift — GENERATED from strudel packages/core/controls.mjs
// (via Tools/generate_controls.py). Do not edit by hand.
// Ported from Strudel <https://codeberg.org/uzu/strudel> — AGPL-3.0-or-later.

import Foundation

public enum Controls {
    /// Maps every control name and alias to its main control name.
    public static let alias: [String: String] = [
        "FXr": "FXrelease",
        "FXrel": "FXrelease",
        "FXrelease": "FXrelease",
        "accelerate": "accelerate",
        "activeLabel": "activeLabel",
        "amp": "amp",
        "analyze": "analyze",
        "anchor": "anchor",
        "att": "attack",
        "attack": "attack",
        "bandf": "bandf",
        "bandq": "bandq",
        "bank": "bank",
        "bb": "byteBeatExpression",
        "bbexpr": "byteBeatExpression",
        "bbst": "byteBeatStartTime",
        "begin": "begin",
        "bgain": "busgain",
        "binshift": "binshift",
        "bp": "bandf",
        "bpa": "bpattack",
        "bpattack": "bpattack",
        "bpd": "bpdecay",
        "bpdc": "bpdc",
        "bpdecay": "bpdecay",
        "bpdepth": "bpdepth",
        "bpdepthfreq": "bpdepthfrequency",
        "bpdepthfrequency": "bpdepthfrequency",
        "bpe": "bpenv",
        "bpenv": "bpenv",
        "bpf": "bandf",
        "bpq": "bandq",
        "bpr": "bprelease",
        "bprate": "bprate",
        "bprelease": "bprelease",
        "bps": "bpsustain",
        "bpshape": "bpshape",
        "bpskew": "bpskew",
        "bpsustain": "bpsustain",
        "bpsync": "bpsync",
        "bus": "bus",
        "busgain": "busgain",
        "byteBeatExpression": "byteBeatExpression",
        "byteBeatStartTime": "byteBeatStartTime",
        "ccn": "ccn",
        "ccv": "ccv",
        "ch": "channels",
        "channel": "channel",
        "channels": "channels",
        "chord": "chord",
        "chorus": "chorus",
        "clip": "clip",
        "coarse": "coarse",
        "color": "color",
        "comb": "comb",
        "compressor": "compressor",
        "compressorAttack": "compressorAttack",
        "compressorKnee": "compressorKnee",
        "compressorRatio": "compressorRatio",
        "compressorRelease": "compressorRelease",
        "cps": "cps",
        "crush": "crush",
        "ctf": "cutoff",
        "ctlNum": "ctlNum",
        "ctranspose": "ctranspose",
        "curve": "curve",
        "cut": "cut",
        "cutoff": "cutoff",
        "datt": "duckattack",
        "dec": "decay",
        "decay": "decay",
        "degree": "degree",
        "delay": "delay",
        "delayfb": "delayfeedback",
        "delayfeedback": "delayfeedback",
        "delays": "delaysync",
        "delayspeed": "delayspeed",
        "delaysync": "delaysync",
        "delayt": "delaytime",
        "delaytime": "delaytime",
        "deltaSlide": "deltaSlide",
        "density": "density",
        "det": "detune",
        "detune": "detune",
        "dfb": "delayfeedback",
        "dict": "dictionary",
        "dictionary": "dictionary",
        "dist": "distort",
        "distort": "distort",
        "distorttype": "distorttype",
        "distortvol": "distortvol",
        "disttype": "distorttype",
        "distvol": "distortvol",
        "djf": "djf",
        "drive": "drive",
        "dry": "dry",
        "ds": "delaysync",
        "dt": "delaytime",
        "duck": "duckorbit",
        "duckatt": "duckattack",
        "duckattack": "duckattack",
        "duckdepth": "duckdepth",
        "duckons": "duckonset",
        "duckonset": "duckonset",
        "duckorbit": "duckorbit",
        "dur": "duration",
        "duration": "duration",
        "end": "end",
        "enhance": "enhance",
        "expression": "expression",
        "fadeInTime": "fadeInTime",
        "fadeOutTime": "fadeTime",
        "fadeTime": "fadeTime",
        "fanchor": "fanchor",
        "fft": "fft",
        "fm": "fmi",
        "fm1": "fmi",
        "fm2": "fmi2",
        "fm3": "fmi3",
        "fm4": "fmi4",
        "fm5": "fmi5",
        "fm6": "fmi6",
        "fm7": "fmi7",
        "fm8": "fmi8",
        "fmatt": "fmattack",
        "fmatt1": "fmattack",
        "fmatt2": "fmattack2",
        "fmatt3": "fmattack3",
        "fmatt4": "fmattack4",
        "fmatt5": "fmattack5",
        "fmatt6": "fmattack6",
        "fmatt7": "fmattack7",
        "fmatt8": "fmattack8",
        "fmattack": "fmattack",
        "fmattack1": "fmattack",
        "fmattack2": "fmattack2",
        "fmattack3": "fmattack3",
        "fmattack4": "fmattack4",
        "fmattack5": "fmattack5",
        "fmattack6": "fmattack6",
        "fmattack7": "fmattack7",
        "fmattack8": "fmattack8",
        "fmdec": "fmdecay",
        "fmdec1": "fmdecay",
        "fmdec2": "fmdecay2",
        "fmdec3": "fmdecay3",
        "fmdec4": "fmdecay4",
        "fmdec5": "fmdecay5",
        "fmdec6": "fmdecay6",
        "fmdec7": "fmdecay7",
        "fmdec8": "fmdecay8",
        "fmdecay": "fmdecay",
        "fmdecay1": "fmdecay",
        "fmdecay2": "fmdecay2",
        "fmdecay3": "fmdecay3",
        "fmdecay4": "fmdecay4",
        "fmdecay5": "fmdecay5",
        "fmdecay6": "fmdecay6",
        "fmdecay7": "fmdecay7",
        "fmdecay8": "fmdecay8",
        "fme": "fmenv",
        "fme1": "fmenv",
        "fme2": "fmenv2",
        "fme3": "fmenv3",
        "fme4": "fmenv4",
        "fme5": "fmenv5",
        "fme6": "fmenv6",
        "fme7": "fmenv7",
        "fme8": "fmenv8",
        "fmenv": "fmenv",
        "fmenv1": "fmenv",
        "fmenv2": "fmenv2",
        "fmenv3": "fmenv3",
        "fmenv4": "fmenv4",
        "fmenv5": "fmenv5",
        "fmenv6": "fmenv6",
        "fmenv7": "fmenv7",
        "fmenv8": "fmenv8",
        "fmh": "fmh",
        "fmh1": "fmh",
        "fmh2": "fmh2",
        "fmh3": "fmh3",
        "fmh4": "fmh4",
        "fmh5": "fmh5",
        "fmh6": "fmh6",
        "fmh7": "fmh7",
        "fmh8": "fmh8",
        "fmi": "fmi",
        "fmi1": "fmh",
        "fmi2": "fmi2",
        "fmi3": "fmi3",
        "fmi4": "fmi4",
        "fmi5": "fmi5",
        "fmi6": "fmi6",
        "fmi7": "fmi7",
        "fmi8": "fmi8",
        "fmrel": "fmrelease",
        "fmrel1": "fmrelease",
        "fmrel2": "fmrelease2",
        "fmrel3": "fmrelease3",
        "fmrel4": "fmrelease4",
        "fmrel5": "fmrelease5",
        "fmrel6": "fmrelease6",
        "fmrel7": "fmrelease7",
        "fmrel8": "fmrelease8",
        "fmrelease": "fmrelease",
        "fmrelease1": "fmrelease",
        "fmrelease2": "fmrelease2",
        "fmrelease3": "fmrelease3",
        "fmrelease4": "fmrelease4",
        "fmrelease5": "fmrelease5",
        "fmrelease6": "fmrelease6",
        "fmrelease7": "fmrelease7",
        "fmrelease8": "fmrelease8",
        "fmsus": "fmsustain",
        "fmsus1": "fmsustain",
        "fmsus2": "fmsustain2",
        "fmsus3": "fmsustain3",
        "fmsus4": "fmsustain4",
        "fmsus5": "fmsustain5",
        "fmsus6": "fmsustain6",
        "fmsus7": "fmsustain7",
        "fmsus8": "fmsustain8",
        "fmsustain": "fmsustain",
        "fmsustain1": "fmsustain",
        "fmsustain2": "fmsustain2",
        "fmsustain3": "fmsustain3",
        "fmsustain4": "fmsustain4",
        "fmsustain5": "fmsustain5",
        "fmsustain6": "fmsustain6",
        "fmsustain7": "fmsustain7",
        "fmsustain8": "fmsustain8",
        "fmwave": "fmwave",
        "fmwave1": "fmwave",
        "fmwave2": "fmwave2",
        "fmwave3": "fmwave3",
        "fmwave4": "fmwave4",
        "fmwave5": "fmwave5",
        "fmwave6": "fmwave6",
        "fmwave7": "fmwave7",
        "fmwave8": "fmwave8",
        "frameRate": "frameRate",
        "frames": "frames",
        "freeze": "freeze",
        "freq": "freq",
        "fshift": "fshift",
        "fshiftnote": "fshiftnote",
        "fshiftphase": "fshiftphase",
        "ftype": "ftype",
        "fxr": "FXrelease",
        "gain": "gain",
        "gat": "gate",
        "gate": "gate",
        "harmonic": "harmonic",
        "hbrick": "hbrick",
        "hcutoff": "hcutoff",
        "hold": "hold",
        "hours": "hours",
        "hp": "hcutoff",
        "hpa": "hpattack",
        "hpattack": "hpattack",
        "hpd": "hpdecay",
        "hpdc": "hpdc",
        "hpdecay": "hpdecay",
        "hpdepth": "hpdepth",
        "hpdepthfreq": "hpdepthfrequency",
        "hpdepthfrequency": "hpdepthfrequency",
        "hpe": "hpenv",
        "hpenv": "hpenv",
        "hpf": "hcutoff",
        "hpq": "hresonance",
        "hpr": "hprelease",
        "hprate": "hprate",
        "hprelease": "hprelease",
        "hps": "hpsustain",
        "hpshape": "hpshape",
        "hpskew": "hpskew",
        "hpsustain": "hpsustain",
        "hpsync": "hpsync",
        "hresonance": "hresonance",
        "i": "i",
        "imag": "imag",
        "ir": "ir",
        "irbegin": "irbegin",
        "iresponse": "ir",
        "irspeed": "irspeed",
        "kcutoff": "kcutoff",
        "krush": "krush",
        "label": "label",
        "lbrick": "lbrick",
        "legato": "clip",
        "leslie": "leslie",
        "lock": "lock",
        "loop": "loop",
        "loopBegin": "loopBegin",
        "loopEnd": "loopEnd",
        "loopb": "loopBegin",
        "loope": "loopEnd",
        "lp": "cutoff",
        "lpa": "lpattack",
        "lpattack": "lpattack",
        "lpd": "lpdecay",
        "lpdc": "lpdc",
        "lpdecay": "lpdecay",
        "lpdepth": "lpdepth",
        "lpdepthfreq": "lpdepthfrequency",
        "lpdepthfrequency": "lpdepthfrequency",
        "lpe": "lpenv",
        "lpenv": "lpenv",
        "lpf": "cutoff",
        "lpq": "resonance",
        "lpr": "lprelease",
        "lprate": "lprate",
        "lprelease": "lprelease",
        "lps": "lpsustain",
        "lpshape": "lpshape",
        "lpskew": "lpskew",
        "lpsustain": "lpsustain",
        "lpsync": "lpsync",
        "lrate": "lrate",
        "lsize": "lsize",
        "midibend": "midibend",
        "midichan": "midichan",
        "midicmd": "midicmd",
        "midimap": "midimap",
        "midiport": "midiport",
        "miditouch": "miditouch",
        "minutes": "minutes",
        "mode": "mode",
        "mtranspose": "mtranspose",
        "n": "n",
        "noise": "noise",
        "note": "note",
        "nrpnn": "nrpnn",
        "nrpv": "nrpv",
        "nudge": "nudge",
        "o": "orbit",
        "oct": "octave",
        "octave": "octave",
        "octaveR": "octaveR",
        "octaves": "octaves",
        "octer": "octer",
        "octersub": "octersub",
        "octersubsub": "octersubsub",
        "offset": "offset",
        "orbit": "orbit",
        "oschost": "oschost",
        "oscport": "oscport",
        "overgain": "overgain",
        "overshape": "overshape",
        "pan": "pan",
        "panchor": "panchor",
        "panorient": "panorient",
        "panspan": "panspan",
        "pansplay": "pansplay",
        "panwidth": "panwidth",
        "patt": "pattack",
        "pattack": "pattack",
        "pcurve": "pcurve",
        "pdec": "pdecay",
        "pdecay": "pdecay",
        "penv": "penv",
        "ph": "phaserrate",
        "phasdp": "phaserdepth",
        "phaser": "phaserrate",
        "phasercenter": "phasercenter",
        "phaserdepth": "phaserdepth",
        "phaserrate": "phaserrate",
        "phasersweep": "phasersweep",
        "phc": "phasercenter",
        "phd": "phaserdepth",
        "phs": "phasersweep",
        "pitchJump": "pitchJump",
        "pitchJumpTime": "pitchJumpTime",
        "polyTouch": "polyTouch",
        "postgain": "postgain",
        "prel": "prelease",
        "prelease": "prelease",
        "progNum": "progNum",
        "psus": "psustain",
        "psustain": "psustain",
        "pw": "pw",
        "pwr": "pwrate",
        "pwrate": "pwrate",
        "pws": "pwsweep",
        "pwsweep": "pwsweep",
        "rdim": "roomdim",
        "real": "real",
        "rel": "release",
        "release": "release",
        "resonance": "resonance",
        "rfade": "roomfade",
        "ring": "ring",
        "ringdf": "ringdf",
        "ringf": "ringf",
        "rlp": "roomlp",
        "room": "room",
        "roomdim": "roomdim",
        "roomfade": "roomfade",
        "roomlp": "roomlp",
        "roomsize": "roomsize",
        "rsize": "roomsize",
        "s": "s",
        "scram": "scram",
        "seconds": "seconds",
        "semitone": "semitone",
        "shape": "shape",
        "size": "roomsize",
        "slide": "slide",
        "smear": "smear",
        "songPtr": "songPtr",
        "sound": "s",
        "source": "source",
        "speed": "speed",
        "spread": "spread",
        "squiz": "squiz",
        "src": "source",
        "stepsPerOctave": "stepsPerOctave",
        "stretch": "stretch",
        "sus": "sustain",
        "sustain": "sustain",
        "sustainpedal": "sustainpedal",
        "sysexdata": "sysexdata",
        "sysexid": "sysexid",
        "sz": "roomsize",
        "transient": "transient",
        "trem": "tremolo",
        "tremdepth": "tremolodepth",
        "tremolo": "tremolo",
        "tremolodepth": "tremolodepth",
        "tremolophase": "tremolophase",
        "tremoloshape": "tremoloshape",
        "tremoloskew": "tremoloskew",
        "tremolosync": "tremolosync",
        "tremphase": "tremolophase",
        "tremshape": "tremoloshape",
        "tremskew": "tremoloskew",
        "tremsync": "tremolosync",
        "triode": "triode",
        "tsdelay": "tsdelay",
        "uid": "uid",
        "unison": "unison",
        "unit": "unit",
        "v": "vib",
        "val": "val",
        "vel": "velocity",
        "velocity": "velocity",
        "vib": "vib",
        "vibmod": "vibmod",
        "vibrato": "vib",
        "vmod": "vibmod",
        "voice": "voice",
        "vowel": "vowel",
        "warp": "warp",
        "warpatt": "warpattack",
        "warpattack": "warpattack",
        "warpdc": "warpdc",
        "warpdec": "warpdecay",
        "warpdecay": "warpdecay",
        "warpdepth": "warpdepth",
        "warpenv": "warpenv",
        "warpmode": "warpmode",
        "warprate": "warprate",
        "warprel": "warprelease",
        "warprelease": "warprelease",
        "warpshape": "warpshape",
        "warpskew": "warpskew",
        "warpsus": "warpsustain",
        "warpsustain": "warpsustain",
        "warpsync": "warpsync",
        "waveloss": "waveloss",
        "wavetablePhaseRand": "wtphaserand",
        "wavetablePosition": "wt",
        "wavetableWarp": "warp",
        "wavetableWarpMode": "warpmode",
        "wt": "wt",
        "wtatt": "wtattack",
        "wtattack": "wtattack",
        "wtdc": "wtdc",
        "wtdec": "wtdecay",
        "wtdecay": "wtdecay",
        "wtdepth": "wtdepth",
        "wtenv": "wtenv",
        "wtphaserand": "wtphaserand",
        "wtrate": "wtrate",
        "wtrel": "wtrelease",
        "wtrelease": "wtrelease",
        "wtshape": "wtshape",
        "wtskew": "wtskew",
        "wtsus": "wtsustain",
        "wtsustain": "wtsustain",
        "wtsync": "wtsync",
        "xsdelay": "xsdelay",
        "zcrush": "zcrush",
        "zdelay": "zdelay",
        "zmod": "zmod",
        "znoise": "znoise",
        "zrand": "zrand",
        "zzfx": "zzfx",
    ]

    /// Multi-name splat lists (mini-notation ":" lists), by main name.
    public static let names: [String: [String]] = [
        "bandf": ["bandf", "bandq", "bpenv"],
        "color": ["color", "colour"],
        "compressor": ["compressor", "compressorRatio", "compressorKnee", "compressorAttack", "compressorRelease"],
        "cutoff": ["cutoff", "resonance", "lpenv"],
        "delay": ["delay", "delaytime", "delayfeedback"],
        "distort": ["distort", "distortvol", "distorttype"],
        "fmh": ["fmh", "fmi"],
        "fmh2": ["fmh2", "fmi2"],
        "fmh3": ["fmh3", "fmi3"],
        "fmh4": ["fmh4", "fmi4"],
        "fmh5": ["fmh5", "fmi5"],
        "fmh6": ["fmh6", "fmi6"],
        "fmh7": ["fmh7", "fmi7"],
        "fmh8": ["fmh8", "fmi8"],
        "fmi": ["fmi", "fmh"],
        "fmi2": ["fmi2", "fmh2"],
        "fmi3": ["fmi3", "fmh3"],
        "fmi4": ["fmi4", "fmh4"],
        "fmi5": ["fmi5", "fmh5"],
        "fmi6": ["fmi6", "fmh6"],
        "fmi7": ["fmi7", "fmh7"],
        "fmi8": ["fmi8", "fmh8"],
        "hcutoff": ["hcutoff", "hresonance", "hpenv"],
        "ir": ["ir", "i"],
        "label": ["label", "activeLabel"],
        "mode": ["mode", "anchor"],
        "note": ["note", "n"],
        "phaserrate": ["phaserrate", "phaserdepth", "phasercenter", "phasersweep"],
        "pw": ["pw", "pwrate", "pwsweep"],
        "room": ["room", "size"],
        "s": ["s", "n", "gain"],
        "shape": ["shape", "shapevol"],
        "transient": ["transient", "transsustain"],
        "tremolo": ["tremolo", "tremolodepth", "tremoloskew", "tremolophase"],
        "tremolosync": ["tremolosync", "tremolodepth", "tremoloskew", "tremolophase"],
        "vib": ["vib", "vibmod"],
        "vibmod": ["vibmod", "vib"],
    ]

    public static func isControlName(_ name: String) -> Bool {
        alias[name] != nil
    }
}

// MARK: - Core control machinery (port of createParam)

/// Wraps a raw value into a control map for the given name list.
func controlWithVal(_ names: [String], _ xs: PatternValue) -> PatternValue {
    let name = names[0]
    var value = xs
    var bag: ControlMap? = nil
    // an object with an unnamed control (.value) carries other controls along
    if var m = value.mapValue, let v = m["value"] {
        m.removeValue(forKey: "value")
        bag = m
        value = v
    }
    if names.count > 1, let list = value.listValue {
        var result = bag ?? [:]
        for (i, x) in list.enumerated() where i < names.count {
            result[names[i]] = x
        }
        return .map(result)
    }
    if var bag {
        bag[name] = value
        return .map(bag)
    }
    return .map([name: value])
}

/// A control pattern: values wrapped into named control maps.
public func controlPattern(_ names: [String], _ value: PatternValue) -> Pattern {
    reify(value).withValue { controlWithVal(names, $0) }
}

extension Pattern {
    /// `pat.ctrl(v)` == `pat.set(ctrl(v))` — the generic control setter.
    public func control(_ name: String, _ value: PatternValue) -> Pattern {
        let main = Controls.alias[name] ?? name
        let names = Controls.extraNames[name] ?? Controls.names[main] ?? [main]
        return set.in(.pattern(controlPattern(names, value)))
    }

    /// `"c3 e3".as("note")` — names the unnamed values (controls.mjs `as`).
    public func `as`(_ name: String) -> Pattern {
        fmap { v in controlWithVal([Controls.alias[name] ?? name], v) }
    }

    /// Sets attack/decay/sustain/release from a "a:d:s:r" list (controls.mjs adsr).
    public func adsr(_ value: PatternValue) -> Pattern {
        control("adsr", value)
    }

    /// attack:release pair (controls.mjs ar).
    public func ar(_ value: PatternValue) -> Pattern {
        control("ar", value)
    }
}

// MARK: - Generated control methods

extension Pattern {
    public func FXr(_ value: PatternValue) -> Pattern { control("FXrelease", value) }
    public func FXrel(_ value: PatternValue) -> Pattern { control("FXrelease", value) }
    public func FXrelease(_ value: PatternValue) -> Pattern { control("FXrelease", value) }
    public func accelerate(_ value: PatternValue) -> Pattern { control("accelerate", value) }
    public func activeLabel(_ value: PatternValue) -> Pattern { control("activeLabel", value) }
    public func amp(_ value: PatternValue) -> Pattern { control("amp", value) }
    public func analyze(_ value: PatternValue) -> Pattern { control("analyze", value) }
    public func anchor(_ value: PatternValue) -> Pattern { control("anchor", value) }
    public func att(_ value: PatternValue) -> Pattern { control("attack", value) }
    public func attack(_ value: PatternValue) -> Pattern { control("attack", value) }
    public func bandf(_ value: PatternValue) -> Pattern { control("bandf", value) }
    public func bandq(_ value: PatternValue) -> Pattern { control("bandq", value) }
    public func bank(_ value: PatternValue) -> Pattern { control("bank", value) }
    public func bb(_ value: PatternValue) -> Pattern { control("byteBeatExpression", value) }
    public func bbexpr(_ value: PatternValue) -> Pattern { control("byteBeatExpression", value) }
    public func bbst(_ value: PatternValue) -> Pattern { control("byteBeatStartTime", value) }
    public func begin(_ value: PatternValue) -> Pattern { control("begin", value) }
    public func bgain(_ value: PatternValue) -> Pattern { control("busgain", value) }
    public func binshift(_ value: PatternValue) -> Pattern { control("binshift", value) }
    public func bp(_ value: PatternValue) -> Pattern { control("bandf", value) }
    public func bpa(_ value: PatternValue) -> Pattern { control("bpattack", value) }
    public func bpattack(_ value: PatternValue) -> Pattern { control("bpattack", value) }
    public func bpd(_ value: PatternValue) -> Pattern { control("bpdecay", value) }
    public func bpdc(_ value: PatternValue) -> Pattern { control("bpdc", value) }
    public func bpdecay(_ value: PatternValue) -> Pattern { control("bpdecay", value) }
    public func bpdepth(_ value: PatternValue) -> Pattern { control("bpdepth", value) }
    public func bpdepthfreq(_ value: PatternValue) -> Pattern { control("bpdepthfrequency", value) }
    public func bpdepthfrequency(_ value: PatternValue) -> Pattern { control("bpdepthfrequency", value) }
    public func bpe(_ value: PatternValue) -> Pattern { control("bpenv", value) }
    public func bpenv(_ value: PatternValue) -> Pattern { control("bpenv", value) }
    public func bpf(_ value: PatternValue) -> Pattern { control("bandf", value) }
    public func bpq(_ value: PatternValue) -> Pattern { control("bandq", value) }
    public func bpr(_ value: PatternValue) -> Pattern { control("bprelease", value) }
    public func bprate(_ value: PatternValue) -> Pattern { control("bprate", value) }
    public func bprelease(_ value: PatternValue) -> Pattern { control("bprelease", value) }
    public func bps(_ value: PatternValue) -> Pattern { control("bpsustain", value) }
    public func bpshape(_ value: PatternValue) -> Pattern { control("bpshape", value) }
    public func bpskew(_ value: PatternValue) -> Pattern { control("bpskew", value) }
    public func bpsustain(_ value: PatternValue) -> Pattern { control("bpsustain", value) }
    public func bpsync(_ value: PatternValue) -> Pattern { control("bpsync", value) }
    public func bus(_ value: PatternValue) -> Pattern { control("bus", value) }
    public func busgain(_ value: PatternValue) -> Pattern { control("busgain", value) }
    public func byteBeatExpression(_ value: PatternValue) -> Pattern { control("byteBeatExpression", value) }
    public func byteBeatStartTime(_ value: PatternValue) -> Pattern { control("byteBeatStartTime", value) }
    public func ccn(_ value: PatternValue) -> Pattern { control("ccn", value) }
    public func ccv(_ value: PatternValue) -> Pattern { control("ccv", value) }
    public func ch(_ value: PatternValue) -> Pattern { control("channels", value) }
    public func channel(_ value: PatternValue) -> Pattern { control("channel", value) }
    public func channels(_ value: PatternValue) -> Pattern { control("channels", value) }
    public func chord(_ value: PatternValue) -> Pattern { control("chord", value) }
    public func chorus(_ value: PatternValue) -> Pattern { control("chorus", value) }
    public func clip(_ value: PatternValue) -> Pattern { control("clip", value) }
    public func coarse(_ value: PatternValue) -> Pattern { control("coarse", value) }
    public func color(_ value: PatternValue) -> Pattern { control("color", value) }
    public func comb(_ value: PatternValue) -> Pattern { control("comb", value) }
    public func compressor(_ value: PatternValue) -> Pattern { control("compressor", value) }
    public func compressorAttack(_ value: PatternValue) -> Pattern { control("compressorAttack", value) }
    public func compressorKnee(_ value: PatternValue) -> Pattern { control("compressorKnee", value) }
    public func compressorRatio(_ value: PatternValue) -> Pattern { control("compressorRatio", value) }
    public func compressorRelease(_ value: PatternValue) -> Pattern { control("compressorRelease", value) }
    public func cps(_ value: PatternValue) -> Pattern { control("cps", value) }
    public func crush(_ value: PatternValue) -> Pattern { control("crush", value) }
    public func ctf(_ value: PatternValue) -> Pattern { control("cutoff", value) }
    public func ctlNum(_ value: PatternValue) -> Pattern { control("ctlNum", value) }
    public func ctranspose(_ value: PatternValue) -> Pattern { control("ctranspose", value) }
    public func curve(_ value: PatternValue) -> Pattern { control("curve", value) }
    public func cut(_ value: PatternValue) -> Pattern { control("cut", value) }
    public func cutoff(_ value: PatternValue) -> Pattern { control("cutoff", value) }
    public func datt(_ value: PatternValue) -> Pattern { control("duckattack", value) }
    public func dec(_ value: PatternValue) -> Pattern { control("decay", value) }
    public func decay(_ value: PatternValue) -> Pattern { control("decay", value) }
    public func degree(_ value: PatternValue) -> Pattern { control("degree", value) }
    public func delay(_ value: PatternValue) -> Pattern { control("delay", value) }
    public func delayfb(_ value: PatternValue) -> Pattern { control("delayfeedback", value) }
    public func delayfeedback(_ value: PatternValue) -> Pattern { control("delayfeedback", value) }
    public func delays(_ value: PatternValue) -> Pattern { control("delaysync", value) }
    public func delayspeed(_ value: PatternValue) -> Pattern { control("delayspeed", value) }
    public func delaysync(_ value: PatternValue) -> Pattern { control("delaysync", value) }
    public func delayt(_ value: PatternValue) -> Pattern { control("delaytime", value) }
    public func delaytime(_ value: PatternValue) -> Pattern { control("delaytime", value) }
    public func deltaSlide(_ value: PatternValue) -> Pattern { control("deltaSlide", value) }
    // "density" collides with an engine method; use .control("density", v)
    public func det(_ value: PatternValue) -> Pattern { control("detune", value) }
    public func detune(_ value: PatternValue) -> Pattern { control("detune", value) }
    public func dfb(_ value: PatternValue) -> Pattern { control("delayfeedback", value) }
    public func dict(_ value: PatternValue) -> Pattern { control("dictionary", value) }
    public func dictionary(_ value: PatternValue) -> Pattern { control("dictionary", value) }
    public func dist(_ value: PatternValue) -> Pattern { control("distort", value) }
    public func distort(_ value: PatternValue) -> Pattern { control("distort", value) }
    public func distorttype(_ value: PatternValue) -> Pattern { control("distorttype", value) }
    public func distortvol(_ value: PatternValue) -> Pattern { control("distortvol", value) }
    public func disttype(_ value: PatternValue) -> Pattern { control("distorttype", value) }
    public func distvol(_ value: PatternValue) -> Pattern { control("distortvol", value) }
    public func djf(_ value: PatternValue) -> Pattern { control("djf", value) }
    public func drive(_ value: PatternValue) -> Pattern { control("drive", value) }
    public func dry(_ value: PatternValue) -> Pattern { control("dry", value) }
    public func ds(_ value: PatternValue) -> Pattern { control("delaysync", value) }
    public func dt(_ value: PatternValue) -> Pattern { control("delaytime", value) }
    public func duck(_ value: PatternValue) -> Pattern { control("duckorbit", value) }
    public func duckatt(_ value: PatternValue) -> Pattern { control("duckattack", value) }
    public func duckattack(_ value: PatternValue) -> Pattern { control("duckattack", value) }
    public func duckdepth(_ value: PatternValue) -> Pattern { control("duckdepth", value) }
    public func duckons(_ value: PatternValue) -> Pattern { control("duckonset", value) }
    public func duckonset(_ value: PatternValue) -> Pattern { control("duckonset", value) }
    public func duckorbit(_ value: PatternValue) -> Pattern { control("duckorbit", value) }
    public func dur(_ value: PatternValue) -> Pattern { control("duration", value) }
    public func duration(_ value: PatternValue) -> Pattern { control("duration", value) }
    public func end(_ value: PatternValue) -> Pattern { control("end", value) }
    public func enhance(_ value: PatternValue) -> Pattern { control("enhance", value) }
    public func expression(_ value: PatternValue) -> Pattern { control("expression", value) }
    public func fadeInTime(_ value: PatternValue) -> Pattern { control("fadeInTime", value) }
    public func fadeOutTime(_ value: PatternValue) -> Pattern { control("fadeTime", value) }
    public func fadeTime(_ value: PatternValue) -> Pattern { control("fadeTime", value) }
    public func fanchor(_ value: PatternValue) -> Pattern { control("fanchor", value) }
    public func fft(_ value: PatternValue) -> Pattern { control("fft", value) }
    public func fm(_ value: PatternValue) -> Pattern { control("fmi", value) }
    public func fm1(_ value: PatternValue) -> Pattern { control("fmi", value) }
    public func fm2(_ value: PatternValue) -> Pattern { control("fmi2", value) }
    public func fm3(_ value: PatternValue) -> Pattern { control("fmi3", value) }
    public func fm4(_ value: PatternValue) -> Pattern { control("fmi4", value) }
    public func fm5(_ value: PatternValue) -> Pattern { control("fmi5", value) }
    public func fm6(_ value: PatternValue) -> Pattern { control("fmi6", value) }
    public func fm7(_ value: PatternValue) -> Pattern { control("fmi7", value) }
    public func fm8(_ value: PatternValue) -> Pattern { control("fmi8", value) }
    public func fmatt(_ value: PatternValue) -> Pattern { control("fmattack", value) }
    public func fmatt1(_ value: PatternValue) -> Pattern { control("fmattack", value) }
    public func fmatt2(_ value: PatternValue) -> Pattern { control("fmattack2", value) }
    public func fmatt3(_ value: PatternValue) -> Pattern { control("fmattack3", value) }
    public func fmatt4(_ value: PatternValue) -> Pattern { control("fmattack4", value) }
    public func fmatt5(_ value: PatternValue) -> Pattern { control("fmattack5", value) }
    public func fmatt6(_ value: PatternValue) -> Pattern { control("fmattack6", value) }
    public func fmatt7(_ value: PatternValue) -> Pattern { control("fmattack7", value) }
    public func fmatt8(_ value: PatternValue) -> Pattern { control("fmattack8", value) }
    public func fmattack(_ value: PatternValue) -> Pattern { control("fmattack", value) }
    public func fmattack1(_ value: PatternValue) -> Pattern { control("fmattack", value) }
    public func fmattack2(_ value: PatternValue) -> Pattern { control("fmattack2", value) }
    public func fmattack3(_ value: PatternValue) -> Pattern { control("fmattack3", value) }
    public func fmattack4(_ value: PatternValue) -> Pattern { control("fmattack4", value) }
    public func fmattack5(_ value: PatternValue) -> Pattern { control("fmattack5", value) }
    public func fmattack6(_ value: PatternValue) -> Pattern { control("fmattack6", value) }
    public func fmattack7(_ value: PatternValue) -> Pattern { control("fmattack7", value) }
    public func fmattack8(_ value: PatternValue) -> Pattern { control("fmattack8", value) }
    public func fmdec(_ value: PatternValue) -> Pattern { control("fmdecay", value) }
    public func fmdec1(_ value: PatternValue) -> Pattern { control("fmdecay", value) }
    public func fmdec2(_ value: PatternValue) -> Pattern { control("fmdecay2", value) }
    public func fmdec3(_ value: PatternValue) -> Pattern { control("fmdecay3", value) }
    public func fmdec4(_ value: PatternValue) -> Pattern { control("fmdecay4", value) }
    public func fmdec5(_ value: PatternValue) -> Pattern { control("fmdecay5", value) }
    public func fmdec6(_ value: PatternValue) -> Pattern { control("fmdecay6", value) }
    public func fmdec7(_ value: PatternValue) -> Pattern { control("fmdecay7", value) }
    public func fmdec8(_ value: PatternValue) -> Pattern { control("fmdecay8", value) }
    public func fmdecay(_ value: PatternValue) -> Pattern { control("fmdecay", value) }
    public func fmdecay1(_ value: PatternValue) -> Pattern { control("fmdecay", value) }
    public func fmdecay2(_ value: PatternValue) -> Pattern { control("fmdecay2", value) }
    public func fmdecay3(_ value: PatternValue) -> Pattern { control("fmdecay3", value) }
    public func fmdecay4(_ value: PatternValue) -> Pattern { control("fmdecay4", value) }
    public func fmdecay5(_ value: PatternValue) -> Pattern { control("fmdecay5", value) }
    public func fmdecay6(_ value: PatternValue) -> Pattern { control("fmdecay6", value) }
    public func fmdecay7(_ value: PatternValue) -> Pattern { control("fmdecay7", value) }
    public func fmdecay8(_ value: PatternValue) -> Pattern { control("fmdecay8", value) }
    public func fme(_ value: PatternValue) -> Pattern { control("fmenv", value) }
    public func fme1(_ value: PatternValue) -> Pattern { control("fmenv", value) }
    public func fme2(_ value: PatternValue) -> Pattern { control("fmenv2", value) }
    public func fme3(_ value: PatternValue) -> Pattern { control("fmenv3", value) }
    public func fme4(_ value: PatternValue) -> Pattern { control("fmenv4", value) }
    public func fme5(_ value: PatternValue) -> Pattern { control("fmenv5", value) }
    public func fme6(_ value: PatternValue) -> Pattern { control("fmenv6", value) }
    public func fme7(_ value: PatternValue) -> Pattern { control("fmenv7", value) }
    public func fme8(_ value: PatternValue) -> Pattern { control("fmenv8", value) }
    public func fmenv(_ value: PatternValue) -> Pattern { control("fmenv", value) }
    public func fmenv1(_ value: PatternValue) -> Pattern { control("fmenv", value) }
    public func fmenv2(_ value: PatternValue) -> Pattern { control("fmenv2", value) }
    public func fmenv3(_ value: PatternValue) -> Pattern { control("fmenv3", value) }
    public func fmenv4(_ value: PatternValue) -> Pattern { control("fmenv4", value) }
    public func fmenv5(_ value: PatternValue) -> Pattern { control("fmenv5", value) }
    public func fmenv6(_ value: PatternValue) -> Pattern { control("fmenv6", value) }
    public func fmenv7(_ value: PatternValue) -> Pattern { control("fmenv7", value) }
    public func fmenv8(_ value: PatternValue) -> Pattern { control("fmenv8", value) }
    public func fmh(_ value: PatternValue) -> Pattern { control("fmh", value) }
    public func fmh1(_ value: PatternValue) -> Pattern { control("fmh", value) }
    public func fmh2(_ value: PatternValue) -> Pattern { control("fmh2", value) }
    public func fmh3(_ value: PatternValue) -> Pattern { control("fmh3", value) }
    public func fmh4(_ value: PatternValue) -> Pattern { control("fmh4", value) }
    public func fmh5(_ value: PatternValue) -> Pattern { control("fmh5", value) }
    public func fmh6(_ value: PatternValue) -> Pattern { control("fmh6", value) }
    public func fmh7(_ value: PatternValue) -> Pattern { control("fmh7", value) }
    public func fmh8(_ value: PatternValue) -> Pattern { control("fmh8", value) }
    public func fmi(_ value: PatternValue) -> Pattern { control("fmi", value) }
    public func fmi1(_ value: PatternValue) -> Pattern { control("fmh", value) }
    public func fmi2(_ value: PatternValue) -> Pattern { control("fmi2", value) }
    public func fmi3(_ value: PatternValue) -> Pattern { control("fmi3", value) }
    public func fmi4(_ value: PatternValue) -> Pattern { control("fmi4", value) }
    public func fmi5(_ value: PatternValue) -> Pattern { control("fmi5", value) }
    public func fmi6(_ value: PatternValue) -> Pattern { control("fmi6", value) }
    public func fmi7(_ value: PatternValue) -> Pattern { control("fmi7", value) }
    public func fmi8(_ value: PatternValue) -> Pattern { control("fmi8", value) }
    public func fmrel(_ value: PatternValue) -> Pattern { control("fmrelease", value) }
    public func fmrel1(_ value: PatternValue) -> Pattern { control("fmrelease", value) }
    public func fmrel2(_ value: PatternValue) -> Pattern { control("fmrelease2", value) }
    public func fmrel3(_ value: PatternValue) -> Pattern { control("fmrelease3", value) }
    public func fmrel4(_ value: PatternValue) -> Pattern { control("fmrelease4", value) }
    public func fmrel5(_ value: PatternValue) -> Pattern { control("fmrelease5", value) }
    public func fmrel6(_ value: PatternValue) -> Pattern { control("fmrelease6", value) }
    public func fmrel7(_ value: PatternValue) -> Pattern { control("fmrelease7", value) }
    public func fmrel8(_ value: PatternValue) -> Pattern { control("fmrelease8", value) }
    public func fmrelease(_ value: PatternValue) -> Pattern { control("fmrelease", value) }
    public func fmrelease1(_ value: PatternValue) -> Pattern { control("fmrelease", value) }
    public func fmrelease2(_ value: PatternValue) -> Pattern { control("fmrelease2", value) }
    public func fmrelease3(_ value: PatternValue) -> Pattern { control("fmrelease3", value) }
    public func fmrelease4(_ value: PatternValue) -> Pattern { control("fmrelease4", value) }
    public func fmrelease5(_ value: PatternValue) -> Pattern { control("fmrelease5", value) }
    public func fmrelease6(_ value: PatternValue) -> Pattern { control("fmrelease6", value) }
    public func fmrelease7(_ value: PatternValue) -> Pattern { control("fmrelease7", value) }
    public func fmrelease8(_ value: PatternValue) -> Pattern { control("fmrelease8", value) }
    public func fmsus(_ value: PatternValue) -> Pattern { control("fmsustain", value) }
    public func fmsus1(_ value: PatternValue) -> Pattern { control("fmsustain", value) }
    public func fmsus2(_ value: PatternValue) -> Pattern { control("fmsustain2", value) }
    public func fmsus3(_ value: PatternValue) -> Pattern { control("fmsustain3", value) }
    public func fmsus4(_ value: PatternValue) -> Pattern { control("fmsustain4", value) }
    public func fmsus5(_ value: PatternValue) -> Pattern { control("fmsustain5", value) }
    public func fmsus6(_ value: PatternValue) -> Pattern { control("fmsustain6", value) }
    public func fmsus7(_ value: PatternValue) -> Pattern { control("fmsustain7", value) }
    public func fmsus8(_ value: PatternValue) -> Pattern { control("fmsustain8", value) }
    public func fmsustain(_ value: PatternValue) -> Pattern { control("fmsustain", value) }
    public func fmsustain1(_ value: PatternValue) -> Pattern { control("fmsustain", value) }
    public func fmsustain2(_ value: PatternValue) -> Pattern { control("fmsustain2", value) }
    public func fmsustain3(_ value: PatternValue) -> Pattern { control("fmsustain3", value) }
    public func fmsustain4(_ value: PatternValue) -> Pattern { control("fmsustain4", value) }
    public func fmsustain5(_ value: PatternValue) -> Pattern { control("fmsustain5", value) }
    public func fmsustain6(_ value: PatternValue) -> Pattern { control("fmsustain6", value) }
    public func fmsustain7(_ value: PatternValue) -> Pattern { control("fmsustain7", value) }
    public func fmsustain8(_ value: PatternValue) -> Pattern { control("fmsustain8", value) }
    public func fmwave(_ value: PatternValue) -> Pattern { control("fmwave", value) }
    public func fmwave1(_ value: PatternValue) -> Pattern { control("fmwave", value) }
    public func fmwave2(_ value: PatternValue) -> Pattern { control("fmwave2", value) }
    public func fmwave3(_ value: PatternValue) -> Pattern { control("fmwave3", value) }
    public func fmwave4(_ value: PatternValue) -> Pattern { control("fmwave4", value) }
    public func fmwave5(_ value: PatternValue) -> Pattern { control("fmwave5", value) }
    public func fmwave6(_ value: PatternValue) -> Pattern { control("fmwave6", value) }
    public func fmwave7(_ value: PatternValue) -> Pattern { control("fmwave7", value) }
    public func fmwave8(_ value: PatternValue) -> Pattern { control("fmwave8", value) }
    public func frameRate(_ value: PatternValue) -> Pattern { control("frameRate", value) }
    public func frames(_ value: PatternValue) -> Pattern { control("frames", value) }
    public func freeze(_ value: PatternValue) -> Pattern { control("freeze", value) }
    public func freq(_ value: PatternValue) -> Pattern { control("freq", value) }
    public func fshift(_ value: PatternValue) -> Pattern { control("fshift", value) }
    public func fshiftnote(_ value: PatternValue) -> Pattern { control("fshiftnote", value) }
    public func fshiftphase(_ value: PatternValue) -> Pattern { control("fshiftphase", value) }
    public func ftype(_ value: PatternValue) -> Pattern { control("ftype", value) }
    public func fxr(_ value: PatternValue) -> Pattern { control("FXrelease", value) }
    public func gain(_ value: PatternValue) -> Pattern { control("gain", value) }
    public func gat(_ value: PatternValue) -> Pattern { control("gate", value) }
    public func gate(_ value: PatternValue) -> Pattern { control("gate", value) }
    public func harmonic(_ value: PatternValue) -> Pattern { control("harmonic", value) }
    public func hbrick(_ value: PatternValue) -> Pattern { control("hbrick", value) }
    public func hcutoff(_ value: PatternValue) -> Pattern { control("hcutoff", value) }
    public func hold(_ value: PatternValue) -> Pattern { control("hold", value) }
    public func hours(_ value: PatternValue) -> Pattern { control("hours", value) }
    public func hp(_ value: PatternValue) -> Pattern { control("hcutoff", value) }
    public func hpa(_ value: PatternValue) -> Pattern { control("hpattack", value) }
    public func hpattack(_ value: PatternValue) -> Pattern { control("hpattack", value) }
    public func hpd(_ value: PatternValue) -> Pattern { control("hpdecay", value) }
    public func hpdc(_ value: PatternValue) -> Pattern { control("hpdc", value) }
    public func hpdecay(_ value: PatternValue) -> Pattern { control("hpdecay", value) }
    public func hpdepth(_ value: PatternValue) -> Pattern { control("hpdepth", value) }
    public func hpdepthfreq(_ value: PatternValue) -> Pattern { control("hpdepthfrequency", value) }
    public func hpdepthfrequency(_ value: PatternValue) -> Pattern { control("hpdepthfrequency", value) }
    public func hpe(_ value: PatternValue) -> Pattern { control("hpenv", value) }
    public func hpenv(_ value: PatternValue) -> Pattern { control("hpenv", value) }
    public func hpf(_ value: PatternValue) -> Pattern { control("hcutoff", value) }
    public func hpq(_ value: PatternValue) -> Pattern { control("hresonance", value) }
    public func hpr(_ value: PatternValue) -> Pattern { control("hprelease", value) }
    public func hprate(_ value: PatternValue) -> Pattern { control("hprate", value) }
    public func hprelease(_ value: PatternValue) -> Pattern { control("hprelease", value) }
    public func hps(_ value: PatternValue) -> Pattern { control("hpsustain", value) }
    public func hpshape(_ value: PatternValue) -> Pattern { control("hpshape", value) }
    public func hpskew(_ value: PatternValue) -> Pattern { control("hpskew", value) }
    public func hpsustain(_ value: PatternValue) -> Pattern { control("hpsustain", value) }
    public func hpsync(_ value: PatternValue) -> Pattern { control("hpsync", value) }
    public func hresonance(_ value: PatternValue) -> Pattern { control("hresonance", value) }
    public func i(_ value: PatternValue) -> Pattern { control("i", value) }
    public func imag(_ value: PatternValue) -> Pattern { control("imag", value) }
    public func ir(_ value: PatternValue) -> Pattern { control("ir", value) }
    public func irbegin(_ value: PatternValue) -> Pattern { control("irbegin", value) }
    public func iresponse(_ value: PatternValue) -> Pattern { control("ir", value) }
    public func irspeed(_ value: PatternValue) -> Pattern { control("irspeed", value) }
    public func kcutoff(_ value: PatternValue) -> Pattern { control("kcutoff", value) }
    public func krush(_ value: PatternValue) -> Pattern { control("krush", value) }
    public func label(_ value: PatternValue) -> Pattern { control("label", value) }
    public func lbrick(_ value: PatternValue) -> Pattern { control("lbrick", value) }
    public func legato(_ value: PatternValue) -> Pattern { control("clip", value) }
    public func leslie(_ value: PatternValue) -> Pattern { control("leslie", value) }
    public func lock(_ value: PatternValue) -> Pattern { control("lock", value) }
    public func loop(_ value: PatternValue) -> Pattern { control("loop", value) }
    public func loopBegin(_ value: PatternValue) -> Pattern { control("loopBegin", value) }
    public func loopEnd(_ value: PatternValue) -> Pattern { control("loopEnd", value) }
    public func loopb(_ value: PatternValue) -> Pattern { control("loopBegin", value) }
    public func loope(_ value: PatternValue) -> Pattern { control("loopEnd", value) }
    public func lp(_ value: PatternValue) -> Pattern { control("cutoff", value) }
    public func lpa(_ value: PatternValue) -> Pattern { control("lpattack", value) }
    public func lpattack(_ value: PatternValue) -> Pattern { control("lpattack", value) }
    public func lpd(_ value: PatternValue) -> Pattern { control("lpdecay", value) }
    public func lpdc(_ value: PatternValue) -> Pattern { control("lpdc", value) }
    public func lpdecay(_ value: PatternValue) -> Pattern { control("lpdecay", value) }
    public func lpdepth(_ value: PatternValue) -> Pattern { control("lpdepth", value) }
    public func lpdepthfreq(_ value: PatternValue) -> Pattern { control("lpdepthfrequency", value) }
    public func lpdepthfrequency(_ value: PatternValue) -> Pattern { control("lpdepthfrequency", value) }
    public func lpe(_ value: PatternValue) -> Pattern { control("lpenv", value) }
    public func lpenv(_ value: PatternValue) -> Pattern { control("lpenv", value) }
    public func lpf(_ value: PatternValue) -> Pattern { control("cutoff", value) }
    public func lpq(_ value: PatternValue) -> Pattern { control("resonance", value) }
    public func lpr(_ value: PatternValue) -> Pattern { control("lprelease", value) }
    public func lprate(_ value: PatternValue) -> Pattern { control("lprate", value) }
    public func lprelease(_ value: PatternValue) -> Pattern { control("lprelease", value) }
    public func lps(_ value: PatternValue) -> Pattern { control("lpsustain", value) }
    public func lpshape(_ value: PatternValue) -> Pattern { control("lpshape", value) }
    public func lpskew(_ value: PatternValue) -> Pattern { control("lpskew", value) }
    public func lpsustain(_ value: PatternValue) -> Pattern { control("lpsustain", value) }
    public func lpsync(_ value: PatternValue) -> Pattern { control("lpsync", value) }
    public func lrate(_ value: PatternValue) -> Pattern { control("lrate", value) }
    public func lsize(_ value: PatternValue) -> Pattern { control("lsize", value) }
    public func midibend(_ value: PatternValue) -> Pattern { control("midibend", value) }
    public func midichan(_ value: PatternValue) -> Pattern { control("midichan", value) }
    public func midicmd(_ value: PatternValue) -> Pattern { control("midicmd", value) }
    public func midimap(_ value: PatternValue) -> Pattern { control("midimap", value) }
    public func midiport(_ value: PatternValue) -> Pattern { control("midiport", value) }
    public func miditouch(_ value: PatternValue) -> Pattern { control("miditouch", value) }
    public func minutes(_ value: PatternValue) -> Pattern { control("minutes", value) }
    public func mode(_ value: PatternValue) -> Pattern { control("mode", value) }
    public func mtranspose(_ value: PatternValue) -> Pattern { control("mtranspose", value) }
    public func n(_ value: PatternValue) -> Pattern { control("n", value) }
    public func noise(_ value: PatternValue) -> Pattern { control("noise", value) }
    public func note(_ value: PatternValue) -> Pattern { control("note", value) }
    public func nrpnn(_ value: PatternValue) -> Pattern { control("nrpnn", value) }
    public func nrpv(_ value: PatternValue) -> Pattern { control("nrpv", value) }
    public func nudge(_ value: PatternValue) -> Pattern { control("nudge", value) }
    public func o(_ value: PatternValue) -> Pattern { control("orbit", value) }
    public func oct(_ value: PatternValue) -> Pattern { control("octave", value) }
    public func octave(_ value: PatternValue) -> Pattern { control("octave", value) }
    public func octaveR(_ value: PatternValue) -> Pattern { control("octaveR", value) }
    public func octaves(_ value: PatternValue) -> Pattern { control("octaves", value) }
    public func octer(_ value: PatternValue) -> Pattern { control("octer", value) }
    public func octersub(_ value: PatternValue) -> Pattern { control("octersub", value) }
    public func octersubsub(_ value: PatternValue) -> Pattern { control("octersubsub", value) }
    public func offset(_ value: PatternValue) -> Pattern { control("offset", value) }
    public func orbit(_ value: PatternValue) -> Pattern { control("orbit", value) }
    public func oschost(_ value: PatternValue) -> Pattern { control("oschost", value) }
    public func oscport(_ value: PatternValue) -> Pattern { control("oscport", value) }
    public func overgain(_ value: PatternValue) -> Pattern { control("overgain", value) }
    public func overshape(_ value: PatternValue) -> Pattern { control("overshape", value) }
    public func pan(_ value: PatternValue) -> Pattern { control("pan", value) }
    public func panchor(_ value: PatternValue) -> Pattern { control("panchor", value) }
    public func panorient(_ value: PatternValue) -> Pattern { control("panorient", value) }
    public func panspan(_ value: PatternValue) -> Pattern { control("panspan", value) }
    public func pansplay(_ value: PatternValue) -> Pattern { control("pansplay", value) }
    public func panwidth(_ value: PatternValue) -> Pattern { control("panwidth", value) }
    public func patt(_ value: PatternValue) -> Pattern { control("pattack", value) }
    public func pattack(_ value: PatternValue) -> Pattern { control("pattack", value) }
    public func pcurve(_ value: PatternValue) -> Pattern { control("pcurve", value) }
    public func pdec(_ value: PatternValue) -> Pattern { control("pdecay", value) }
    public func pdecay(_ value: PatternValue) -> Pattern { control("pdecay", value) }
    public func penv(_ value: PatternValue) -> Pattern { control("penv", value) }
    public func ph(_ value: PatternValue) -> Pattern { control("phaserrate", value) }
    public func phasdp(_ value: PatternValue) -> Pattern { control("phaserdepth", value) }
    public func phaser(_ value: PatternValue) -> Pattern { control("phaserrate", value) }
    public func phasercenter(_ value: PatternValue) -> Pattern { control("phasercenter", value) }
    public func phaserdepth(_ value: PatternValue) -> Pattern { control("phaserdepth", value) }
    public func phaserrate(_ value: PatternValue) -> Pattern { control("phaserrate", value) }
    public func phasersweep(_ value: PatternValue) -> Pattern { control("phasersweep", value) }
    public func phc(_ value: PatternValue) -> Pattern { control("phasercenter", value) }
    public func phd(_ value: PatternValue) -> Pattern { control("phaserdepth", value) }
    public func phs(_ value: PatternValue) -> Pattern { control("phasersweep", value) }
    public func pitchJump(_ value: PatternValue) -> Pattern { control("pitchJump", value) }
    public func pitchJumpTime(_ value: PatternValue) -> Pattern { control("pitchJumpTime", value) }
    public func polyTouch(_ value: PatternValue) -> Pattern { control("polyTouch", value) }
    public func postgain(_ value: PatternValue) -> Pattern { control("postgain", value) }
    public func prel(_ value: PatternValue) -> Pattern { control("prelease", value) }
    public func prelease(_ value: PatternValue) -> Pattern { control("prelease", value) }
    public func progNum(_ value: PatternValue) -> Pattern { control("progNum", value) }
    public func psus(_ value: PatternValue) -> Pattern { control("psustain", value) }
    public func psustain(_ value: PatternValue) -> Pattern { control("psustain", value) }
    public func pw(_ value: PatternValue) -> Pattern { control("pw", value) }
    public func pwr(_ value: PatternValue) -> Pattern { control("pwrate", value) }
    public func pwrate(_ value: PatternValue) -> Pattern { control("pwrate", value) }
    public func pws(_ value: PatternValue) -> Pattern { control("pwsweep", value) }
    public func pwsweep(_ value: PatternValue) -> Pattern { control("pwsweep", value) }
    public func rdim(_ value: PatternValue) -> Pattern { control("roomdim", value) }
    public func real(_ value: PatternValue) -> Pattern { control("real", value) }
    public func rel(_ value: PatternValue) -> Pattern { control("release", value) }
    public func release(_ value: PatternValue) -> Pattern { control("release", value) }
    public func resonance(_ value: PatternValue) -> Pattern { control("resonance", value) }
    public func rfade(_ value: PatternValue) -> Pattern { control("roomfade", value) }
    public func ring(_ value: PatternValue) -> Pattern { control("ring", value) }
    public func ringdf(_ value: PatternValue) -> Pattern { control("ringdf", value) }
    public func ringf(_ value: PatternValue) -> Pattern { control("ringf", value) }
    public func rlp(_ value: PatternValue) -> Pattern { control("roomlp", value) }
    public func room(_ value: PatternValue) -> Pattern { control("room", value) }
    public func roomdim(_ value: PatternValue) -> Pattern { control("roomdim", value) }
    public func roomfade(_ value: PatternValue) -> Pattern { control("roomfade", value) }
    public func roomlp(_ value: PatternValue) -> Pattern { control("roomlp", value) }
    public func roomsize(_ value: PatternValue) -> Pattern { control("roomsize", value) }
    public func rsize(_ value: PatternValue) -> Pattern { control("roomsize", value) }
    public func s(_ value: PatternValue) -> Pattern { control("s", value) }
    public func scram(_ value: PatternValue) -> Pattern { control("scram", value) }
    public func seconds(_ value: PatternValue) -> Pattern { control("seconds", value) }
    public func semitone(_ value: PatternValue) -> Pattern { control("semitone", value) }
    public func shape(_ value: PatternValue) -> Pattern { control("shape", value) }
    public func size(_ value: PatternValue) -> Pattern { control("roomsize", value) }
    public func slide(_ value: PatternValue) -> Pattern { control("slide", value) }
    public func smear(_ value: PatternValue) -> Pattern { control("smear", value) }
    public func songPtr(_ value: PatternValue) -> Pattern { control("songPtr", value) }
    public func sound(_ value: PatternValue) -> Pattern { control("s", value) }
    public func source(_ value: PatternValue) -> Pattern { control("source", value) }
    public func speed(_ value: PatternValue) -> Pattern { control("speed", value) }
    public func spread(_ value: PatternValue) -> Pattern { control("spread", value) }
    public func squiz(_ value: PatternValue) -> Pattern { control("squiz", value) }
    public func src(_ value: PatternValue) -> Pattern { control("source", value) }
    public func stepsPerOctave(_ value: PatternValue) -> Pattern { control("stepsPerOctave", value) }
    public func stretch(_ value: PatternValue) -> Pattern { control("stretch", value) }
    public func sus(_ value: PatternValue) -> Pattern { control("sustain", value) }
    public func sustain(_ value: PatternValue) -> Pattern { control("sustain", value) }
    public func sustainpedal(_ value: PatternValue) -> Pattern { control("sustainpedal", value) }
    public func sysexdata(_ value: PatternValue) -> Pattern { control("sysexdata", value) }
    public func sysexid(_ value: PatternValue) -> Pattern { control("sysexid", value) }
    public func sz(_ value: PatternValue) -> Pattern { control("roomsize", value) }
    public func transient(_ value: PatternValue) -> Pattern { control("transient", value) }
    public func trem(_ value: PatternValue) -> Pattern { control("tremolo", value) }
    public func tremdepth(_ value: PatternValue) -> Pattern { control("tremolodepth", value) }
    public func tremolo(_ value: PatternValue) -> Pattern { control("tremolo", value) }
    public func tremolodepth(_ value: PatternValue) -> Pattern { control("tremolodepth", value) }
    public func tremolophase(_ value: PatternValue) -> Pattern { control("tremolophase", value) }
    public func tremoloshape(_ value: PatternValue) -> Pattern { control("tremoloshape", value) }
    public func tremoloskew(_ value: PatternValue) -> Pattern { control("tremoloskew", value) }
    public func tremolosync(_ value: PatternValue) -> Pattern { control("tremolosync", value) }
    public func tremphase(_ value: PatternValue) -> Pattern { control("tremolophase", value) }
    public func tremshape(_ value: PatternValue) -> Pattern { control("tremoloshape", value) }
    public func tremskew(_ value: PatternValue) -> Pattern { control("tremoloskew", value) }
    public func tremsync(_ value: PatternValue) -> Pattern { control("tremolosync", value) }
    public func triode(_ value: PatternValue) -> Pattern { control("triode", value) }
    public func tsdelay(_ value: PatternValue) -> Pattern { control("tsdelay", value) }
    public func uid(_ value: PatternValue) -> Pattern { control("uid", value) }
    public func unison(_ value: PatternValue) -> Pattern { control("unison", value) }
    public func unit(_ value: PatternValue) -> Pattern { control("unit", value) }
    public func v(_ value: PatternValue) -> Pattern { control("vib", value) }
    public func val(_ value: PatternValue) -> Pattern { control("val", value) }
    public func vel(_ value: PatternValue) -> Pattern { control("velocity", value) }
    public func velocity(_ value: PatternValue) -> Pattern { control("velocity", value) }
    public func vib(_ value: PatternValue) -> Pattern { control("vib", value) }
    public func vibmod(_ value: PatternValue) -> Pattern { control("vibmod", value) }
    public func vibrato(_ value: PatternValue) -> Pattern { control("vib", value) }
    public func vmod(_ value: PatternValue) -> Pattern { control("vibmod", value) }
    public func voice(_ value: PatternValue) -> Pattern { control("voice", value) }
    public func vowel(_ value: PatternValue) -> Pattern { control("vowel", value) }
    public func warp(_ value: PatternValue) -> Pattern { control("warp", value) }
    public func warpatt(_ value: PatternValue) -> Pattern { control("warpattack", value) }
    public func warpattack(_ value: PatternValue) -> Pattern { control("warpattack", value) }
    public func warpdc(_ value: PatternValue) -> Pattern { control("warpdc", value) }
    public func warpdec(_ value: PatternValue) -> Pattern { control("warpdecay", value) }
    public func warpdecay(_ value: PatternValue) -> Pattern { control("warpdecay", value) }
    public func warpdepth(_ value: PatternValue) -> Pattern { control("warpdepth", value) }
    public func warpenv(_ value: PatternValue) -> Pattern { control("warpenv", value) }
    public func warpmode(_ value: PatternValue) -> Pattern { control("warpmode", value) }
    public func warprate(_ value: PatternValue) -> Pattern { control("warprate", value) }
    public func warprel(_ value: PatternValue) -> Pattern { control("warprelease", value) }
    public func warprelease(_ value: PatternValue) -> Pattern { control("warprelease", value) }
    public func warpshape(_ value: PatternValue) -> Pattern { control("warpshape", value) }
    public func warpskew(_ value: PatternValue) -> Pattern { control("warpskew", value) }
    public func warpsus(_ value: PatternValue) -> Pattern { control("warpsustain", value) }
    public func warpsustain(_ value: PatternValue) -> Pattern { control("warpsustain", value) }
    public func warpsync(_ value: PatternValue) -> Pattern { control("warpsync", value) }
    public func waveloss(_ value: PatternValue) -> Pattern { control("waveloss", value) }
    public func wavetablePhaseRand(_ value: PatternValue) -> Pattern { control("wtphaserand", value) }
    public func wavetablePosition(_ value: PatternValue) -> Pattern { control("wt", value) }
    public func wavetableWarp(_ value: PatternValue) -> Pattern { control("warp", value) }
    public func wavetableWarpMode(_ value: PatternValue) -> Pattern { control("warpmode", value) }
    public func wt(_ value: PatternValue) -> Pattern { control("wt", value) }
    public func wtatt(_ value: PatternValue) -> Pattern { control("wtattack", value) }
    public func wtattack(_ value: PatternValue) -> Pattern { control("wtattack", value) }
    public func wtdc(_ value: PatternValue) -> Pattern { control("wtdc", value) }
    public func wtdec(_ value: PatternValue) -> Pattern { control("wtdecay", value) }
    public func wtdecay(_ value: PatternValue) -> Pattern { control("wtdecay", value) }
    public func wtdepth(_ value: PatternValue) -> Pattern { control("wtdepth", value) }
    public func wtenv(_ value: PatternValue) -> Pattern { control("wtenv", value) }
    public func wtphaserand(_ value: PatternValue) -> Pattern { control("wtphaserand", value) }
    public func wtrate(_ value: PatternValue) -> Pattern { control("wtrate", value) }
    public func wtrel(_ value: PatternValue) -> Pattern { control("wtrelease", value) }
    public func wtrelease(_ value: PatternValue) -> Pattern { control("wtrelease", value) }
    public func wtshape(_ value: PatternValue) -> Pattern { control("wtshape", value) }
    public func wtskew(_ value: PatternValue) -> Pattern { control("wtskew", value) }
    public func wtsus(_ value: PatternValue) -> Pattern { control("wtsustain", value) }
    public func wtsustain(_ value: PatternValue) -> Pattern { control("wtsustain", value) }
    public func wtsync(_ value: PatternValue) -> Pattern { control("wtsync", value) }
    public func xsdelay(_ value: PatternValue) -> Pattern { control("xsdelay", value) }
    public func zcrush(_ value: PatternValue) -> Pattern { control("zcrush", value) }
    public func zdelay(_ value: PatternValue) -> Pattern { control("zdelay", value) }
    public func zmod(_ value: PatternValue) -> Pattern { control("zmod", value) }
    public func znoise(_ value: PatternValue) -> Pattern { control("znoise", value) }
    public func zrand(_ value: PatternValue) -> Pattern { control("zrand", value) }
    public func zzfx(_ value: PatternValue) -> Pattern { control("zzfx", value) }
}

// MARK: - Generated top-level control functions

public func FXr(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["FXrelease"] ?? ["FXrelease"], value) }
public func FXrel(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["FXrelease"] ?? ["FXrelease"], value) }
public func FXrelease(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["FXrelease"] ?? ["FXrelease"], value) }
public func accelerate(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["accelerate"] ?? ["accelerate"], value) }
public func activeLabel(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["activeLabel"] ?? ["activeLabel"], value) }
public func amp(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["amp"] ?? ["amp"], value) }
public func analyze(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["analyze"] ?? ["analyze"], value) }
public func anchor(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["anchor"] ?? ["anchor"], value) }
public func att(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["attack"] ?? ["attack"], value) }
public func attack(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["attack"] ?? ["attack"], value) }
public func bandf(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["bandf"] ?? ["bandf"], value) }
public func bandq(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["bandq"] ?? ["bandq"], value) }
public func bank(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["bank"] ?? ["bank"], value) }
public func bb(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["byteBeatExpression"] ?? ["byteBeatExpression"], value) }
public func bbexpr(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["byteBeatExpression"] ?? ["byteBeatExpression"], value) }
public func bbst(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["byteBeatStartTime"] ?? ["byteBeatStartTime"], value) }
public func begin(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["begin"] ?? ["begin"], value) }
public func bgain(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["busgain"] ?? ["busgain"], value) }
public func binshift(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["binshift"] ?? ["binshift"], value) }
public func bp(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["bandf"] ?? ["bandf"], value) }
public func bpa(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["bpattack"] ?? ["bpattack"], value) }
public func bpattack(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["bpattack"] ?? ["bpattack"], value) }
public func bpd(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["bpdecay"] ?? ["bpdecay"], value) }
public func bpdc(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["bpdc"] ?? ["bpdc"], value) }
public func bpdecay(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["bpdecay"] ?? ["bpdecay"], value) }
public func bpdepth(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["bpdepth"] ?? ["bpdepth"], value) }
public func bpdepthfreq(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["bpdepthfrequency"] ?? ["bpdepthfrequency"], value) }
public func bpdepthfrequency(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["bpdepthfrequency"] ?? ["bpdepthfrequency"], value) }
public func bpe(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["bpenv"] ?? ["bpenv"], value) }
public func bpenv(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["bpenv"] ?? ["bpenv"], value) }
public func bpf(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["bandf"] ?? ["bandf"], value) }
public func bpq(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["bandq"] ?? ["bandq"], value) }
public func bpr(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["bprelease"] ?? ["bprelease"], value) }
public func bprate(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["bprate"] ?? ["bprate"], value) }
public func bprelease(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["bprelease"] ?? ["bprelease"], value) }
public func bps(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["bpsustain"] ?? ["bpsustain"], value) }
public func bpshape(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["bpshape"] ?? ["bpshape"], value) }
public func bpskew(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["bpskew"] ?? ["bpskew"], value) }
public func bpsustain(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["bpsustain"] ?? ["bpsustain"], value) }
public func bpsync(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["bpsync"] ?? ["bpsync"], value) }
public func bus(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["bus"] ?? ["bus"], value) }
public func busgain(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["busgain"] ?? ["busgain"], value) }
public func byteBeatExpression(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["byteBeatExpression"] ?? ["byteBeatExpression"], value) }
public func byteBeatStartTime(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["byteBeatStartTime"] ?? ["byteBeatStartTime"], value) }
public func ccn(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["ccn"] ?? ["ccn"], value) }
public func ccv(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["ccv"] ?? ["ccv"], value) }
public func ch(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["channels"] ?? ["channels"], value) }
public func channel(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["channel"] ?? ["channel"], value) }
public func channels(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["channels"] ?? ["channels"], value) }
public func chord(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["chord"] ?? ["chord"], value) }
public func chorus(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["chorus"] ?? ["chorus"], value) }
public func clip(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["clip"] ?? ["clip"], value) }
public func coarse(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["coarse"] ?? ["coarse"], value) }
public func color(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["color"] ?? ["color"], value) }
public func comb(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["comb"] ?? ["comb"], value) }
public func compressor(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["compressor"] ?? ["compressor"], value) }
public func compressorAttack(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["compressorAttack"] ?? ["compressorAttack"], value) }
public func compressorKnee(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["compressorKnee"] ?? ["compressorKnee"], value) }
public func compressorRatio(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["compressorRatio"] ?? ["compressorRatio"], value) }
public func compressorRelease(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["compressorRelease"] ?? ["compressorRelease"], value) }
public func cps(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["cps"] ?? ["cps"], value) }
public func crush(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["crush"] ?? ["crush"], value) }
public func ctf(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["cutoff"] ?? ["cutoff"], value) }
public func ctlNum(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["ctlNum"] ?? ["ctlNum"], value) }
public func ctranspose(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["ctranspose"] ?? ["ctranspose"], value) }
public func curve(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["curve"] ?? ["curve"], value) }
public func cut(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["cut"] ?? ["cut"], value) }
public func cutoff(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["cutoff"] ?? ["cutoff"], value) }
public func datt(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["duckattack"] ?? ["duckattack"], value) }
public func dec(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["decay"] ?? ["decay"], value) }
public func decay(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["decay"] ?? ["decay"], value) }
public func degree(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["degree"] ?? ["degree"], value) }
public func delay(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["delay"] ?? ["delay"], value) }
public func delayfb(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["delayfeedback"] ?? ["delayfeedback"], value) }
public func delayfeedback(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["delayfeedback"] ?? ["delayfeedback"], value) }
public func delays(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["delaysync"] ?? ["delaysync"], value) }
public func delayspeed(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["delayspeed"] ?? ["delayspeed"], value) }
public func delaysync(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["delaysync"] ?? ["delaysync"], value) }
public func delayt(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["delaytime"] ?? ["delaytime"], value) }
public func delaytime(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["delaytime"] ?? ["delaytime"], value) }
public func deltaSlide(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["deltaSlide"] ?? ["deltaSlide"], value) }
public func density(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["density"] ?? ["density"], value) }
public func det(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["detune"] ?? ["detune"], value) }
public func detune(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["detune"] ?? ["detune"], value) }
public func dfb(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["delayfeedback"] ?? ["delayfeedback"], value) }
public func dict(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["dictionary"] ?? ["dictionary"], value) }
public func dictionary(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["dictionary"] ?? ["dictionary"], value) }
public func dist(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["distort"] ?? ["distort"], value) }
public func distort(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["distort"] ?? ["distort"], value) }
public func distorttype(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["distorttype"] ?? ["distorttype"], value) }
public func distortvol(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["distortvol"] ?? ["distortvol"], value) }
public func disttype(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["distorttype"] ?? ["distorttype"], value) }
public func distvol(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["distortvol"] ?? ["distortvol"], value) }
public func djf(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["djf"] ?? ["djf"], value) }
public func drive(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["drive"] ?? ["drive"], value) }
public func dry(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["dry"] ?? ["dry"], value) }
public func ds(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["delaysync"] ?? ["delaysync"], value) }
public func dt(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["delaytime"] ?? ["delaytime"], value) }
public func duck(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["duckorbit"] ?? ["duckorbit"], value) }
public func duckatt(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["duckattack"] ?? ["duckattack"], value) }
public func duckattack(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["duckattack"] ?? ["duckattack"], value) }
public func duckdepth(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["duckdepth"] ?? ["duckdepth"], value) }
public func duckons(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["duckonset"] ?? ["duckonset"], value) }
public func duckonset(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["duckonset"] ?? ["duckonset"], value) }
public func duckorbit(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["duckorbit"] ?? ["duckorbit"], value) }
public func dur(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["duration"] ?? ["duration"], value) }
public func duration(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["duration"] ?? ["duration"], value) }
public func end(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["end"] ?? ["end"], value) }
public func enhance(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["enhance"] ?? ["enhance"], value) }
public func expression(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["expression"] ?? ["expression"], value) }
public func fadeInTime(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fadeInTime"] ?? ["fadeInTime"], value) }
public func fadeOutTime(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fadeTime"] ?? ["fadeTime"], value) }
public func fadeTime(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fadeTime"] ?? ["fadeTime"], value) }
public func fanchor(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fanchor"] ?? ["fanchor"], value) }
public func fft(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fft"] ?? ["fft"], value) }
public func fm(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmi"] ?? ["fmi"], value) }
public func fm1(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmi"] ?? ["fmi"], value) }
public func fm2(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmi2"] ?? ["fmi2"], value) }
public func fm3(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmi3"] ?? ["fmi3"], value) }
public func fm4(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmi4"] ?? ["fmi4"], value) }
public func fm5(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmi5"] ?? ["fmi5"], value) }
public func fm6(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmi6"] ?? ["fmi6"], value) }
public func fm7(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmi7"] ?? ["fmi7"], value) }
public func fm8(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmi8"] ?? ["fmi8"], value) }
public func fmatt(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmattack"] ?? ["fmattack"], value) }
public func fmatt1(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmattack"] ?? ["fmattack"], value) }
public func fmatt2(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmattack2"] ?? ["fmattack2"], value) }
public func fmatt3(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmattack3"] ?? ["fmattack3"], value) }
public func fmatt4(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmattack4"] ?? ["fmattack4"], value) }
public func fmatt5(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmattack5"] ?? ["fmattack5"], value) }
public func fmatt6(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmattack6"] ?? ["fmattack6"], value) }
public func fmatt7(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmattack7"] ?? ["fmattack7"], value) }
public func fmatt8(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmattack8"] ?? ["fmattack8"], value) }
public func fmattack(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmattack"] ?? ["fmattack"], value) }
public func fmattack1(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmattack"] ?? ["fmattack"], value) }
public func fmattack2(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmattack2"] ?? ["fmattack2"], value) }
public func fmattack3(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmattack3"] ?? ["fmattack3"], value) }
public func fmattack4(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmattack4"] ?? ["fmattack4"], value) }
public func fmattack5(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmattack5"] ?? ["fmattack5"], value) }
public func fmattack6(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmattack6"] ?? ["fmattack6"], value) }
public func fmattack7(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmattack7"] ?? ["fmattack7"], value) }
public func fmattack8(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmattack8"] ?? ["fmattack8"], value) }
public func fmdec(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmdecay"] ?? ["fmdecay"], value) }
public func fmdec1(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmdecay"] ?? ["fmdecay"], value) }
public func fmdec2(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmdecay2"] ?? ["fmdecay2"], value) }
public func fmdec3(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmdecay3"] ?? ["fmdecay3"], value) }
public func fmdec4(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmdecay4"] ?? ["fmdecay4"], value) }
public func fmdec5(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmdecay5"] ?? ["fmdecay5"], value) }
public func fmdec6(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmdecay6"] ?? ["fmdecay6"], value) }
public func fmdec7(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmdecay7"] ?? ["fmdecay7"], value) }
public func fmdec8(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmdecay8"] ?? ["fmdecay8"], value) }
public func fmdecay(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmdecay"] ?? ["fmdecay"], value) }
public func fmdecay1(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmdecay"] ?? ["fmdecay"], value) }
public func fmdecay2(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmdecay2"] ?? ["fmdecay2"], value) }
public func fmdecay3(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmdecay3"] ?? ["fmdecay3"], value) }
public func fmdecay4(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmdecay4"] ?? ["fmdecay4"], value) }
public func fmdecay5(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmdecay5"] ?? ["fmdecay5"], value) }
public func fmdecay6(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmdecay6"] ?? ["fmdecay6"], value) }
public func fmdecay7(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmdecay7"] ?? ["fmdecay7"], value) }
public func fmdecay8(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmdecay8"] ?? ["fmdecay8"], value) }
public func fme(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmenv"] ?? ["fmenv"], value) }
public func fme1(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmenv"] ?? ["fmenv"], value) }
public func fme2(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmenv2"] ?? ["fmenv2"], value) }
public func fme3(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmenv3"] ?? ["fmenv3"], value) }
public func fme4(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmenv4"] ?? ["fmenv4"], value) }
public func fme5(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmenv5"] ?? ["fmenv5"], value) }
public func fme6(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmenv6"] ?? ["fmenv6"], value) }
public func fme7(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmenv7"] ?? ["fmenv7"], value) }
public func fme8(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmenv8"] ?? ["fmenv8"], value) }
public func fmenv(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmenv"] ?? ["fmenv"], value) }
public func fmenv1(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmenv"] ?? ["fmenv"], value) }
public func fmenv2(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmenv2"] ?? ["fmenv2"], value) }
public func fmenv3(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmenv3"] ?? ["fmenv3"], value) }
public func fmenv4(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmenv4"] ?? ["fmenv4"], value) }
public func fmenv5(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmenv5"] ?? ["fmenv5"], value) }
public func fmenv6(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmenv6"] ?? ["fmenv6"], value) }
public func fmenv7(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmenv7"] ?? ["fmenv7"], value) }
public func fmenv8(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmenv8"] ?? ["fmenv8"], value) }
public func fmh(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmh"] ?? ["fmh"], value) }
public func fmh1(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmh"] ?? ["fmh"], value) }
public func fmh2(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmh2"] ?? ["fmh2"], value) }
public func fmh3(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmh3"] ?? ["fmh3"], value) }
public func fmh4(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmh4"] ?? ["fmh4"], value) }
public func fmh5(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmh5"] ?? ["fmh5"], value) }
public func fmh6(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmh6"] ?? ["fmh6"], value) }
public func fmh7(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmh7"] ?? ["fmh7"], value) }
public func fmh8(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmh8"] ?? ["fmh8"], value) }
public func fmi(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmi"] ?? ["fmi"], value) }
public func fmi1(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmh"] ?? ["fmh"], value) }
public func fmi2(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmi2"] ?? ["fmi2"], value) }
public func fmi3(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmi3"] ?? ["fmi3"], value) }
public func fmi4(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmi4"] ?? ["fmi4"], value) }
public func fmi5(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmi5"] ?? ["fmi5"], value) }
public func fmi6(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmi6"] ?? ["fmi6"], value) }
public func fmi7(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmi7"] ?? ["fmi7"], value) }
public func fmi8(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmi8"] ?? ["fmi8"], value) }
public func fmrel(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmrelease"] ?? ["fmrelease"], value) }
public func fmrel1(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmrelease"] ?? ["fmrelease"], value) }
public func fmrel2(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmrelease2"] ?? ["fmrelease2"], value) }
public func fmrel3(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmrelease3"] ?? ["fmrelease3"], value) }
public func fmrel4(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmrelease4"] ?? ["fmrelease4"], value) }
public func fmrel5(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmrelease5"] ?? ["fmrelease5"], value) }
public func fmrel6(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmrelease6"] ?? ["fmrelease6"], value) }
public func fmrel7(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmrelease7"] ?? ["fmrelease7"], value) }
public func fmrel8(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmrelease8"] ?? ["fmrelease8"], value) }
public func fmrelease(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmrelease"] ?? ["fmrelease"], value) }
public func fmrelease1(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmrelease"] ?? ["fmrelease"], value) }
public func fmrelease2(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmrelease2"] ?? ["fmrelease2"], value) }
public func fmrelease3(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmrelease3"] ?? ["fmrelease3"], value) }
public func fmrelease4(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmrelease4"] ?? ["fmrelease4"], value) }
public func fmrelease5(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmrelease5"] ?? ["fmrelease5"], value) }
public func fmrelease6(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmrelease6"] ?? ["fmrelease6"], value) }
public func fmrelease7(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmrelease7"] ?? ["fmrelease7"], value) }
public func fmrelease8(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmrelease8"] ?? ["fmrelease8"], value) }
public func fmsus(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmsustain"] ?? ["fmsustain"], value) }
public func fmsus1(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmsustain"] ?? ["fmsustain"], value) }
public func fmsus2(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmsustain2"] ?? ["fmsustain2"], value) }
public func fmsus3(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmsustain3"] ?? ["fmsustain3"], value) }
public func fmsus4(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmsustain4"] ?? ["fmsustain4"], value) }
public func fmsus5(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmsustain5"] ?? ["fmsustain5"], value) }
public func fmsus6(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmsustain6"] ?? ["fmsustain6"], value) }
public func fmsus7(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmsustain7"] ?? ["fmsustain7"], value) }
public func fmsus8(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmsustain8"] ?? ["fmsustain8"], value) }
public func fmsustain(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmsustain"] ?? ["fmsustain"], value) }
public func fmsustain1(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmsustain"] ?? ["fmsustain"], value) }
public func fmsustain2(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmsustain2"] ?? ["fmsustain2"], value) }
public func fmsustain3(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmsustain3"] ?? ["fmsustain3"], value) }
public func fmsustain4(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmsustain4"] ?? ["fmsustain4"], value) }
public func fmsustain5(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmsustain5"] ?? ["fmsustain5"], value) }
public func fmsustain6(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmsustain6"] ?? ["fmsustain6"], value) }
public func fmsustain7(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmsustain7"] ?? ["fmsustain7"], value) }
public func fmsustain8(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmsustain8"] ?? ["fmsustain8"], value) }
public func fmwave(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmwave"] ?? ["fmwave"], value) }
public func fmwave1(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmwave"] ?? ["fmwave"], value) }
public func fmwave2(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmwave2"] ?? ["fmwave2"], value) }
public func fmwave3(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmwave3"] ?? ["fmwave3"], value) }
public func fmwave4(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmwave4"] ?? ["fmwave4"], value) }
public func fmwave5(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmwave5"] ?? ["fmwave5"], value) }
public func fmwave6(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmwave6"] ?? ["fmwave6"], value) }
public func fmwave7(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmwave7"] ?? ["fmwave7"], value) }
public func fmwave8(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fmwave8"] ?? ["fmwave8"], value) }
public func frameRate(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["frameRate"] ?? ["frameRate"], value) }
public func frames(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["frames"] ?? ["frames"], value) }
public func freeze(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["freeze"] ?? ["freeze"], value) }
public func freq(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["freq"] ?? ["freq"], value) }
public func fshift(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fshift"] ?? ["fshift"], value) }
public func fshiftnote(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fshiftnote"] ?? ["fshiftnote"], value) }
public func fshiftphase(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["fshiftphase"] ?? ["fshiftphase"], value) }
public func ftype(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["ftype"] ?? ["ftype"], value) }
public func fxr(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["FXrelease"] ?? ["FXrelease"], value) }
public func gain(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["gain"] ?? ["gain"], value) }
public func gat(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["gate"] ?? ["gate"], value) }
public func gate(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["gate"] ?? ["gate"], value) }
public func harmonic(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["harmonic"] ?? ["harmonic"], value) }
public func hbrick(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["hbrick"] ?? ["hbrick"], value) }
public func hcutoff(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["hcutoff"] ?? ["hcutoff"], value) }
public func hold(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["hold"] ?? ["hold"], value) }
public func hours(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["hours"] ?? ["hours"], value) }
public func hp(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["hcutoff"] ?? ["hcutoff"], value) }
public func hpa(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["hpattack"] ?? ["hpattack"], value) }
public func hpattack(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["hpattack"] ?? ["hpattack"], value) }
public func hpd(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["hpdecay"] ?? ["hpdecay"], value) }
public func hpdc(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["hpdc"] ?? ["hpdc"], value) }
public func hpdecay(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["hpdecay"] ?? ["hpdecay"], value) }
public func hpdepth(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["hpdepth"] ?? ["hpdepth"], value) }
public func hpdepthfreq(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["hpdepthfrequency"] ?? ["hpdepthfrequency"], value) }
public func hpdepthfrequency(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["hpdepthfrequency"] ?? ["hpdepthfrequency"], value) }
public func hpe(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["hpenv"] ?? ["hpenv"], value) }
public func hpenv(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["hpenv"] ?? ["hpenv"], value) }
public func hpf(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["hcutoff"] ?? ["hcutoff"], value) }
public func hpq(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["hresonance"] ?? ["hresonance"], value) }
public func hpr(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["hprelease"] ?? ["hprelease"], value) }
public func hprate(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["hprate"] ?? ["hprate"], value) }
public func hprelease(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["hprelease"] ?? ["hprelease"], value) }
public func hps(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["hpsustain"] ?? ["hpsustain"], value) }
public func hpshape(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["hpshape"] ?? ["hpshape"], value) }
public func hpskew(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["hpskew"] ?? ["hpskew"], value) }
public func hpsustain(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["hpsustain"] ?? ["hpsustain"], value) }
public func hpsync(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["hpsync"] ?? ["hpsync"], value) }
public func hresonance(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["hresonance"] ?? ["hresonance"], value) }
public func i(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["i"] ?? ["i"], value) }
public func imag(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["imag"] ?? ["imag"], value) }
public func ir(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["ir"] ?? ["ir"], value) }
public func irbegin(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["irbegin"] ?? ["irbegin"], value) }
public func iresponse(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["ir"] ?? ["ir"], value) }
public func irspeed(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["irspeed"] ?? ["irspeed"], value) }
public func kcutoff(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["kcutoff"] ?? ["kcutoff"], value) }
public func krush(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["krush"] ?? ["krush"], value) }
public func label(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["label"] ?? ["label"], value) }
public func lbrick(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["lbrick"] ?? ["lbrick"], value) }
public func legato(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["clip"] ?? ["clip"], value) }
public func leslie(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["leslie"] ?? ["leslie"], value) }
public func lock(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["lock"] ?? ["lock"], value) }
public func loop(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["loop"] ?? ["loop"], value) }
public func loopBegin(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["loopBegin"] ?? ["loopBegin"], value) }
public func loopEnd(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["loopEnd"] ?? ["loopEnd"], value) }
public func loopb(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["loopBegin"] ?? ["loopBegin"], value) }
public func loope(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["loopEnd"] ?? ["loopEnd"], value) }
public func lp(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["cutoff"] ?? ["cutoff"], value) }
public func lpa(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["lpattack"] ?? ["lpattack"], value) }
public func lpattack(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["lpattack"] ?? ["lpattack"], value) }
public func lpd(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["lpdecay"] ?? ["lpdecay"], value) }
public func lpdc(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["lpdc"] ?? ["lpdc"], value) }
public func lpdecay(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["lpdecay"] ?? ["lpdecay"], value) }
public func lpdepth(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["lpdepth"] ?? ["lpdepth"], value) }
public func lpdepthfreq(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["lpdepthfrequency"] ?? ["lpdepthfrequency"], value) }
public func lpdepthfrequency(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["lpdepthfrequency"] ?? ["lpdepthfrequency"], value) }
public func lpe(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["lpenv"] ?? ["lpenv"], value) }
public func lpenv(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["lpenv"] ?? ["lpenv"], value) }
public func lpf(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["cutoff"] ?? ["cutoff"], value) }
public func lpq(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["resonance"] ?? ["resonance"], value) }
public func lpr(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["lprelease"] ?? ["lprelease"], value) }
public func lprate(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["lprate"] ?? ["lprate"], value) }
public func lprelease(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["lprelease"] ?? ["lprelease"], value) }
public func lps(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["lpsustain"] ?? ["lpsustain"], value) }
public func lpshape(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["lpshape"] ?? ["lpshape"], value) }
public func lpskew(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["lpskew"] ?? ["lpskew"], value) }
public func lpsustain(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["lpsustain"] ?? ["lpsustain"], value) }
public func lpsync(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["lpsync"] ?? ["lpsync"], value) }
public func lrate(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["lrate"] ?? ["lrate"], value) }
public func lsize(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["lsize"] ?? ["lsize"], value) }
public func midibend(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["midibend"] ?? ["midibend"], value) }
public func midichan(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["midichan"] ?? ["midichan"], value) }
public func midicmd(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["midicmd"] ?? ["midicmd"], value) }
public func midimap(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["midimap"] ?? ["midimap"], value) }
public func midiport(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["midiport"] ?? ["midiport"], value) }
public func miditouch(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["miditouch"] ?? ["miditouch"], value) }
public func minutes(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["minutes"] ?? ["minutes"], value) }
public func mode(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["mode"] ?? ["mode"], value) }
public func mtranspose(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["mtranspose"] ?? ["mtranspose"], value) }
public func n(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["n"] ?? ["n"], value) }
public func noise(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["noise"] ?? ["noise"], value) }
public func note(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["note"] ?? ["note"], value) }
public func nrpnn(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["nrpnn"] ?? ["nrpnn"], value) }
public func nrpv(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["nrpv"] ?? ["nrpv"], value) }
public func nudge(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["nudge"] ?? ["nudge"], value) }
public func o(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["orbit"] ?? ["orbit"], value) }
public func oct(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["octave"] ?? ["octave"], value) }
public func octave(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["octave"] ?? ["octave"], value) }
public func octaveR(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["octaveR"] ?? ["octaveR"], value) }
public func octaves(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["octaves"] ?? ["octaves"], value) }
public func octer(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["octer"] ?? ["octer"], value) }
public func octersub(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["octersub"] ?? ["octersub"], value) }
public func octersubsub(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["octersubsub"] ?? ["octersubsub"], value) }
public func offset(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["offset"] ?? ["offset"], value) }
public func orbit(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["orbit"] ?? ["orbit"], value) }
public func oschost(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["oschost"] ?? ["oschost"], value) }
public func oscport(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["oscport"] ?? ["oscport"], value) }
public func overgain(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["overgain"] ?? ["overgain"], value) }
public func overshape(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["overshape"] ?? ["overshape"], value) }
public func pan(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["pan"] ?? ["pan"], value) }
public func panchor(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["panchor"] ?? ["panchor"], value) }
public func panorient(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["panorient"] ?? ["panorient"], value) }
public func panspan(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["panspan"] ?? ["panspan"], value) }
public func pansplay(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["pansplay"] ?? ["pansplay"], value) }
public func panwidth(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["panwidth"] ?? ["panwidth"], value) }
public func patt(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["pattack"] ?? ["pattack"], value) }
public func pattack(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["pattack"] ?? ["pattack"], value) }
public func pcurve(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["pcurve"] ?? ["pcurve"], value) }
public func pdec(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["pdecay"] ?? ["pdecay"], value) }
public func pdecay(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["pdecay"] ?? ["pdecay"], value) }
public func penv(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["penv"] ?? ["penv"], value) }
public func ph(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["phaserrate"] ?? ["phaserrate"], value) }
public func phasdp(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["phaserdepth"] ?? ["phaserdepth"], value) }
public func phaser(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["phaserrate"] ?? ["phaserrate"], value) }
public func phasercenter(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["phasercenter"] ?? ["phasercenter"], value) }
public func phaserdepth(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["phaserdepth"] ?? ["phaserdepth"], value) }
public func phaserrate(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["phaserrate"] ?? ["phaserrate"], value) }
public func phasersweep(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["phasersweep"] ?? ["phasersweep"], value) }
public func phc(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["phasercenter"] ?? ["phasercenter"], value) }
public func phd(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["phaserdepth"] ?? ["phaserdepth"], value) }
public func phs(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["phasersweep"] ?? ["phasersweep"], value) }
public func pitchJump(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["pitchJump"] ?? ["pitchJump"], value) }
public func pitchJumpTime(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["pitchJumpTime"] ?? ["pitchJumpTime"], value) }
public func polyTouch(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["polyTouch"] ?? ["polyTouch"], value) }
public func postgain(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["postgain"] ?? ["postgain"], value) }
public func prel(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["prelease"] ?? ["prelease"], value) }
public func prelease(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["prelease"] ?? ["prelease"], value) }
public func progNum(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["progNum"] ?? ["progNum"], value) }
public func psus(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["psustain"] ?? ["psustain"], value) }
public func psustain(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["psustain"] ?? ["psustain"], value) }
public func pw(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["pw"] ?? ["pw"], value) }
public func pwr(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["pwrate"] ?? ["pwrate"], value) }
public func pwrate(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["pwrate"] ?? ["pwrate"], value) }
public func pws(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["pwsweep"] ?? ["pwsweep"], value) }
public func pwsweep(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["pwsweep"] ?? ["pwsweep"], value) }
public func rdim(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["roomdim"] ?? ["roomdim"], value) }
public func real(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["real"] ?? ["real"], value) }
public func rel(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["release"] ?? ["release"], value) }
public func release(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["release"] ?? ["release"], value) }
public func resonance(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["resonance"] ?? ["resonance"], value) }
public func rfade(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["roomfade"] ?? ["roomfade"], value) }
public func ring(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["ring"] ?? ["ring"], value) }
public func ringdf(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["ringdf"] ?? ["ringdf"], value) }
public func ringf(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["ringf"] ?? ["ringf"], value) }
public func rlp(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["roomlp"] ?? ["roomlp"], value) }
public func room(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["room"] ?? ["room"], value) }
public func roomdim(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["roomdim"] ?? ["roomdim"], value) }
public func roomfade(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["roomfade"] ?? ["roomfade"], value) }
public func roomlp(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["roomlp"] ?? ["roomlp"], value) }
public func roomsize(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["roomsize"] ?? ["roomsize"], value) }
public func rsize(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["roomsize"] ?? ["roomsize"], value) }
public func s(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["s"] ?? ["s"], value) }
public func scram(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["scram"] ?? ["scram"], value) }
public func seconds(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["seconds"] ?? ["seconds"], value) }
public func semitone(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["semitone"] ?? ["semitone"], value) }
public func shape(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["shape"] ?? ["shape"], value) }
public func size(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["roomsize"] ?? ["roomsize"], value) }
public func slide(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["slide"] ?? ["slide"], value) }
public func smear(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["smear"] ?? ["smear"], value) }
public func songPtr(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["songPtr"] ?? ["songPtr"], value) }
public func sound(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["s"] ?? ["s"], value) }
public func source(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["source"] ?? ["source"], value) }
public func speed(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["speed"] ?? ["speed"], value) }
public func spread(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["spread"] ?? ["spread"], value) }
public func squiz(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["squiz"] ?? ["squiz"], value) }
public func src(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["source"] ?? ["source"], value) }
public func stepsPerOctave(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["stepsPerOctave"] ?? ["stepsPerOctave"], value) }
public func stretch(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["stretch"] ?? ["stretch"], value) }
public func sus(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["sustain"] ?? ["sustain"], value) }
public func sustain(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["sustain"] ?? ["sustain"], value) }
public func sustainpedal(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["sustainpedal"] ?? ["sustainpedal"], value) }
public func sysexdata(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["sysexdata"] ?? ["sysexdata"], value) }
public func sysexid(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["sysexid"] ?? ["sysexid"], value) }
public func sz(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["roomsize"] ?? ["roomsize"], value) }
public func transient(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["transient"] ?? ["transient"], value) }
public func trem(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["tremolo"] ?? ["tremolo"], value) }
public func tremdepth(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["tremolodepth"] ?? ["tremolodepth"], value) }
public func tremolo(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["tremolo"] ?? ["tremolo"], value) }
public func tremolodepth(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["tremolodepth"] ?? ["tremolodepth"], value) }
public func tremolophase(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["tremolophase"] ?? ["tremolophase"], value) }
public func tremoloshape(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["tremoloshape"] ?? ["tremoloshape"], value) }
public func tremoloskew(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["tremoloskew"] ?? ["tremoloskew"], value) }
public func tremolosync(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["tremolosync"] ?? ["tremolosync"], value) }
public func tremphase(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["tremolophase"] ?? ["tremolophase"], value) }
public func tremshape(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["tremoloshape"] ?? ["tremoloshape"], value) }
public func tremskew(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["tremoloskew"] ?? ["tremoloskew"], value) }
public func tremsync(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["tremolosync"] ?? ["tremolosync"], value) }
public func triode(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["triode"] ?? ["triode"], value) }
public func tsdelay(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["tsdelay"] ?? ["tsdelay"], value) }
public func uid(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["uid"] ?? ["uid"], value) }
public func unison(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["unison"] ?? ["unison"], value) }
public func unit(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["unit"] ?? ["unit"], value) }
public func v(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["vib"] ?? ["vib"], value) }
public func val(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["val"] ?? ["val"], value) }
public func vel(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["velocity"] ?? ["velocity"], value) }
public func velocity(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["velocity"] ?? ["velocity"], value) }
public func vib(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["vib"] ?? ["vib"], value) }
public func vibmod(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["vibmod"] ?? ["vibmod"], value) }
public func vibrato(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["vib"] ?? ["vib"], value) }
public func vmod(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["vibmod"] ?? ["vibmod"], value) }
public func voice(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["voice"] ?? ["voice"], value) }
public func vowel(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["vowel"] ?? ["vowel"], value) }
public func warp(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["warp"] ?? ["warp"], value) }
public func warpatt(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["warpattack"] ?? ["warpattack"], value) }
public func warpattack(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["warpattack"] ?? ["warpattack"], value) }
public func warpdc(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["warpdc"] ?? ["warpdc"], value) }
public func warpdec(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["warpdecay"] ?? ["warpdecay"], value) }
public func warpdecay(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["warpdecay"] ?? ["warpdecay"], value) }
public func warpdepth(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["warpdepth"] ?? ["warpdepth"], value) }
public func warpenv(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["warpenv"] ?? ["warpenv"], value) }
public func warpmode(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["warpmode"] ?? ["warpmode"], value) }
public func warprate(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["warprate"] ?? ["warprate"], value) }
public func warprel(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["warprelease"] ?? ["warprelease"], value) }
public func warprelease(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["warprelease"] ?? ["warprelease"], value) }
public func warpshape(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["warpshape"] ?? ["warpshape"], value) }
public func warpskew(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["warpskew"] ?? ["warpskew"], value) }
public func warpsus(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["warpsustain"] ?? ["warpsustain"], value) }
public func warpsustain(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["warpsustain"] ?? ["warpsustain"], value) }
public func warpsync(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["warpsync"] ?? ["warpsync"], value) }
public func waveloss(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["waveloss"] ?? ["waveloss"], value) }
public func wavetablePhaseRand(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["wtphaserand"] ?? ["wtphaserand"], value) }
public func wavetablePosition(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["wt"] ?? ["wt"], value) }
public func wavetableWarp(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["warp"] ?? ["warp"], value) }
public func wavetableWarpMode(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["warpmode"] ?? ["warpmode"], value) }
public func wt(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["wt"] ?? ["wt"], value) }
public func wtatt(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["wtattack"] ?? ["wtattack"], value) }
public func wtattack(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["wtattack"] ?? ["wtattack"], value) }
public func wtdc(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["wtdc"] ?? ["wtdc"], value) }
public func wtdec(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["wtdecay"] ?? ["wtdecay"], value) }
public func wtdecay(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["wtdecay"] ?? ["wtdecay"], value) }
public func wtdepth(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["wtdepth"] ?? ["wtdepth"], value) }
public func wtenv(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["wtenv"] ?? ["wtenv"], value) }
public func wtphaserand(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["wtphaserand"] ?? ["wtphaserand"], value) }
public func wtrate(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["wtrate"] ?? ["wtrate"], value) }
public func wtrel(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["wtrelease"] ?? ["wtrelease"], value) }
public func wtrelease(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["wtrelease"] ?? ["wtrelease"], value) }
public func wtshape(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["wtshape"] ?? ["wtshape"], value) }
public func wtskew(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["wtskew"] ?? ["wtskew"], value) }
public func wtsus(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["wtsustain"] ?? ["wtsustain"], value) }
public func wtsustain(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["wtsustain"] ?? ["wtsustain"], value) }
public func wtsync(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["wtsync"] ?? ["wtsync"], value) }
public func xsdelay(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["xsdelay"] ?? ["xsdelay"], value) }
public func zcrush(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["zcrush"] ?? ["zcrush"], value) }
public func zdelay(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["zdelay"] ?? ["zdelay"], value) }
public func zmod(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["zmod"] ?? ["zmod"], value) }
public func znoise(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["znoise"] ?? ["znoise"], value) }
public func zrand(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["zrand"] ?? ["zrand"], value) }
public func zzfx(_ value: PatternValue) -> Pattern { controlPattern(Controls.names["zzfx"] ?? ["zzfx"], value) }

// MARK: - Hand-written multi-name controls (adsr, ar)

extension Controls {
    static let extraNames: [String: [String]] = [
        "adsr": ["attack", "decay", "sustain", "release"],
        "ar": ["attack", "release"],
    ]
}
