import Testing
@testable import WorkoutEngine

private let start = ContinuousClock.now

private func at(_ seconds: Double) -> Session.Instant {
    start + .milliseconds(Int((seconds * 1000).rounded()))
}

private func minutes(_ minutes: Int, _ seconds: Int = 0) -> Duration {
    .seconds(minutes * 60 + seconds)
}

private func session(_ configuration: WorkoutConfiguration, getReady: Int = 0) -> Session {
    Session(configuration: configuration, getReady: .seconds(getReady), startingAt: start)
}

/// Updates every 100 ms like the app does, returning each cue with the second it was reported.
private func run(_ session: inout Session, from: Double, to: Double) -> [(Double, CueEvent)] {
    var cues: [(Double, CueEvent)] = []
    var tenths = Int((from * 10).rounded())
    while tenths <= Int((to * 10).rounded()) {
        let second = Double(tenths) / 10
        cues += session.update(at(second)).map { (second, $0) }
        tenths += 1
    }
    return cues
}

private let intervals = WorkoutConfiguration.intervals(work: .seconds(45), rest: .seconds(15), rounds: 8)
private let amrap = WorkoutConfiguration.amrap(block: .seconds(300), blocks: 3, rest: .seconds(60), countsRounds: true)
private let sets = WorkoutConfiguration.sets(rest: .seconds(90), sets: 3)

@Suite struct PhaseAdvance {
    @Test func getReadyCountsDownThenTheFirstPhaseBegins() {
        var workout = session(intervals, getReady: 10)

        _ = workout.update(at(9.9))
        #expect(workout.isInGetReady)

        _ = workout.update(at(10))
        #expect(workout.currentSegment.kind == .work)
        #expect(workout.workoutTime(at(10)) == .zero)
    }

    @Test func getReadyDoesNotCountTowardsWorkoutTime() {
        var workout = session(intervals, getReady: 10)

        _ = workout.update(at(25))

        #expect(workout.workoutTime(at(25)) == .seconds(15))
    }

    @Test func getReadyOffStartsTheFirstPhaseImmediately() {
        let workout = session(intervals)

        #expect(workout.currentSegment.kind == .work)
        #expect(workout.timeLeftInSegment(at(0)) == .seconds(45))
    }

    @Test func skippingGetReadyStartsTheFirstPhaseNow() {
        var workout = session(intervals, getReady: 10)

        workout.skipGetReady(at(3))

        #expect(workout.currentSegment.kind == .work)
        #expect(workout.timeLeftInSegment(at(3)) == .seconds(45))
        #expect(workout.workoutTime(at(3)) == .zero)
    }

    @Test func phasesRunInOrderAndEndAfterTheLastWorkPhase() {
        var workout = session(.intervals(work: .seconds(45), rest: .seconds(15), rounds: 2))
        var kinds: [Segment.Kind] = [workout.currentSegment.kind]

        for second in [44.9, 45, 59.9, 60, 104.9] {
            _ = workout.update(at(second))
            kinds.append(workout.currentSegment.kind)
        }
        #expect(kinds == [.work, .work, .rest, .rest, .work, .work])
        #expect(workout.status == .running)

        _ = workout.update(at(105))
        #expect(workout.status == .finished)
        #expect(workout.workoutTime(at(200)) == minutes(1, 45))
    }

    @Test func oneUpdateCanPassSeveralBoundaries() {
        // work 0-10, rest 10-15, work 15-25, rest 25-30, work 30-40
        var workout = session(.intervals(work: .seconds(10), rest: .seconds(5), rounds: 3))

        _ = workout.update(at(27))

        #expect(workout.segmentIndex == 3)
        #expect(workout.currentSegment.kind == .rest)
        #expect(workout.elapsedInSegment(at(27)) == .seconds(2))
    }

