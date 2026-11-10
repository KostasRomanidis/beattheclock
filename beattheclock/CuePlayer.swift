import AVFoundation
import WorkoutEngine

/// Plays the workout cues as short sine tones generated at launch, so there are no audio assets.
/// Cues mix with other audio and, on iPad, play with the silent setting on.
final class CuePlayer {
    private static let sampleRate = 44_100.0
    private static let amplitude: Float = 0.6
    private static let fade = 0.005

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let buffers: [CueEvent: AVAudioPCMBuffer]

    init() {
        #if os(iOS)
        // Playback ignores the silent setting; mixing keeps other apps' music playing.
        try? AVAudioSession.sharedInstance().setCategory(.playback, options: .mixWithOthers)
        try? AVAudioSession.sharedInstance().setActive(true)
        #endif
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

    func play(_ cue: CueEvent) {
        // The engine stops on audio route changes and interruptions, so restart it on demand.
        if !engine.isRunning {
            guard (try? engine.start()) != nil else { return }
            player.play()
        }
        guard let buffer = buffers[cue] else { return }
        player.scheduleBuffer(buffer, at: nil, options: .interrupts)
    }

    /// Notes played one after another, each faded in and out to avoid clicks.
    private static func tones(_ notes: [(frequency: Double, seconds: Double)], format: AVAudioFormat) -> AVAudioPCMBuffer {
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
