// LivePlaybackTests.swift — end-to-end verification of the LIVE audio path:
// a tap on the output records real playback, then we measure onset spacing
// (timing accuracy) and post-hush silence (immediate stop).
// Requires an output device; tolerances are generous for shared machines.
// AGPL-3.0-or-later.

import AVFoundation
import XCTest
@testable import StrudelAudio
@testable import StrudelCore
@testable import StrudelMini

final class LivePlaybackTests: XCTestCase {
    override func setUp() { installMiniNotation() }

    func testLiveTimingAndImmediateStop() throws {
        let player = StrudelPlayer()
        // sharp clicks, 4 per cycle at 1 cps → one every 250 ms
        let clicks = s("square*4").decay(0.012).sustain(0).gain(1)

        var recorded: [Float] = []
        let lock = NSLock()
        let engine = player.engineForTesting
        engine.mainMixerNode.installTap(onBus: 0, bufferSize: 2048,
                                        format: engine.mainMixerNode.outputFormat(forBus: 0)) { buffer, _ in
            guard let data = buffer.floatChannelData?[0] else { return }
            lock.lock()
            recorded.append(contentsOf: UnsafeBufferPointer(start: data, count: Int(buffer.frameLength)))
            lock.unlock()
        }
        defer { engine.mainMixerNode.removeTap(onBus: 0) }

        try player.play(clicks, cps: 1)
        Thread.sleep(forTimeInterval: 3.0)
        player.hush()
        lock.lock()
        let hushMark = recorded.count
        lock.unlock()
        Thread.sleep(forTimeInterval: 0.8)

        lock.lock()
        let samples = recorded
        lock.unlock()
        let sr = engine.mainMixerNode.outputFormat(forBus: 0).sampleRate

        // --- timing: click onsets must be evenly spaced at 250 ms ---
        var onsets: [Int] = []
        var i = 0
        let threshold: Float = 0.05
        while i < min(hushMark, samples.count) {
            if abs(samples[i]) > threshold {
                onsets.append(i)
                i += Int(sr * 0.1)  // skip past this click
            } else {
                i += 1
            }
        }
        XCTAssertGreaterThanOrEqual(onsets.count, 8, "should capture several clicks")
        let gaps = zip(onsets.dropFirst(), onsets).map { Double($0 - $1) / sr }
        for gap in gaps {
            // every gap is a multiple of 0.25 s (missed clicks allowed under
            // load), and never bunched
            let quarters = gap / 0.25
            XCTAssertEqual(quarters, quarters.rounded(), accuracy: 0.12,
                           "clicks must land on the 250 ms grid, got gap \(gap)")
            XCTAssertGreaterThan(gap, 0.13, "clicks must not bunch together")
        }

        // --- stop: output after hush must be silent (small decay allowance) ---
        let tailStart = min(hushMark + Int(sr * 0.25), samples.count)
        let tail = samples[tailStart...]
        let tailPeak = tail.map { abs($0) }.max() ?? 0
        XCTAssertLessThan(tailPeak, 0.02, "audio must stop immediately after hush")
    }
}
