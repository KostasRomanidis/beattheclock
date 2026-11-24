import Testing
@testable import WorkoutEngine

private func work(_ seconds: Int) -> Phase {
    Phase(kind: .work, ending: .afterDuration(.seconds(seconds)))
}

private func rest(_ seconds: Int) -> Phase {
    Phase(kind: .rest, ending: .afterDuration(.seconds(seconds)))
}

private let set = Phase(kind: .work, ending: .byUser(cap: nil))

/// The phases' kinds and endings alone; `Places` and `PhaseActions` cover the rest.
private func timeline(_ configuration: WorkoutConfiguration) -> [Phase] {
    configuration.plan().phases.map { Phase(kind: $0.kind, ending: $0.ending) }
}

@Suite struct Timelines {
    @Test func intervalsRunEightWorkPhasesWithSevenRestsBetween() {
        let timeline = timeline(WorkoutConfiguration.intervals(Intervals(work: .seconds(45), rest: .seconds(15), rounds: 8)))

        #expect(timeline.count == 15)
        #expect(timeline.filter { $0 == work(45) }.count == 8)
        #expect(timeline.filter { $0 == rest(15) }.count == 7)
        #expect(timeline.last == work(45))
    }

    @Test func amrapBlocksAlternateWithRest() {
        let timeline = timeline(WorkoutConfiguration.amrap(Amrap(block: .seconds(300), blocks: 3, rest: .seconds(60), countsRounds: true)))

        #expect(timeline == [work(300), rest(60), work(300), rest(60), work(300)])
    }

    @Test func emomWindowsRunBackToBack() {
        let timeline = timeline(WorkoutConfiguration.emom(Emom(window: .seconds(60), exercises: 1, rounds: 10, rest: .seconds(60))))

        #expect(timeline == Array(repeating: work(60), count: 10))
    }

    @Test func emomRestsBetweenRoundsOfExercises() {
        let timeline = timeline(WorkoutConfiguration.emom(Emom(window: .seconds(60), exercises: 5, rounds: 3, rest: .seconds(60))))
        let round = Array(repeating: work(60), count: 5)

        #expect(timeline == round + [rest(60)] + round + [rest(60)] + round)
        #expect(timeline.count == 17)
        #expect(WorkoutConfiguration.emom(Emom(window: .seconds(60), exercises: 5, rounds: 3, rest: .seconds(60))).total == .seconds(17 * 60))
    }

    @Test func emomRoundsWithNoRestRunBackToBack() {
        let timeline = timeline(WorkoutConfiguration.emom(Emom(window: .seconds(60), exercises: 5, rounds: 3, rest: .zero)))

        #expect(timeline == Array(repeating: work(60), count: 15))
    }

    @Test func singleExerciseEmomIgnoresItsStoredRest() {
        let timeline = timeline(WorkoutConfiguration.emom(Emom(window: .seconds(60), exercises: 1, rounds: 10, rest: .seconds(60))))

        #expect(timeline == Array(repeating: work(60), count: 10))
    }

    @Test func tabataUsesFixedWorkAndRest() {
        let timeline = timeline(WorkoutConfiguration.tabata(Tabata(rounds: 2)))

        #expect(timeline == [work(20), rest(10), work(20)])
    }

    @Test func timerIsOneCountdown() {
        #expect(timeline(WorkoutConfiguration.countdown(Countdown(duration: .seconds(300)))) == [work(300)])
    }

    @Test func zeroRestRunsWorkPhasesBackToBack() {
        let timeline = timeline(WorkoutConfiguration.intervals(Intervals(work: .seconds(45), rest: .zero, rounds: 3)))

        #expect(timeline == [work(45), work(45), work(45)])
    }

    @Test func noRestAfterTheLastWorkPhase() {
        let intervals = timeline(WorkoutConfiguration.intervals(Intervals(work: .seconds(40), rest: .seconds(20), rounds: 1)))
        let sets = timeline(WorkoutConfiguration.sets(Sets(rest: .seconds(90), sets: 1)))

        #expect(intervals == [work(40)])
        #expect(sets == [set])
    }

    @Test func setsCountUpWithTimedRestBetween() {
        let timeline = timeline(WorkoutConfiguration.sets(Sets(rest: .seconds(90), sets: 3)))

        #expect(timeline == [set, rest(90), set, rest(90), set])
    }

    @Test func forTimeCountsUpToItsCap() {
        let capped = timeline(WorkoutConfiguration.forTime(ForTime(cap: .seconds(20 * 60))))
        let uncapped = timeline(WorkoutConfiguration.forTime(ForTime(cap: nil)))

        #expect(capped == [Phase(kind: .work, ending: .byUser(cap: .seconds(20 * 60)))])
        #expect(uncapped == [set])
    }

    @Test func stopwatchCountsUpWithNoCap() {
        #expect(timeline(WorkoutConfiguration.stopwatch(Stopwatch())) == [set])
    }
}

@Suite struct CalculatedTotal {
    @Test func intervalsExampleTotalsSevenFortyFive() {
        let intervals = WorkoutConfiguration.intervals(Intervals(work: .seconds(45), rest: .seconds(15), rounds: 8))

        #expect(intervals.total == .seconds(7 * 60 + 45))
    }

