import AVFoundation
import WorkoutEngine

/// Plays the workout cues as short sine tones generated at launch, so there are no audio assets.
/// Cues mix with other audio and, on iPad, play with the silent setting on.
/// An actor so the blocking audio session and engine calls stay off the main thread.
actor CuePlayer {
    private nonisolated static let sampleRate = 44_100.0
    private nonisolated static let amplitude: Float = 0.6
    private nonisolated static let fade = 0.005

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let buffers: [CueEvent: AVAudioPCMBuffer]
    private var preparing: Task<Void, Never>?

    init() {
        let format = AVAudioFormat(standardFormatWithSampleRate: Self.sampleRate, channels: 1)!
        buffers = [
            .tick: Self.tones([(1760, 0.06)], format: format),
            .workStart: Self.tones([(880, 0.12), (1320, 0.22)], format: format),
            .restStart: Self.tones([(1320, 0.12), (660, 0.22)], format: format),
            .finish: Self.tones([(880, 0.15), (1109, 0.15), (1319, 0.4)], format: format),
        ]
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
    }

    /// Starts setting up audio once, in the background: the session on iPad, then the engine,
    /// so the first cue doesn't pay the start-up time. Cues wait for it instead of racing it.
    func prepare() {
        guard preparing == nil else { return }
        preparing = Task { await setUp() }
    }

    func play(_ cue: CueEvent) async {
        await preparing?.value
        // The engine stops on audio route changes and interruptions, so restart it on demand.
        guard startEngine(), let buffer = buffers[cue] else { return }
        queue(buffer)
    }

    /// Queued without interrupting, so several cues from one tick play in order. Not async,
    /// so this schedules the buffer rather than the async overload that awaits its playback.
    private func queue(_ buffer: AVAudioPCMBuffer) {
        player.scheduleBuffer(buffer, at: nil, completionHandler: nil)
    }

    private func setUp() async {
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        // Playback ignores the silent setting; mixing keeps other apps' music playing.
        try? session.setCategory(.playback, options: .mixWithOthers)
        if #available(iOS 27, *) {
            _ = try? await session.activate(options: [])
        } else {
            try? session.setActive(true)
        }
        #endif
        startEngine()
    }

    /// Whether the engine is running, starting it and the player if needed.
    @discardableResult private func startEngine() -> Bool {
        if engine.isRunning { return true }
        guard (try? engine.start()) != nil else { return false }
        player.play()
        return true
    }

    /// Notes played one after another, each faded in and out to avoid clicks.
    private nonisolated static func tones(_ notes: [(frequency: Double, seconds: Double)], format: AVAudioFormat) -> AVAudioPCMBuffer {
        let totalFrames = notes.reduce(0) { $0 + Int($1.seconds * sampleRate) }
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(totalFrames))!
        buffer.frameLength = AVAudioFrameCount(totalFrames)
        let samples = buffer.floatChannelData![0]
        var offset = 0
        for note in notes {
            let frames = Int(note.seconds * sampleRate)
            let fadeFrames = Double(fade * sampleRate)
            for frame in 0..<frames {
                let edge = Double(min(frame, frames - 1 - frame))
                let envelope = min(1, edge / fadeFrames)
                let phase = 2 * Double.pi * note.frequency * Double(frame) / sampleRate
                samples[offset + frame] = Self.amplitude * Float(envelope * sin(phase))
            }
            offset += frames
        }
        return buffer
    }
}
