import Testing
@testable import WorkoutEngine

@Suite struct WorkoutConfigurationDefaults {
    @Test func eightWorkoutTypesWithTheSpecDefaults() {
        #expect(WorkoutConfiguration.defaults == [
            .timer(duration: .seconds(5 * 60)),
            .amrap(block: .seconds(12 * 60), blocks: 1, rest: .seconds(60), countsRounds: true),
            .emom(window: .seconds(60), exercises: 1, rounds: 10, rest: .seconds(60)),
            .tabata(rounds: 8),
            .intervals(work: .seconds(40), rest: .seconds(20), rounds: 8),
            .forTime(cap: nil),
            .stopwatch,
            .sets(rest: .seconds(90), sets: 5),
        ])
    }

    @Test func tabataWorkAndRestAreFixed() {
        #expect(WorkoutConfiguration.tabataWork == .seconds(20))
        #expect(WorkoutConfiguration.tabataRest == .seconds(10))
    }
}
