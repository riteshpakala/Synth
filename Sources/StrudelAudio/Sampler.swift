// Sampler.swift — local sample folders as sounds.
// Semantics ported from Strudel <https://codeberg.org/uzu/strudel>
// (packages/superdough/sampler.mjs: n/begin/end/speed/unit/loop) — AGPL-3.0-or-later.

import AVFoundation
import Foundation
import StrudelCore

/// A sound backed by one or more audio files. `n` selects the file
/// (wrapping); begin/end/speed/unit/loop come from the control map.
public struct SampleSound: SoundSource {
    public let name: String
    /// The decoded files: mono samples + their source sample rate.
    let files: [(samples: [Float], sampleRate: Double)]

    public func render(params: SoundParams, sampleRate: Double) -> [Float] {
        guard !files.isEmpty else { return [] }
        let file = files[_mod(params.n, files.count)]
        let source = file.samples
        guard !source.isEmpty else { return [] }

        let begin = params.value["begin"]?.doubleValue ?? 0
        let end = params.value["end"]?.doubleValue ?? 1
        var speed = params.value["speed"]?.doubleValue ?? 1
        let unit = params.value["unit"]?.stringValue
        let loop = params.value["loop"]?.truthy ?? false

        let startFrame = Int(Double(source.count) * min(begin, end))
        let endFrame = Int(Double(source.count) * max(begin, end))
        let sliceLength = max(1, endFrame - startFrame)
        let sliceDuration = Double(sliceLength) / file.sampleRate

        if unit == "c" {
            // unit 'c': speed is playback rate per cycle — fit slice into
            // 1/speed cycles; scheduler passes duration in seconds, so speed
            // becomes sliceDuration / duration.
            speed = speed * sliceDuration
        }
        let reverse = speed < 0
        let rate = max(abs(speed), 0.001) * file.sampleRate / sampleRate

        // cut to hap duration (+ small release), or the whole slice if shorter
        let adsr = ADSR(attack: params.adsr.attack, decay: params.adsr.decay,
                        sustain: params.adsr.sustain, release: params.adsr.release,
                        defaults: (0.001, 0.001, 1, 0.01))
        let holdEnd = params.duration
        let maxFrames = Int((holdEnd + adsr.release) * sampleRate)
        let naturalFrames = Int(Double(sliceLength) / rate)
        let frames = loop ? maxFrames : min(maxFrames, naturalFrames)
        guard frames > 0 else { return [] }

        var out = [Float](repeating: 0, count: frames)
        for i in 0..<frames {
            var pos = Double(i) * rate
            if loop {
                pos = pos.truncatingRemainder(dividingBy: Double(sliceLength))
            } else if pos >= Double(sliceLength) {
                break
            }
            let idx = reverse ? Double(sliceLength) - 1 - pos : pos
            let j = startFrame + Int(idx)
            guard j >= 0 && j < source.count else { continue }
            let t = Double(i) / sampleRate
            let env = adsr.level(at: t, holdEnd: holdEnd)
            out[i] = source[j] * Float(env * params.velocity)
        }
        return out
    }
}

