/// What the live screen shows for a session at a moment. Views only render these values.
public struct SessionDisplay: Equatable, Sendable {
    public enum State: Equatable, Sendable {
        case getReady, work, rest, finalSeconds, paused, finished
    }

    static let finalSeconds: Duration = .seconds(3)

    /// The largest number: time left in a countdown phase, or time so far in a count-up phase.
    public let mainTime: String
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

        mainTime = timeLeft.map { Self.format($0, roundingUp: true) }
            ?? Self.format(session.elapsedInSegment(now))
        label = session.status == .paused ? "PAUSED" : segment.kind.label
        state = Self.state(session: session, timeLeft: timeLeft)
        secondaryTotal = Self.secondaryTotal(session.configuration, workoutTime: workoutTime)
        position = Self.position(session)
        nextPhase = Self.nextPhase(session)
        phaseProgress = segment.countdownDuration.map { Self.fraction(session.elapsedInSegment(now), of: $0) }
        workoutProgress = total.map { Self.fraction(workoutTime, of: $0) }
    }

    /// Minutes and seconds, with hours only when needed. Countdowns round up,
    /// so they show 0:00 only when the phase ends.
    public static func format(_ duration: Duration, roundingUp: Bool = false) -> String {
        let (seconds, attoseconds) = max(duration, .zero).components
        let wholeSeconds = Int(seconds) + (roundingUp && attoseconds > 0 ? 1 : 0)
        let (hours, minutes, secondsPart) = (wholeSeconds / 3600, wholeSeconds / 60 % 60, wholeSeconds % 60)
        let paddedSeconds = secondsPart < 10 ? "0\(secondsPart)" : "\(secondsPart)"
        guard hours > 0 else { return "\(minutes):\(paddedSeconds)" }
        let paddedMinutes = minutes < 10 ? "0\(minutes)" : "\(minutes)"
        return "\(hours):\(paddedMinutes):\(paddedSeconds)"
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
        let place = "\(unit) \(workSoFar + 1) of \(workSegments)\(next)"
        return rounds.map { "\(place) · \($0)" } ?? place
    }

    private static func roundsCountedText(_ session: Session) -> String? {
        guard case .amrap(_, _, _, true) = session.configuration else { return nil }
        let count = session.roundsCounted
        return count == 1 ? "1 round" : "\(count) rounds"
    }

    private static func nextPhase(_ session: Session) -> String? {
        let nextIndex = session.segmentIndex + 1
        guard nextIndex < session.segments.count else {
            return session.configuration.roundUnit.map { "Last \($0.lowercased())" }
        }
        let next = session.segments[nextIndex]
        return next.countdownDuration.map { "\(next.kind.name) \(format($0))" } ?? next.kind.name
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
