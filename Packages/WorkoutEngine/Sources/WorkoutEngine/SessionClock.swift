/// Turns real instants into session time, which excludes pauses. Everything else in a session
/// is stored in session time, so a pause moves nothing but this clock.
struct SessionClock: Sendable {
    typealias Instant = ContinuousClock.Instant

    enum State: Equatable, Sendable {
        case running, paused(at: Duration), ended(at: Duration)
    }

    private(set) var state: State = .running
    /// When the session would have started had it never paused.
    private var origin: Instant

    init(startingAt now: Instant) {
        origin = now
    }

    /// Session time, stopped while paused or after the end.
    func time(_ now: Instant) -> Duration {
        switch state {
        case .running: timeIfRunning(now)
        case .paused(let time), .ended(let time): time
        }
    }

    /// Session time as if the clock had not stopped at the end, to tell how late a cue is.
    func timeIfRunning(_ now: Instant) -> Duration {
        now - origin
    }

    mutating func pause(_ now: Instant) {
        guard case .running = state else { return }
        state = .paused(at: time(now))
    }

    mutating func resume(_ now: Instant) {
        guard case .paused(let time) = state else { return }
        origin = now - time
        state = .running
    }

    mutating func end(at time: Duration) {
        state = .ended(at: time)
    }
}
