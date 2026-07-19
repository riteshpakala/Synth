import Foundation

/// A classic ADSR amplitude envelope.
///
/// Attack, decay, and release are durations in seconds; sustain is a level in
/// `0...1`. The envelope is shaped to always fit inside a note's duration so
/// notes start and end without clicks.
public struct Envelope: Sendable {
    public var attack: Double
    public var decay: Double
    public var sustain: Double
    public var release: Double

    public init(attack: Double, decay: Double, sustain: Double, release: Double) {
        self.attack = attack
        self.decay = decay
        self.sustain = sustain
        self.release = release
    }

    /// A gentle default that avoids clicks on short notes.
    public static let `default` = Envelope(attack: 0.012, decay: 0.06, sustain: 0.7, release: 0.09)

    /// The envelope's amplitude at a given frame within a note.
    public func amplitude(atFrame frame: Int, totalFrames: Int, sampleRate: Double) -> Double {
        guard totalFrames > 0 else { return 0 }

        let t = Double(frame) / sampleRate
        let total = Double(totalFrames) / sampleRate

        // Clamp the attack/release so they always fit inside the note.
        let a = min(attack, total * 0.5)
        let r = min(release, total * 0.5)
        let releaseStart = max(a, total - r)

        if t < a {
            return a > 0 ? t / a : 1.0
        } else if t < a + decay && t < releaseStart {
            let progress = decay > 0 ? (t - a) / decay : 1.0
            return 1.0 - (1.0 - sustain) * min(progress, 1.0)
        } else if t < releaseStart {
            return sustain
        } else {
            let progress = r > 0 ? (t - releaseStart) / r : 1.0
            return sustain * max(0.0, 1.0 - progress)
        }
    }
}