    @Test func fortyMinuteWorkoutEndsExactlyOnTime() {
        var workout = session(.emom(window: .seconds(60), exercises: 1, rounds: 40, rest: .seconds(60)))

        _ = run(&workout, from: 0, to: 2399.9)
        #expect(workout.status == .running)

        _ = workout.update(at(2400))
        #expect(workout.status == .finished)
        #expect(workout.workoutTime(at(2500)) == minutes(40))
    }

    @Test func aSetBeginsCountingUpWhenItsRestEnds() {
        var workout = session(sets)
        workout.mainAction(at(30))

        _ = workout.update(at(125))

        #expect(workout.segmentIndex == 2)
        #expect(workout.timeLeftInSegment(at(125)) == nil)
        #expect(workout.elapsedInSegment(at(125)) == .seconds(5))
    }
}

@Suite struct PauseAndResume {
    @Test func pausingLeavesPhaseAndTotalTimeUnchanged() {
        // Round 3 work starts at 2:00, so 0:37 is left at 2:08.
        var workout = session(intervals)
        _ = workout.update(at(128))
        #expect(workout.timeLeftInSegment(at(128)) == .seconds(37))

        workout.pause(at(128))
        _ = workout.update(at(248))
        #expect(workout.timeLeftInSegment(at(248)) == .seconds(37))

        workout.resume(at(248))
        _ = workout.update(at(248))
        #expect(workout.segmentIndex == 4)
        #expect(workout.timeLeftInSegment(at(248)) == .seconds(37))
        #expect(workout.workoutTime(at(248)) == minutes(2, 8))
    }

    @Test func pausingWorksDuringGetReady() {
        var workout = session(intervals, getReady: 10)

        workout.pause(at(4))
        _ = workout.update(at(60))

        #expect(workout.isInGetReady)
        #expect(workout.timeLeftInSegment(at(60)) == .seconds(6))
    }

    @Test func endingEarlyKeepsTheWorkoutTimeReached() {
        var workout = session(intervals)
        workout.pause(at(100))

        workout.endWorkout()

        #expect(workout.status == .finished)
        #expect(workout.workoutTime(at(500)) == minutes(1, 40))
    }

    @Test func endWorkoutOnlyWhilePaused() {
        var workout = session(intervals)

        workout.endWorkout()

        #expect(workout.status == .running)
    }

    @Test func tapSkipsGetReadyInsteadOfPausing() {
        var workout = session(intervals, getReady: 10)

        workout.tap(at(2))

        #expect(workout.status == .running)
        #expect(workout.currentSegment.kind == .work)
    }

    @Test func spaceSkipsGetReadyInsteadOfPausing() {
        var workout = session(intervals, getReady: 10)

        workout.togglePause(at(2))

        #expect(workout.status == .running)
        #expect(workout.currentSegment.kind == .work)
    }

    @Test func tapWithNoMainActionPausesAndResumes() {
        var workout = session(intervals)

        workout.tap(at(5))
        #expect(workout.status == .paused)

        workout.tap(at(9))
        #expect(workout.status == .running)
        #expect(workout.timeLeftInSegment(at(9)) == .seconds(40))
    }
}

@Suite struct MainActions {
    @Test func tapCountsAnAmrapRoundAndKeepsRunning() {
        var workout = session(amrap)

        workout.tap(at(30))

        #expect(workout.roundsCounted == 1)
        #expect(workout.status == .running)
    }

    @Test func spaceAndHoldPauseWithoutCountingARound() {
        var spaced = session(amrap)
        var held = session(amrap)

        spaced.togglePause(at(30))
        held.pause(at(30))

        #expect(spaced.status == .paused)
        #expect(held.status == .paused)
        #expect(spaced.roundsCounted == 0)
        #expect(held.roundsCounted == 0)
    }

    @Test func holdPausesAndResumesWithoutCountingARound() {
        var workout = session(amrap)

        workout.hold(at(30))
        #expect(workout.status == .paused)

        workout.hold(at(40))
        #expect(workout.status == .running)
        #expect(workout.roundsCounted == 0)
    }

