// OrbitBus.swift — shared per-orbit delay/reverb buses.
// The Swift equivalent of superdough's orbit architecture: every hap sends
// into its orbit's continuously-running feedback delay and reverb, whose
// parameters update at hap onsets (superdough.mjs getOrbit/setDelay/setReverb).
// — AGPL-3.0-or-later.

import AVFoundation
import Foundation

/// One orbit's effect buses. Voices write their send signals into ring
/// buffers at absolute engine sample positions; an `AVAudioSourceNode` pulls
/// from the rings and runs the shared streaming effects.
final class OrbitBus {
    let orbit: Int
    private let sampleRate: Double

    // Ring buffers indexed by absolute engine sample time (mod capacity).
    // ~23 seconds at 44.1k — far beyond the scheduler's latency horizon.
    private let capacity = 1 << 20
    private var delayRing: [Float]
    private var reverbRing: [Float]
    private let lock = NSLock()

    private let delay: StreamingDelay
    private let reverbL: StreamingFreeverb
    private let reverbR: StreamingFreeverb

    private(set) var sourceNode: AVAudioSourceNode!

    init(orbit: Int, sampleRate: Double) {
        self.orbit = orbit
        self.sampleRate = sampleRate
        self.delayRing = [Float](repeating: 0, count: capacity)
        self.reverbRing = [Float](repeating: 0, count: capacity)
        self.delay = StreamingDelay(sampleRate: sampleRate)
        // Classic freeverb stereo spread (23 samples) on the right channel.
        self.reverbL = StreamingFreeverb(sampleRate: sampleRate)
        self.reverbR = StreamingFreeverb(sampleRate: sampleRate, stereoSpread: 23)

        sourceNode = AVAudioSourceNode { [weak self] _, timestamp, frameCount, audioBufferList -> OSStatus in
            guard let self else { return noErr }
            let abl = UnsafeMutableAudioBufferListPointer(audioBufferList)
            guard abl.count >= 2,
                  let leftOut = abl[0].mData?.assumingMemoryBound(to: Float.self),
                  let rightOut = abl[1].mData?.assumingMemoryBound(to: Float.self) else {
                return noErr
            }
            let startSample = Int64(timestamp.pointee.mSampleTime)
            self.renderBlock(startSample: startSample, frameCount: Int(frameCount),
                             left: leftOut, right: rightOut)
            return noErr
        }
    }

    /// Silences the bus: drops all pending (not yet played) send audio and
    /// resets the effect state so nothing new sounds after a hush.
    func clear() {
        lock.lock()
        defer { lock.unlock() }
        for i in 0..<capacity {
            delayRing[i] = 0
            reverbRing[i] = 0
        }
        delay.reset()
        reverbL.reset()
        reverbR.reset()
    }

    /// Mixes send audio into the rings at the given absolute sample position.
    func write(delaySend: [Float]?, reverbSend: [Float]?, atSample: Int64,
               delayTime: Double, delayFeedback: Double, roomSize: Double) {
        lock.lock()
        defer { lock.unlock() }
        // Param updates happen at hap onsets, like superdough's shared nodes.
        if delaySend != nil {
            delay.setTime(delayTime)
            delay.feedback = delayFeedback
        }
        if reverbSend != nil {
            reverbL.setSize(roomSize)
            reverbR.setSize(roomSize)
        }
        let base = Int(atSample % Int64(capacity))
        if let send = delaySend {
            for i in send.indices {
                delayRing[(base + i) % capacity] += send[i]
            }
        }
        if let send = reverbSend {
            for i in send.indices {
                reverbRing[(base + i) % capacity] += send[i]
            }
        }
    }

    func renderBlockForTesting(startSample: Int64, frameCount: Int,
                               left: UnsafeMutablePointer<Float>,
                               right: UnsafeMutablePointer<Float>) {
        renderBlock(startSample: startSample, frameCount: frameCount, left: left, right: right)
    }

    private func renderBlock(startSample: Int64, frameCount: Int,
                             left: UnsafeMutablePointer<Float>,
                             right: UnsafeMutablePointer<Float>) {
        lock.lock()
        defer { lock.unlock() }
        let base = Int(startSample % Int64(capacity))
        for i in 0..<frameCount {
            let idx = (base + i) % capacity
            let delayIn = delayRing[idx]
            let reverbIn = reverbRing[idx]
            // consume the ring so old audio never replays
            delayRing[idx] = 0
            reverbRing[idx] = 0
            let delayed = delay.process(delayIn)
            let revL = reverbL.process(reverbIn)
            let revR = reverbR.process(reverbIn)
            left[i] = delayed + revL
            right[i] = delayed + revR
        }
    }
}
