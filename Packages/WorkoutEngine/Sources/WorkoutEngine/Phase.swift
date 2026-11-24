/// One phase of a workout. Timed phases count down; user-ended phases count up.
public struct Phase: Equatable, Sendable {
    public enum Kind: Equatable, Sendable {
        case work, rest, getReady
    }

    public enum Ending: Equatable, Sendable {
        case afterDuration(Duration)
        case byUser(cap: Duration?)
    }

    public enum MainAction: Equatable, Sendable {
        case countRound, split, setDone
    }

    /// Where a phase falls among the workout's repeats. A rest or get-ready holds the place coming next.
    struct Place: Equatable, Sendable {
        enum Unit: Equatable, Sendable {
            case block, round, set
        }

        struct Exercise: Equatable, Sendable {
            let number: Int
            let count: Int
        }

        let unit: Unit
        let number: Int
        let count: Int
        /// The exercise within an EMOM round, when there is more than one.
        var exercise: Exercise?
    }

    /// How many seconds at the end of a timed phase are marked by the ticks and the screen.
    static let finalSeconds = 3

    public let kind: Kind
    public let ending: Ending
    /// The action a tap or Return performs during this phase, if it has one.
    var mainAction: MainAction?
    /// Whether Finish can end the workout during this phase.
    var canFinish = false
    /// Nil for workouts without repeats.
    var place: Place?

    /// How long a timed phase runs, or nil when it counts up.
    var countdownDuration: Duration? {
        guard case .afterDuration(let duration) = ending else { return nil }
        return duration
    }

    /// When the phase ends on its own: its duration, or the cap of a count-up phase.
    var limit: Duration? {
        switch ending {
        case .afterDuration(let duration): duration
        case .byUser(let cap): cap
        }
    }
}