    @Test func holdPausesGetReadyInsteadOfSkippingIt() {
        var workout = session(intervals, getReady: 10)

        workout.hold(at(2))

        #expect(workout.status == .paused)
        #expect(workout.isInGetReady)
    }

    @Test func undoRemovesTheLastRound() {
        var workout = session(amrap)
        for second in 1...4 { workout.tap(at(Double(second))) }

        workout.undoRound()

        #expect(workout.roundsCounted == 3)
    }

    @Test func undoWithNoRoundsHasNoEffect() {
        var workout = session(amrap)

        workout.undoRound()

        #expect(workout.roundsCounted == 0)
    }

    @Test func roundsAccumulateAcrossBlocks() {
        var workout = session(amrap)
        workout.tap(at(10))
        _ = workout.update(at(370))

        workout.tap(at(370))

        #expect(workout.segmentIndex == 2)
        #expect(workout.roundsCounted == 2)
    }

    @Test func tapDuringAmrapRestPausesWithoutCountingARound() {
        var workout = session(amrap)
        _ = workout.update(at(310))

        workout.tap(at(310))

        #expect(workout.status == .paused)
        #expect(workout.roundsCounted == 0)
    }

    @Test func tapPausesWhenRoundCountingIsOff() {
        var workout = session(.amrap(block: .seconds(300), blocks: 1, rest: .seconds(60), countsRounds: false))

        workout.tap(at(30))

        #expect(workout.status == .paused)
        #expect(workout.roundsCounted == 0)
    }

    @Test func forTimeRecordsEachRoundsTime() {
        var workout = session(.forTime(cap: nil), getReady: 10)
        _ = workout.update(at(10))

        workout.tap(at(10 + 130))
        workout.tap(at(10 + 270))

        #expect(workout.splits == [minutes(2, 10), minutes(2, 20)])
        #expect(workout.status == .running)
    }

    @Test func forTimeSplitsKeepHundredths() {
        var workout = session(.forTime(cap: nil), getReady: 10)
        _ = workout.update(at(10))

        workout.tap(at(10 + 130.25))
        workout.tap(at(10 + 270.5))

        #expect(workout.splits.map { SessionDisplay.format($0, hundredths: true) } == ["2:10.25", "2:20.25"])
        #expect(SessionDisplay.format(workout.workoutTime(at(10 + 270.5)), hundredths: true) == "4:30.50")
    }

    @Test func forTimeSplitHundredthsAreNotRoundedUp() {
        var workout = session(.forTime(cap: nil))

        workout.tap(at(60.999))

        #expect(SessionDisplay.format(workout.splits[0], hundredths: true) == "1:00.99")
    }

    @Test func finishEndsForTimeWithTheTimeReached() {
        var workout = session(.forTime(cap: nil))

        workout.finish(at(270))

        #expect(workout.status == .finished)
        #expect(workout.workoutTime(at(400)) == minutes(4, 30))
    }

    @Test func finishEndsStopwatch() {
        var workout = session(.stopwatch)

        workout.finish(at(12))

        #expect(workout.status == .finished)
    }

    @Test func finishDoesNothingForClockDrivenWorkouts() {
        var workout = session(intervals)

        workout.finish(at(12))

        #expect(workout.status == .running)
    }

    @Test func forTimeEndsAtItsCap() {
        var workout = session(.forTime(cap: minutes(20)))

        _ = workout.update(at(1199.9))
        #expect(workout.status == .running)

        _ = workout.update(at(1200.05))
        #expect(workout.status == .finished)
        #expect(workout.workoutTime(at(1300)) == minutes(20))
    }

    @Test func markingASetDoneStartsTheRest() {
        var workout = session(sets)

        workout.mainAction(at(40))

        #expect(workout.currentSegment.kind == .rest)
        #expect(workout.timeLeftInSegment(at(40)) == minutes(1, 30))
    }

    @Test func markingTheLastSetDoneEndsTheWorkout() {
        var workout = session(.sets(rest: .seconds(90), sets: 1))

        workout.tap(at(40))

        #expect(workout.status == .finished)
        #expect(workout.workoutTime(at(100)) == .seconds(40))
    }

