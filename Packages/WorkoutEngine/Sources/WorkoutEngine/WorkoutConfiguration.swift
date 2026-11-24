/// One workout type with its settings. A closed list, so a new type fails to compile in every `switch`.
public enum WorkoutConfiguration: Equatable, Sendable {
    case countdown(Countdown)
    case amrap(Amrap)
    case emom(Emom)
    case tabata(Tabata)
    case intervals(Intervals)
    case forTime(ForTime)
    case stopwatch(Stopwatch)
    case sets(Sets)

    /// Every workout type with its default settings, in the order the app offers them.
    /// The compiler does not check this list, so add a new type here too.
    public static let defaults: [WorkoutConfiguration] = [
        .countdown(Countdown()),
        .amrap(Amrap()),
        .emom(Emom()),
        .tabata(Tabata()),
        .intervals(Intervals()),
        .forTime(ForTime()),
        .stopwatch(Stopwatch()),
        .sets(Sets()),
    ]

    public func plan() -> WorkoutPlan {
        switch self {
        case .countdown(let workout): workout.plan()
        case .amrap(let workout): workout.plan()
        case .emom(let workout): workout.plan()
        case .tabata(let workout): workout.plan()
        case .intervals(let workout): workout.plan()
        case .forTime(let workout): workout.plan()
        case .stopwatch(let workout): workout.plan()
        case .sets(let workout): workout.plan()
        }
    }

    /// The calculated total, or nil when the athlete decides when a phase ends.
    public var total: Duration? { plan().total }
}
