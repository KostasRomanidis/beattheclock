import Observation
import WorkoutEngine

/// Connects a `Session` to real time: ticks every 100 ms and publishes what the screen shows.
/// While For Time is running it ticks every 16 ms so the hundredths move smoothly.
/// It holds no workout rules; inputs go straight to the session through `perform`.
@Observable
final class SessionController {
    static let tickInterval: Duration = .milliseconds(100)
    static let hundredthsTickInterval: Duration = .milliseconds(16)

    // Only `display` is observed. Everything the screen shows from the session also changes
    // the display, so views redraw only when something visible changes, not on every tick.
    @ObservationIgnored private(set) var session: Session
    private(set) var display: SessionDisplay
    private let getReady: Duration
    private let cuePlayer: CuePlayer
    private let wake = DisplayWake()

    init(configuration: WorkoutConfiguration, getReady: Duration, cuePlayer: CuePlayer) {
        let now = ContinuousClock.now
        let session = Session(configuration: configuration, getReady: getReady, startingAt: now)
        self.session = session
        self.display = SessionDisplay(session: session, now: now)
        self.getReady = getReady
        self.cuePlayer = cuePlayer
    }

    /// Runs while the live view is showing; SwiftUI cancels it when the view goes away.
    func run() async {
        await cuePlayer.prepare()
        while !Task.isCancelled {
            // Nothing moves on the summary; `restart` ticks again when the workout repeats.
            if session.status != .finished { tick() }
            try? await Task.sleep(for: interval)
        }
    }

    /// Fast only while hundredths are shown and moving; paused, get-ready and other workouts stay slow.
    private var interval: Duration {
        session.status == .running && display.mainFraction != nil ? Self.hundredthsTickInterval : Self.tickInterval
    }

    func perform(_ action: (inout Session, ContinuousClock.Instant) -> Void) {
        action(&session, .now)
        // Ticking straight away plays the action's cue now, such as rest starting after a set.
        tick()
    }

    /// Starts the same workout again from its get-ready countdown.
    func restart() {
        session = Session(configuration: session.configuration, getReady: getReady, startingAt: .now)
        tick()
    }

    private func tick() {
        let now = ContinuousClock.now
        let cues = session.update(now)
        let display = SessionDisplay(session: session, now: now)
        if display != self.display { self.display = display }
        // One task per tick keeps a tick's cues in order.
        if !cues.isEmpty {
            Task { [cuePlayer] in for cue in cues { await cuePlayer.play(cue) } }
        }
        // Awake while running or paused; normal sleep returns once the summary shows.
        wake.isActive = session.status != .finished
    }
}