    @Test func noMainActionDuringASetsRest() {
        var workout = session(sets)
        workout.mainAction(at(40))

        workout.mainAction(at(50))

        #expect(workout.segmentIndex == 1)
        #expect(workout.availableAction == nil)
    }
}

@Suite struct Cues {
    @Test func ticksPlayOnceAtThreeTwoAndOneSecondsLeft() {
        var workout = session(.timer(duration: .seconds(10)))

        let cues = run(&workout, from: 0, to: 12)

        #expect(cues.map(\.0) == [0, 7, 8, 9, 10])
        #expect(cues.map(\.1) == [.workStart, .tick, .tick, .tick, .finish])
    }

    @Test func getReadyTicksThenWorkStarts() {
        var workout = session(.timer(duration: .seconds(60)), getReady: 10)

        let cues = run(&workout, from: 0, to: 10)

        #expect(cues.map(\.0) == [7, 8, 9, 10])
        #expect(cues.map(\.1) == [.tick, .tick, .tick, .workStart])
    }

    @Test func workAndRestStartsHaveTheirOwnSounds() {
        var workout = session(.intervals(work: .seconds(5), rest: .seconds(5), rounds: 2))

        let cues = run(&workout, from: 0, to: 16).map(\.1).filter { $0 != .tick }

        #expect(cues == [.workStart, .restStart, .workStart, .finish])
    }

    @Test func eachEmomExercisePlaysTheWorkSoundAndRoundsRest() {
        var workout = session(.emom(window: .seconds(5), exercises: 2, rounds: 2, rest: .seconds(5)))

        let cues = run(&workout, from: 0, to: 26).map(\.1).filter { $0 != .tick }

        #expect(cues == [.workStart, .workStart, .restStart, .workStart, .workStart, .finish])
    }

    @Test func aSetStartingAfterRestPlaysTheWorkSound() {
        var workout = session(sets)
        _ = workout.update(at(0))
        workout.mainAction(at(30))

        let cues = run(&workout, from: 30, to: 120).map(\.1).filter { $0 != .tick }

        #expect(cues == [.restStart, .workStart])
    }

    @Test func finishingByHandPlaysTheFinishSound() {
        var workout = session(.stopwatch)
        _ = workout.update(at(0))

        workout.finish(at(20))

        #expect(workout.update(at(20.1)) == [.finish])
    }

    @Test func ticksResumeAfterAPauseWithoutRepeating() {
        var workout = session(.timer(duration: .seconds(10)))
        let before = run(&workout, from: 0, to: 7.5)

        workout.pause(at(7.5))
        let whilePaused = run(&workout, from: 7.6, to: 20)
        workout.resume(at(20))
        let after = run(&workout, from: 20, to: 25)

        #expect(before.map(\.1) == [.workStart, .tick])
        #expect(whilePaused.isEmpty)
        #expect(after.map(\.0) == [20.5, 21.5, 22.5])
        #expect(after.map(\.1) == [.tick, .tick, .finish])
    }

    @Test func skippedGetReadyPlaysNoTicks() {
        var workout = session(.timer(duration: .seconds(60)), getReady: 10)
        _ = run(&workout, from: 0, to: 5)

        workout.tap(at(5))
        let cues = run(&workout, from: 5.1, to: 15)

        #expect(cues.map(\.1) == [.workStart])
    }

    @Test func cuesPassedDuringALongStallAreDropped() {
        var workout = session(.timer(duration: .seconds(10)))
        _ = workout.update(at(0))

        #expect(workout.update(at(12)) == [])
        #expect(workout.status == .finished)
    }

    @Test func aCueLessThanASecondLateStillPlays() {
        // work 0-10, rest 10-15, work 15-25, rest 25-30
        var workout = session(.intervals(work: .seconds(10), rest: .seconds(5), rounds: 3))
        _ = workout.update(at(0))

        #expect(workout.update(at(25.5)) == [.restStart])
    }
}
