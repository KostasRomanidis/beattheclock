/// One workout type with its settings. Each type has exactly the settings its spec lists.
public enum WorkoutConfiguration: Equatable, Sendable {
    case timer(duration: Duration)
    case amrap(block: Duration, blocks: Int, rest: Duration, countsRounds: Bool)
    case emom(window: Duration, rounds: Int)
    case tabata(rounds: Int)
    case intervals(work: Duration, rest: Duration, rounds: Int)
    case forTime(cap: Duration?)
    case stopwatch
    case sets(rest: Duration, sets: Int)

    public static let tabataWork: Duration = .seconds(20)
    public static let tabataRest: Duration = .seconds(10)

    /// Every workout type with its default settings, in the order the app offers them.
    public static let defaults: [WorkoutConfiguration] = [
        .timer(duration: .seconds(5 * 60)),
        .amrap(block: .seconds(12 * 60), blocks: 1, rest: .seconds(60), countsRounds: true),
        .emom(window: .seconds(60), rounds: 10),
        .tabata(rounds: 8),
        .intervals(work: .seconds(40), rest: .seconds(20), rounds: 8),
        .forTime(cap: nil),
        .stopwatch,
        .sets(rest: .seconds(90), sets: 5),
    ]
}
