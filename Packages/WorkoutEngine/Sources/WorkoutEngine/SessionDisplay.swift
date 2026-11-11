/// What the live screen shows for a session at a moment. Views only render these values.
public struct SessionDisplay: Equatable, Sendable {
    public enum State: Equatable, Sendable {
        case getReady, work, rest, finalSeconds, paused, finished
    }

    static let finalSeconds: Duration = .seconds(3)

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
        let segment = session.currentSegment
        let timeLeft = session.timeLeftInSegment(now)
        let workoutTime = session.workoutTime(now)
        let total = session.configuration.total

        let elapsed = session.elapsedInSegment(now)
        mainTime = timeLeft.map { Self.format($0, roundingUp: true) } ?? Self.format(elapsed)
        mainFraction = timeLeft == nil && session.configuration.showsHundredths
            ? Self.fraction(max(elapsed, .zero).components.attoseconds) : nil
        label = session.status == .paused ? "PAUSED" : segment.kind.label
        state = Self.state(session: session, timeLeft: timeLeft)
        secondaryTotal = Self.secondaryTotal(session.configuration, workoutTime: workoutTime)
        position = Self.position(session)
        nextPhase = Self.nextPhase(session)
        phaseProgress = segment.countdownDuration.map { Self.fraction(session.elapsedInSegment(now), of: $0) }
        workoutProgress = total.map { Self.fraction(workoutTime, of: $0) }
    }

    /// Minutes and seconds, with hours only when needed. Countdowns round up,
    /// so they show 0:00 only when the phase ends. `hundredths` adds the whole
    /// hundredths cut off, never rounded, so a time never reads later than it is;
    /// it is for count-up times and not combined with `roundingUp`.
    public static func format(_ duration: Duration, roundingUp: Bool = false, hundredths: Bool = false) -> String {
        let (seconds, attoseconds) = max(duration, .zero).components
        let wholeSeconds = Int(seconds) + (roundingUp && attoseconds > 0 ? 1 : 0)
        let (hours, minutes, secondsPart) = (wholeSeconds / 3600, wholeSeconds / 60 % 60, wholeSeconds % 60)
        let paddedSeconds = secondsPart < 10 ? "0\(secondsPart)" : "\(secondsPart)"
        let time: String
        if hours > 0 {
            let paddedMinutes = minutes < 10 ? "0\(minutes)" : "\(minutes)"
            time = "\(hours):\(paddedMinutes):\(paddedSeconds)"
        } else {
            time = "\(minutes):\(paddedSeconds)"
        }
        return hundredths ? time + fraction(attoseconds) : time
    }

    /// The hundredths of a second in `attoseconds`, such as ".25".
    static func fraction(_ attoseconds: Int64) -> String {
        let hundredths = Int(attoseconds / 10_000_000_000_000_000)
        return hundredths < 10 ? ".0\(hundredths)" : ".\(hundredths)"
    }

    /// A preset in words: whole minutes as "12 min", zero as "None", otherwise seconds.
    public static func presetLabel(_ duration: Duration) -> String {
        let seconds = Int(duration.components.seconds)
        if seconds == 0 { return "None" }
        return seconds % 60 == 0 ? "\(seconds / 60) min" : "\(seconds) s"
    }

    private static func state(session: Session, timeLeft: Duration?) -> State {
        switch session.status {
        case .paused: return .paused
        case .finished: return .finished
        case .running: break
        }
        if let timeLeft, timeLeft <= finalSeconds { return .finalSeconds }
        switch session.currentSegment.kind {
        case .getReady: return .getReady
        case .work: return .work
        case .rest: return .rest
        }
    }

    private static func secondaryTotal(_ configuration: WorkoutConfiguration, workoutTime: Duration) -> String? {
        switch configuration {
        case .intervals, .tabata, .emom:
            return configuration.total.map { left($0 - workoutTime) }
        case .amrap(_, let blocks, _, _):
            guard blocks > 1 else { return nil }
            return configuration.total.map { left($0 - workoutTime) }
        case .forTime(let cap):
            return cap.map { left($0 - workoutTime) }
        case .sets:
            return "\(format(workoutTime)) elapsed"
        case .timer, .stopwatch:
            return nil
        }
    }

    private static func left(_ duration: Duration) -> String {
        "\(format(duration, roundingUp: true)) left"
    }

    private static func position(_ session: Session) -> String? {
        let configuration = session.configuration
        let rounds = roundsCountedText(session)
        if case .forTime = configuration { return "Round \(session.splits.count + 1)" }
        guard let unit = configuration.roundUnit else { return rounds }

        // Counting work phases before this one, plus one, gives the current work phase,
        // or during rest and get-ready, the one that comes next.
        let workSegments = session.segments.filter { $0.kind == .work }.count
        let workSoFar = session.segments[..<session.segmentIndex].filter { $0.kind == .work }.count
        let next = session.currentSegment.kind == .work ? "" : " next"
        if let exercises = configuration.emomExercises {
            let round = "\(unit) \(workSoFar / exercises + 1) of \(workSegments / exercises)"
            return next.isEmpty ? "\(round), exercise \(workSoFar % exercises + 1) of \(exercises)" : round + next
        }
        let place = "\(unit) \(workSoFar + 1) of \(workSegments)\(next)"
        return rounds.map { "\(place) · \($0)" } ?? place
    }

    private static func roundsCountedText(_ session: Session) -> String? {
        guard session.configuration.countsRounds else { return nil }
        let count = session.roundsCounted
        return count == 1 ? "1 round" : "\(count) rounds"
    }

    private static func nextPhase(_ session: Session) -> String? {
        let nextIndex = session.segmentIndex + 1
        let exercises = session.configuration.emomExercises
        guard nextIndex < session.segments.count else {
            if exercises != nil { return "Final exercise" }
            return session.configuration.roundUnit.map { "Final \($0.lowercased())" }
        }
        let next = session.segments[nextIndex]
        if let exercises, next.kind == .work, let duration = next.countdownDuration {
            let exercise = session.segments[..<nextIndex].filter { $0.kind == .work }.count % exercises + 1
            return "Next: Exercise \(exercise) · \(format(duration))"
        }
        return "Next: " + (next.countdownDuration.map { "\(next.kind.name) \(format($0))" } ?? next.kind.name)
    }

    private static func fraction(_ part: Duration, of whole: Duration) -> Double {
        min(max(part / whole, 0), 1)
    }
}

extension Segment.Kind {
    var name: String {
        switch self {
        case .getReady: "Get ready"
        case .work: "Work"
        case .rest: "Rest"
        }
    }

    var label: String { name.uppercased() }
}

extension WorkoutConfiguration {
    /// Whether times are shown to hundredths of a second: For Time only, where they separate close results.
    public var showsHundredths: Bool {
        guard case .forTime = self else { return false }
        return true
    }

    /// Whether the athlete counts AMRAP rounds, which also shows the undo control.
    public var countsRounds: Bool {
        guard case .amrap(_, _, _, true) = self else { return false }
        return true
    }

    /// Exercises per EMOM round, when there is more than one to show within a round.
    var emomExercises: Int? {
        guard case .emom(_, let exercises, _, _) = self, exercises > 1 else { return nil }
        return exercises
    }

    /// The name for one repeat of the workout, for workouts that have several.
    var roundUnit: String? {
        switch self {
        case .amrap(_, let blocks, _, _): blocks > 1 ? "Block" : nil
        case .emom, .tabata, .intervals: "Round"
        case .sets: "Set"
        case .timer, .forTime, .stopwatch: nil
        }
    }
}
