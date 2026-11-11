import Testing
@testable import WorkoutEngine

private func work(_ seconds: Int) -> Segment {
    Segment(kind: .work, ending: .afterDuration(.seconds(seconds)))
}

private func rest(_ seconds: Int) -> Segment {
    Segment(kind: .rest, ending: .afterDuration(.seconds(seconds)))
}

private let set = Segment(kind: .work, ending: .byUser(cap: nil))

@Suite struct Timelines {
    @Test func intervalsRunEightWorkPhasesWithSevenRestsBetween() {
        let timeline = WorkoutConfiguration.intervals(work: .seconds(45), rest: .seconds(15), rounds: 8).timeline()

        #expect(timeline.count == 15)
        #expect(timeline.filter { $0 == work(45) }.count == 8)
        #expect(timeline.filter { $0 == rest(15) }.count == 7)
        #expect(timeline.last == work(45))
    }

    @Test func amrapBlocksAlternateWithRest() {
        let timeline = WorkoutConfiguration.amrap(block: .seconds(300), blocks: 3, rest: .seconds(60), countsRounds: true).timeline()

        #expect(timeline == [work(300), rest(60), work(300), rest(60), work(300)])
    }

    @Test func emomWindowsRunBackToBack() {
        let timeline = WorkoutConfiguration.emom(window: .seconds(60), exercises: 1, rounds: 10, rest: .seconds(60)).timeline()

        #expect(timeline == Array(repeating: work(60), count: 10))
    }

    @Test func emomRestsBetweenRoundsOfExercises() {
        let timeline = WorkoutConfiguration.emom(window: .seconds(60), exercises: 5, rounds: 3, rest: .seconds(60)).timeline()
        let round = Array(repeating: work(60), count: 5)

        #expect(timeline == round + [rest(60)] + round + [rest(60)] + round)
        #expect(timeline.count == 17)
        #expect(WorkoutConfiguration.emom(window: .seconds(60), exercises: 5, rounds: 3, rest: .seconds(60)).total == .seconds(17 * 60))
    }

    @Test func emomRoundsWithNoRestRunBackToBack() {
        let timeline = WorkoutConfiguration.emom(window: .seconds(60), exercises: 5, rounds: 3, rest: .zero).timeline()

        #expect(timeline == Array(repeating: work(60), count: 15))
    }

    @Test func singleExerciseEmomIgnoresItsStoredRest() {
        let timeline = WorkoutConfiguration.emom(window: .seconds(60), exercises: 1, rounds: 10, rest: .seconds(60)).timeline()

        #expect(timeline == Array(repeating: work(60), count: 10))
    }

    @Test func tabataUsesFixedWorkAndRest() {
        let timeline = WorkoutConfiguration.tabata(rounds: 2).timeline()

        #expect(timeline == [work(20), rest(10), work(20)])
    }

    @Test func timerIsOneCountdown() {
        #expect(WorkoutConfiguration.timer(duration: .seconds(300)).timeline() == [work(300)])
    }

    @Test func zeroRestRunsWorkPhasesBackToBack() {
        let timeline = WorkoutConfiguration.intervals(work: .seconds(45), rest: .zero, rounds: 3).timeline()

        #expect(timeline == [work(45), work(45), work(45)])
    }

    @Test func noRestAfterTheLastWorkPhase() {
        let intervals = WorkoutConfiguration.intervals(work: .seconds(40), rest: .seconds(20), rounds: 1).timeline()
        let sets = WorkoutConfiguration.sets(rest: .seconds(90), sets: 1).timeline()

        #expect(intervals == [work(40)])
        #expect(sets == [set])
    }

    @Test func setsCountUpWithTimedRestBetween() {
        let timeline = WorkoutConfiguration.sets(rest: .seconds(90), sets: 3).timeline()

        #expect(timeline == [set, rest(90), set, rest(90), set])
    }

    @Test func forTimeCountsUpToItsCap() {
        let capped = WorkoutConfiguration.forTime(cap: .seconds(20 * 60)).timeline()
        let uncapped = WorkoutConfiguration.forTime(cap: nil).timeline()

        #expect(capped == [Segment(kind: .work, ending: .byUser(cap: .seconds(20 * 60)))])
        #expect(uncapped == [set])
    }

    @Test func stopwatchCountsUpWithNoCap() {
        #expect(WorkoutConfiguration.stopwatch.timeline() == [set])
    }
}

@Suite struct CalculatedTotal {
    @Test func intervalsExampleTotalsSevenFortyFive() {
        let intervals = WorkoutConfiguration.intervals(work: .seconds(45), rest: .seconds(15), rounds: 8)

        #expect(intervals.total == .seconds(7 * 60 + 45))
    }

    @Test func threeAmrapBlocksTotalSeventeenMinutes() {
        let amrap = WorkoutConfiguration.amrap(block: .seconds(300), blocks: 3, rest: .seconds(60), countsRounds: true)

        #expect(amrap.total == .seconds(17 * 60))
    }

    @Test func athleteEndedWorkoutsHaveNoTotal() {
        #expect(WorkoutConfiguration.forTime(cap: nil).total == nil)
        #expect(WorkoutConfiguration.forTime(cap: .seconds(20 * 60)).total == nil)
        #expect(WorkoutConfiguration.stopwatch.total == nil)
        #expect(WorkoutConfiguration.sets(rest: .seconds(90), sets: 5).total == nil)
    }
}

@Suite struct InvalidCounts {
    private func workSegments(_ configuration: WorkoutConfiguration) -> Int {
        configuration.timeline().filter { $0.kind == .work }.count
    }

    @Test func zeroAndNegativeCountsStillBuildOneWorkPhase() {
        let configurations: [WorkoutConfiguration] = [
            .amrap(block: .seconds(60), blocks: 0, rest: .seconds(60), countsRounds: false),
            .emom(window: .seconds(60), exercises: 0, rounds: 0, rest: .seconds(60)),
            .tabata(rounds: -1),
            .intervals(work: .seconds(20), rest: .seconds(10), rounds: 0),
            .sets(rest: .seconds(60), sets: -3),
        ]
        for configuration in configurations {
            #expect(workSegments(configuration) == 1)
        }
    }

    @Test func countsAboveTheLimitStopAtTheLimit() {
        #expect(workSegments(.tabata(rounds: 500)) == SetupLimits.counts.upperBound)
    }
}