    @Test func threeAmrapBlocksTotalSeventeenMinutes() {
        let amrap = WorkoutConfiguration.amrap(Amrap(block: .seconds(300), blocks: 3, rest: .seconds(60), countsRounds: true))

        #expect(amrap.total == .seconds(17 * 60))
    }

    @Test func athleteEndedWorkoutsHaveNoTotal() {
        #expect(WorkoutConfiguration.forTime(ForTime(cap: nil)).total == nil)
        #expect(WorkoutConfiguration.forTime(ForTime(cap: .seconds(20 * 60))).total == nil)
        #expect(WorkoutConfiguration.stopwatch(Stopwatch()).total == nil)
        #expect(WorkoutConfiguration.sets(Sets(rest: .seconds(90), sets: 5)).total == nil)
    }
}

@Suite struct InvalidCounts {
    private func workPhases(_ configuration: WorkoutConfiguration) -> Int {
        configuration.plan().phases.filter { $0.kind == .work }.count
    }

    @Test func zeroAndNegativeCountsStillBuildOneWorkPhase() {
        let configurations: [WorkoutConfiguration] = [
            .amrap(Amrap(block: .seconds(60), blocks: 0, rest: .seconds(60), countsRounds: false)),
            .emom(Emom(window: .seconds(60), exercises: 0, rounds: 0, rest: .seconds(60))),
            .tabata(Tabata(rounds: -1)),
            .intervals(Intervals(work: .seconds(20), rest: .seconds(10), rounds: 0)),
            .sets(Sets(rest: .seconds(60), sets: -3)),
        ]
        for configuration in configurations {
            #expect(workPhases(configuration) == 1)
        }
    }

    @Test func countsAboveTheLimitStopAtTheLimit() {
        #expect(workPhases(.tabata(Tabata(rounds: 500))) == SetupLimits.counts.upperBound)
    }
}

@Suite struct Places {
    private func places(_ configuration: WorkoutConfiguration) -> [Phase.Place?] {
        configuration.plan().phases.map(\.place)
    }

    @Test func emomPlacesExercisesWithinRoundsAndRestHoldsTheNextRound() {
        let circuit = WorkoutConfiguration.emom(Emom(window: .seconds(60), exercises: 2, rounds: 2, rest: .seconds(60)))

        #expect(places(circuit) == [
            Phase.Place(unit: .round, number: 1, count: 2, exercise: .init(number: 1, count: 2)),
            Phase.Place(unit: .round, number: 1, count: 2, exercise: .init(number: 2, count: 2)),
            Phase.Place(unit: .round, number: 2, count: 2),
            Phase.Place(unit: .round, number: 2, count: 2, exercise: .init(number: 1, count: 2)),
            Phase.Place(unit: .round, number: 2, count: 2, exercise: .init(number: 2, count: 2)),
        ])
    }

    @Test func singleExerciseEmomHasNoExercisePlace() {
        let emom = WorkoutConfiguration.emom(Emom(window: .seconds(60), exercises: 1, rounds: 2, rest: .seconds(60)))

        #expect(places(emom) == [
            Phase.Place(unit: .round, number: 1, count: 2),
            Phase.Place(unit: .round, number: 2, count: 2),
        ])
    }

    @Test func restHoldsThePlaceComingNext() {
        #expect(places(.sets(Sets(rest: .seconds(90), sets: 2))) == [
            Phase.Place(unit: .set, number: 1, count: 2),
            Phase.Place(unit: .set, number: 2, count: 2),
            Phase.Place(unit: .set, number: 2, count: 2),
        ])
    }

    @Test func amrapHasPlacesOnlyWithSeveralBlocks() {
        #expect(places(.amrap(Amrap(block: .seconds(60), blocks: 1, rest: .seconds(60), countsRounds: true))) == [nil])
        #expect(places(.amrap(Amrap(block: .seconds(60), blocks: 2, rest: .zero, countsRounds: true))) == [
            Phase.Place(unit: .block, number: 1, count: 2),
            Phase.Place(unit: .block, number: 2, count: 2),
        ])
    }
}

@Suite struct PhaseActions {
    @Test func onlyWorkPhasesHaveTheirWorkoutsAction() {
        let blocks = WorkoutConfiguration.amrap(Amrap(block: .seconds(60), blocks: 2, rest: .seconds(60), countsRounds: true))

        #expect(blocks.plan().phases.map(\.mainAction) == [.countRound, nil, .countRound])
        #expect(WorkoutConfiguration.sets(Sets(rest: .seconds(90), sets: 2)).plan().phases.map(\.mainAction) == [.setDone, nil, .setDone])
        #expect(WorkoutConfiguration.forTime(ForTime(cap: nil)).plan().phases.map(\.mainAction) == [.split])
    }

    @Test func onlyForTimeAndStopwatchCanFinish() {
        for configuration in WorkoutConfiguration.defaults {
            let expected = configuration == .forTime(ForTime(cap: nil)) || configuration == .stopwatch(Stopwatch())
            #expect(configuration.plan().phases.allSatisfy { $0.canFinish == expected })
        }
    }
}
