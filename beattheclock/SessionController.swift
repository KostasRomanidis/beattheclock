import Observation
import WorkoutEngine

/// Connects a `Session` to real time: ticks every 100 ms and publishes what the screen shows.
/// It holds no workout rules; inputs go straight to the session through `perform`.
@Observable
final class SessionController {
    static let tickInterval: Duration = .milliseconds(100)

    private(set) var session: Session
    private(set) var display: SessionDisplay
    private let getReady: Duration

    init(configuration: WorkoutConfiguration, getReady: Duration) {
        let now = ContinuousClock.now
        let session = Session(configuration: configuration, getReady: getReady, startingAt: now)
        self.session = session
        self.display = SessionDisplay(session: session, now: now)
        self.getReady = getReady
    }

    /// Runs while the live view is showing; SwiftUI cancels it when the view goes away.
    func run() async {
        while !Task.isCancelled {
            tick()
            try? await Task.sleep(for: Self.tickInterval)
        }
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
        display = SessionDisplay(session: session, now: now)
        // shortcut: cues are dropped until CuePlayer exists, replace in task 7.1.
        _ = cues
    }
}
