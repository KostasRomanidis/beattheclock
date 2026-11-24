// Each workout type's settings, starting at their defaults, and the plan they make.
// Counts are clamped to `SetupLimits.counts`, so a plan always has at least one phase.

public struct Countdown: Equatable, Sendable {
    public var duration: Duration

    public init(duration: Duration = .seconds(5 * 60)) {
        self.duration = duration
    }

    func plan() -> WorkoutPlan {
        WorkoutPlan(phases: [Phase(kind: .work, ending: .afterDuration(duration))])
    }
}

public struct Amrap: Equatable, Sendable {
    public var block: Duration
    public var blocks: Int
    public var rest: Duration
    public var countsRounds: Bool

    public init(block: Duration = .seconds(12 * 60), blocks: Int = 1, rest: Duration = .seconds(60), countsRounds: Bool = true) {
        self.block = block
        self.blocks = blocks
        self.rest = rest
        self.countsRounds = countsRounds
    }

    func plan() -> WorkoutPlan {
        let work = Phase(kind: .work, ending: .afterDuration(block), mainAction: countsRounds ? .countRound : nil)
        guard blocks > 1 else { return WorkoutPlan(phases: [work]) }
        return WorkoutPlan(phases: WorkoutPlan.alternating(work, rest: rest, count: blocks, unit: .block))
    }
}

public struct Emom: Equatable, Sendable {
    public var window: Duration
    public var exercises: Int
    public var rounds: Int
    /// Runs between rounds and applies only with more than one exercise,
    /// so a single-exercise EMOM never turns into intervals.
    public var rest: Duration

    public init(window: Duration = .seconds(60), exercises: Int = 1, rounds: Int = 10, rest: Duration = .seconds(60)) {
        self.window = window
        self.exercises = exercises
        self.rounds = rounds
        self.rest = rest
    }

    func plan() -> WorkoutPlan {
        let exercises = SetupLimits.clamp(exercises)
        let rounds = SetupLimits.clamp(rounds)
        var phases: [Phase] = []
        for round in 1...rounds {
            var place = Phase.Place(unit: .round, number: round, count: rounds)
            if round > 1 && exercises > 1 && rest > .zero {
                phases.append(Phase(kind: .rest, ending: .afterDuration(rest), place: place))
            }
            for exercise in 1...exercises {
                if exercises > 1 { place.exercise = Phase.Place.Exercise(number: exercise, count: exercises) }
                phases.append(Phase(kind: .work, ending: .afterDuration(window), place: place))
            }
        }
        return WorkoutPlan(phases: phases)
    }
}

public struct Tabata: Equatable, Sendable {
    public static let work: Duration = .seconds(20)
    public static let rest: Duration = .seconds(10)

    public var rounds: Int

    public init(rounds: Int = 8) {
        self.rounds = rounds
    }

    func plan() -> WorkoutPlan {
        Intervals(work: Self.work, rest: Self.rest, rounds: rounds).plan()
    }
}

public struct Intervals: Equatable, Sendable {
    public var work: Duration
    public var rest: Duration
    public var rounds: Int

    public init(work: Duration = .seconds(40), rest: Duration = .seconds(20), rounds: Int = 8) {
        self.work = work
        self.rest = rest
        self.rounds = rounds
    }

    func plan() -> WorkoutPlan {
        let work = Phase(kind: .work, ending: .afterDuration(work))
        return WorkoutPlan(phases: WorkoutPlan.alternating(work, rest: rest, count: rounds, unit: .round))
    }
}

public struct ForTime: Equatable, Sendable {
    public var cap: Duration?

    public init(cap: Duration? = nil) {
        self.cap = cap
    }

    func plan() -> WorkoutPlan {
        WorkoutPlan(phases: [Phase(kind: .work, ending: .byUser(cap: cap), mainAction: .split, canFinish: true)],
                    showsHundredths: true)
    }
}

public struct Stopwatch: Equatable, Sendable {
    public init() {}

    func plan() -> WorkoutPlan {
        WorkoutPlan(phases: [Phase(kind: .work, ending: .byUser(cap: nil), canFinish: true)])
    }
}

public struct Sets: Equatable, Sendable {
    public var rest: Duration
    public var sets: Int

    public init(rest: Duration = .seconds(90), sets: Int = 5) {
        self.rest = rest
        self.sets = sets
    }

    func plan() -> WorkoutPlan {
        let work = Phase(kind: .work, ending: .byUser(cap: nil), mainAction: .setDone)
        return WorkoutPlan(phases: WorkoutPlan.alternating(work, rest: rest, count: sets, unit: .set))
    }
}