/// Loads audio files into the registry: a folder becomes `s(folderName)`,
/// its files selectable with `n`.
public enum SampleLoader {
    /// Loads every audio file directly inside `directory` as one sound named
    /// after the folder, and every subfolder as its own sound.
    public static func loadDirectory(_ directory: URL) throws {
        let fm = FileManager.default
        let contents = try fm.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.isDirectoryKey])
        var rootFiles: [URL] = []
        for url in contents.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
            if (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true {
                let files = (try? fm.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)) ?? []
                register(name: url.lastPathComponent, files: files)
            } else if isAudioFile(url) {
                rootFiles.append(url)
            }
        }
        if !rootFiles.isEmpty {
            register(name: directory.lastPathComponent, files: rootFiles)
        }
    }

    /// Registers a named sound from explicit audio files. Names starting
    /// with `wt_` become wavetables (sampler.mjs isWavetable convention).
    public static func register(name: String, files: [URL]) {
        let decoded = files
            .filter(isAudioFile)
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
            .compactMap { try? decode($0) }
        guard !decoded.isEmpty else { return }
        if name.hasPrefix("wt_") {
            SoundRegistry.shared.register(WavetableSound(name: name, files: decoded), as: name)
        } else {
            SoundRegistry.shared.register(SampleSound(name: name, files: decoded), as: name)
        }
    }

    static func isAudioFile(_ url: URL) -> Bool {
        ["wav", "aif", "aiff", "mp3", "m4a", "flac", "caf"].contains(url.pathExtension.lowercased())
    }

    static func decode(_ url: URL) throws -> ([Float], Double) {
        let file = try AVAudioFile(forReading: url)
        let format = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                   sampleRate: file.processingFormat.sampleRate,
                                   channels: 1, interleaved: false)!
        let frames = AVAudioFrameCount(file.length)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames) else {
            throw NSError(domain: "SampleLoader", code: 1)
        }
        try file.read(into: buffer)
        let count = Int(buffer.frameLength)
        let samples = Array(UnsafeBufferPointer(start: buffer.floatChannelData![0], count: count))
        return (samples, file.processingFormat.sampleRate)
    }
}

// MARK: - Wavetables (superdough wavetable.mjs)

/// A wavetable oscillator: audio files whose name starts with `wt_` are
/// treated as banks of 2048-sample single-cycle frames. `wt` (0..1) scans
/// the frames, optionally swept by the wt position envelope (`wtenv`,
/// `wtattack`, `wtdecay`, `wtsustain`, `wtrelease`).
public struct WavetableSound: SoundSource {
    public let name: String
    let files: [(samples: [Float], sampleRate: Double)]
    static let frameLen = 2048

    public func render(params: SoundParams, sampleRate: Double) -> [Float] {
        guard !files.isEmpty else { return [] }
        let file = files[_mod(params.n, files.count)]
        let source = file.samples
        let frameLen = Self.frameLen
        let numFrames = max(1, source.count / frameLen)

        let adsr = ADSR(attack: params.adsr.attack, decay: params.adsr.decay,
                        sustain: params.adsr.sustain, release: params.adsr.release,
                        defaults: (0.001, 0.05, 0.6, 0.01))
        let holdEnd = params.duration
        let frames = max(1, Int((holdEnd + adsr.release) * sampleRate))
        var out = [Float](repeating: 0, count: frames)

        let wt = params.value["wt"]?.doubleValue ?? 0
        let wtenv = params.value["wtenv"]?.doubleValue ?? 0
        let posADSR = ADSR(attack: params.value["wtattack"]?.doubleValue,
                           decay: params.value["wtdecay"]?.doubleValue,
                           sustain: params.value["wtsustain"]?.doubleValue,
                           release: params.value["wtrelease"]?.doubleValue,
                           defaults: (0.005, 0.14, 0, 0.1))

        var phase = 0.0
        let increment = params.frequency / sampleRate
        for i in 0..<frames {
            let t = Double(i) / sampleRate
            // wavetable position, swept by the position envelope
            var position = wt
            if wtenv != 0 {
                position += wtenv * posADSR.level(at: t, holdEnd: holdEnd)
            }
            position = min(max(position, 0), 1)
            let framePos = position * Double(numFrames - 1)
            let frameA = Int(framePos)
            let frameB = min(frameA + 1, numFrames - 1)
            let frameMix = Float(framePos - Double(frameA))

            let x = phase * Double(frameLen)
            let idx = Int(x) % frameLen
            let nextIdx = (idx + 1) % frameLen
            let mix = Float(x - x.rounded(.down))
            func sampleFrame(_ f: Int) -> Float {
                let base = f * frameLen
                guard base + nextIdx < source.count else { return 0 }
                return source[base + idx] * (1 - mix) + source[base + nextIdx] * mix
            }
            let sample = sampleFrame(frameA) * (1 - frameMix) + sampleFrame(frameB) * frameMix

            let env = adsr.level(at: t, holdEnd: holdEnd)
            out[i] = sample * Float(env * 0.3 * params.velocity)
            phase += increment
            if phase >= 1 { phase -= 1 }
        }
        return out
    }
}
