/// The cues waiting for their moment, in session time, so each is reported once and none is reported late.
struct CueQueue: Sendable {
    static let staleCueLimit: Duration = .seconds(1)

    private struct TimedCue: Sendable {
        let moment: Duration
        let cue: CueEvent
    }

    private var pending: [TimedCue] = []

    mutating func queue(_ cue: CueEvent, at moment: Duration) {
        pending.append(TimedCue(moment: moment, cue: cue))
    }

    /// Queues the final-seconds ticks of a countdown phase from `start` to `end`.
    mutating func queueTicks(from start: Duration, to end: Duration) {
        for secondsLeft in (1...Phase.finalSeconds).reversed() {
            let moment = end - .seconds(secondsLeft)
            if moment > start { queue(.tick, at: moment) }
        }
    }

    /// Returns the cues due by `time`, dropping any more than a second late.
    mutating func takeDue(_ time: Duration) -> [CueEvent] {
        let due = pending.filter { $0.moment <= time }
        pending.removeAll { $0.moment <= time }
        return due.filter { time - $0.moment <= Self.staleCueLimit }.map(\.cue)
    }

    /// Drops what was still to come when a phase ends early.
    mutating func cancel(after moment: Duration) {
        pending.removeAll { $0.moment > moment }
    }

    mutating func cancelAll() {
        pending = []
    }
}
