/// What the live screen shows for a session at a moment. Views only render these values.
public struct SessionDisplay: Equatable, Sendable {
    public enum State: Equatable, Sendable {
        case getReady, work, rest, finalSeconds, paused, finished
    }

    /// The largest number: time left in a countdown phase, or time so far in a count-up phase.
    public let mainTime: String
    /// The hundredths of a second, such as ".25", shown smaller after `mainTime` while For Time
    /// counts up. Nil everywhere else, where times stay in whole seconds.
    public let mainFraction: String?
    /// The phase or pause in words, so the state never relies on colour alone.
    public let label: String
    public let state: State
    /// The smaller total at the top, such as "5:37 left" or "12:00 elapsed".
    public let secondaryTotal: String?
    /// Round, block or set position, rounds counted in AMRAP, or round number in For Time.
    public let position: String?
    /// The next phase and its length, or a note that this is the last one.
    public let nextPhase: String?
    /// Fraction of the current countdown phase used, or nil for a count-up phase.
    public let phaseProgress: Double?
    /// Fraction of a known-length workout done, or nil when the length is unknown.
    public let workoutProgress: Double?

    public init(session: Session, now: Session.Instant) {
        let phase = session.currentPhase
        let timeLeft = session.timeLeftInPhase(now)
        let workoutTime = session.workoutTime(now)
        let total = session.plan.total
        let elapsed = session.elapsedInPhase(now)
        mainTime = timeLeft.map { TimeFormat.format($0, roundingUp: true) } ?? TimeFormat.format(elapsed)
        mainFraction = timeLeft == nil && session.plan.showsHundredths
            ? TimeFormat.fraction(max(elapsed, .zero).components.attoseconds) : nil
        label = session.status == .paused ? "PAUSED" : phase.kind.label
        state = Self.state(session: session, timeLeft: timeLeft)
        secondaryTotal = Self.secondaryTotal(session.plan, workoutTime: workoutTime)
        position = Self.position(session)
        nextPhase = Self.nextPhase(session)
        phaseProgress = phase.countdownDuration.map { Self.fraction(elapsed, of: $0) }
        workoutProgress = total.map { Self.fraction(workoutTime, of: $0) }
    }

    private static func state(session: Session, timeLeft: Duration?) -> State {
        switch session.status {
        case .paused: return .paused
        case .finished: return .finished
        case .running: break
        }
        if let timeLeft, timeLeft <= .seconds(Phase.finalSeconds) { return .finalSeconds }
        switch session.currentPhase.kind {
        case .getReady: return .getReady
        case .work: return .work
        case .rest: return .rest
        }
    }

    private static func secondaryTotal(_ plan: WorkoutPlan, workoutTime: Duration) -> String? {
        switch plan.secondaryTotal {
        case .left(let whole): left(whole - workoutTime)
        case .elapsed: "\(TimeFormat.format(workoutTime)) elapsed"
        case nil: nil
        }
    }

    private static func left(_ duration: Duration) -> String {
        "\(TimeFormat.format(duration, roundingUp: true)) left"
    }

    private static func position(_ session: Session) -> String? {
        let recorded: String? = switch session.plan.record {
        case .rounds: session.roundsCounted == 1 ? "1 round" : "\(session.roundsCounted) rounds"
        case .splits: "Round \(session.splits.count + 1)"
        case nil: nil
        }
        guard let place = session.currentPhase.place else { return recorded }
        let text = text(place, isNext: session.currentPhase.kind != .work)
        return recorded.map { "\(text) · \($0)" } ?? text
    }

    private static func text(_ place: Phase.Place, isNext: Bool) -> String {
        let repeats = "\(place.unit.name) \(place.number) of \(place.count)"
        if isNext { return "\(repeats) next" }
        return place.exercise.map { "\(repeats), exercise \($0.number) of \($0.count)" } ?? repeats
    }

    private static func nextPhase(_ session: Session) -> String? {
        let nextIndex = session.phaseIndex + 1
        guard nextIndex < session.plan.phases.count else {
            guard let place = session.currentPhase.place else { return nil }
            return place.exercise == nil ? "Final \(place.unit.name.lowercased())" : "Final exercise"
        }
        let next = session.plan.phases[nextIndex]
        if let exercise = next.place?.exercise, let duration = next.countdownDuration {
            return "Next: Exercise \(exercise.number) · \(TimeFormat.format(duration))"
        }
        return "Next: " + (next.countdownDuration.map { "\(next.kind.name) \(TimeFormat.format($0))" } ?? next.kind.name)
    }

    private static func fraction(_ part: Duration, of whole: Duration) -> Double {
        // A zero-length phase or workout is already over, and dividing by it has no answer.
        guard whole > .zero else { return 1 }
        return min(max(part / whole, 0), 1)
    }
}

extension Phase.Kind {
    var name: String {
        switch self {
        case .getReady: "Get ready"
        case .work: "Work"
        case .rest: "Rest"
        }
    }

    var label: String { name.uppercased() }
}

extension Phase.Place.Unit {
    var name: String {
        switch self {
        case .block: "Block"
        case .round: "Round"
        case .set: "Set"
        }
    }
}
