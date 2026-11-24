/// Everything a session needs to run a workout, whatever its type.
public struct WorkoutPlan: Equatable, Sendable {
    /// What the athlete records along the way.
    public enum Record: Equatable, Sendable {
        case rounds, splits
    }

    enum SecondaryTotal: Equatable, Sendable {
        case left(of: Duration), elapsed
    }

    /// Never empty.
    let phases: [Phase]
    /// The calculated total, excluding get-ready, worked out once. Nil when the athlete decides when a phase ends.
    let total: Duration?
    let secondaryTotal: SecondaryTotal?
    public let record: Record?
    /// Whether times are shown to hundredths of a second: For Time only, where they separate close results.
    public let showsHundredths: Bool

    init(phases: [Phase], showsHundredths: Bool = false) {
        precondition(!phases.isEmpty, "A workout needs at least one phase")
        self.phases = phases
        self.total = Self.total(of: phases)
        self.secondaryTotal = Self.secondaryTotal(of: phases, total: total)
        self.record = Self.record(of: phases)
        self.showsHundredths = showsHundredths
    }

    /// The same plan with a get-ready countdown first, unless `getReady` is zero.
    func starting(with getReady: Duration) -> WorkoutPlan {
        guard getReady > .zero else { return self }
        let phase = Phase(kind: .getReady, ending: .afterDuration(getReady), place: phases[0].place)
        return WorkoutPlan(phases: [phase] + phases, showsHundredths: showsHundredths)
    }

    private static func total(of phases: [Phase]) -> Duration? {
        var total = Duration.zero
        for phase in phases where phase.kind != .getReady {
            guard let duration = phase.countdownDuration else { return nil }
            total += duration
        }
        return total
    }

    /// Workouts with repeats show the time left, or elapsed when the length is unknown; a capped one shows the cap left.
    private static func secondaryTotal(of phases: [Phase], total: Duration?) -> SecondaryTotal? {
        guard let work = phases.first(where: { $0.kind == .work }) else { return nil }
        if work.place != nil { return total.map { .left(of: $0) } ?? .elapsed }
        guard case .byUser(let cap?) = work.ending else { return nil }
        return .left(of: cap)
    }

    private static func record(of phases: [Phase]) -> Record? {
        if phases.contains(where: { $0.mainAction == .countRound }) { return .rounds }
        if phases.contains(where: { $0.mainAction == .split }) { return .splits }
        return nil
    }

    /// Repeats `work` with rest only between repeats, and none when rest is zero.
    static func alternating(_ work: Phase, rest: Duration, count: Int, unit: Phase.Place.Unit) -> [Phase] {
        let count = SetupLimits.clamp(count)
        var phases: [Phase] = []
        for number in 1...count {
            let place = Phase.Place(unit: unit, number: number, count: count)
            if number > 1 && rest > .zero {
                phases.append(Phase(kind: .rest, ending: .afterDuration(rest), place: place))
            }
            var repeated = work
            repeated.place = place
            phases.append(repeated)
        }
        return phases
    }
}
