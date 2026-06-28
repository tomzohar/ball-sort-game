import AVFoundation

/// Synthesizes short feedback tones in-code — no audio asset files, no SDKs (E8.1).
/// Each `GameEvent` maps to a tiny PCM buffer (sine partials with an envelope) that
/// is scheduled on an `AVAudioPlayerNode`. The engine is configured `.ambient`, so
/// it honors the silent switch and never ducks the player's music. Construction is
/// cheap: the engine is lazily started on the first `play(_:)` so building a
/// `BoardViewModel` in the test host never touches audio hardware. Playback is gated
/// on the `soundEnabled` setting (default on).
@MainActor
final class SoundPlayer: GameFeedbackPlaying {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)
    private var started = false

    /// Cached buffers, synthesized once per event on first use.
    private var buffers: [Event: AVAudioPCMBuffer] = [:]

    private var isEnabled: Bool {
        UserDefaults.standard.object(forKey: "soundEnabled") as? Bool ?? true
    }

    func play(_ event: GameEvent) {
        guard isEnabled, let event = Event(event), let format else { return }
        guard start() else { return }

        let buffer: AVAudioPCMBuffer
        if let cached = buffers[event] {
            buffer = cached
        } else {
            guard let made = Self.makeBuffer(for: event, format: format) else { return }
            buffers[event] = made
            buffer = made
        }
        player.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: nil)
        if !player.isPlaying { player.play() }
    }

    /// Lazily configure the session and start the engine. Returns `false` (and stays
    /// silent) if any step fails, so a sandboxed/headless host never crashes.
    private func start() -> Bool {
        if started { return true }
        guard let format else { return false }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, mode: .default, options: [])
            try session.setActive(true)
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: format)
            try engine.start()
            started = true
            return true
        } catch {
            return false
        }
    }

    // MARK: - Synthesis

    /// The subset of `GameEvent`s that produce a tone (`.undo` is silent — haptics
    /// only — to avoid a distracting blip on every revert).
    private enum Event {
        case lift, drop, tubeComplete, win, illegalMove, hint

        init?(_ event: GameEvent) {
            switch event {
            case .lift: self = .lift
            case .drop: self = .drop
            case .tubeComplete: self = .tubeComplete
            case .win: self = .win
            case .illegalMove: self = .illegalMove
            case .hint: self = .hint
            case .undo: return nil
            }
        }
    }

    private static let sampleRate: Double = 44_100

    /// One partial in a synthesized cue: a pure tone at `frequency`, beginning at
    /// `start` seconds and lasting `duration` seconds.
    private struct Note {
        let frequency: Double
        let start: Double
        let duration: Double
    }

    private static func makeBuffer(for event: Event, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        switch event {
        case .lift:
            return tone(notes: [Note(frequency: 880, start: 0.0, duration: 0.06)], format: format)
        case .drop:
            return tone(notes: [Note(frequency: 330, start: 0.0, duration: 0.10)], format: format)
        case .tubeComplete:
            return tone(
                notes: [
                    Note(frequency: 523.25, start: 0.0, duration: 0.10),
                    Note(frequency: 659.25, start: 0.08, duration: 0.14)
                ],
                format: format
            )
        case .win:
            return tone(
                notes: [
                    Note(frequency: 523.25, start: 0.0, duration: 0.14),
                    Note(frequency: 659.25, start: 0.12, duration: 0.14),
                    Note(frequency: 783.99, start: 0.24, duration: 0.20)
                ],
                format: format
            )
        case .illegalMove:
            return tone(notes: [Note(frequency: 160, start: 0.0, duration: 0.14)], format: format, square: true)
        case .hint:
            // A gentle ascending "ti-ding" (E5 → B5), softer and higher than the move
            // cues, so a hint reads as a friendly nudge rather than a result.
            return tone(
                notes: [
                    Note(frequency: 659.25, start: 0.0, duration: 0.07),
                    Note(frequency: 987.77, start: 0.06, duration: 0.11)
                ],
                format: format
            )
        }
    }

    /// Builds a mono PCM buffer summing each `Note`, each shaped by a short
    /// attack/decay envelope to avoid clicks. `square` swaps the sine for a harsher
    /// buzz used by the illegal-move cue.
    private static func tone(
        notes: [Note],
        format: AVAudioFormat,
        square: Bool = false
    ) -> AVAudioPCMBuffer? {
        let total = notes.map { $0.start + $0.duration }.max() ?? 0
        let frameCount = AVAudioFrameCount((total + 0.02) * sampleRate)
        guard frameCount > 0,
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
              let channel = buffer.floatChannelData?[0] else { return nil }
        buffer.frameLength = frameCount

        for frame in 0..<Int(frameCount) {
            channel[frame] = 0
        }

        let twoPi = 2.0 * Double.pi
        for note in notes {
            let startFrame = Int(note.start * sampleRate)
            let noteFrames = Int(note.duration * sampleRate)
            for offset in 0..<noteFrames {
                let frame = startFrame + offset
                guard frame < Int(frameCount) else { break }
                let time = Double(offset) / sampleRate
                let phase = twoPi * note.frequency * time
                let raw = square ? (sin(phase) >= 0 ? 1.0 : -1.0) : sin(phase)
                let envelope = Self.envelope(progress: Double(offset) / Double(noteFrames))
                channel[frame] += Float(raw * envelope * 0.25)
            }
        }
        return buffer
    }

    /// A simple attack/decay envelope (ramp up over the first 10%, decay across the
    /// rest) so notes start and end without an audible click.
    private static func envelope(progress: Double) -> Double {
        let attack = 0.1
        if progress < attack {
            return progress / attack
        }
        return 1.0 - (progress - attack) / (1.0 - attack)
    }
}
