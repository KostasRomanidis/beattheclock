import Testing
@testable import WorkoutEngine

@Suite struct WorkoutConfigurationDefaults {
    @Test func eightWorkoutTypesWithTheSpecDefaults() {
        #expect(WorkoutConfiguration.defaults == [
            .countdown(Countdown(duration: .seconds(5 * 60))),
            .amrap(Amrap(block: .seconds(12 * 60), blocks: 1, rest: .seconds(60), countsRounds: true)),
            .emom(Emom(window: .seconds(60), exercises: 1, rounds: 10, rest: .seconds(60))),
            .tabata(Tabata(rounds: 8)),
            .intervals(Intervals(work: .seconds(40), rest: .seconds(20), rounds: 8)),
            .forTime(ForTime(cap: nil)),
            .stopwatch(Stopwatch()),
            .sets(Sets(rest: .seconds(90), sets: 5)),
        ])
    }

    @Test func tabataWorkAndRestAreFixed() {
        #expect(Tabata.work == .seconds(20))
        #expect(Tabata.rest == .seconds(10))
    }
}
