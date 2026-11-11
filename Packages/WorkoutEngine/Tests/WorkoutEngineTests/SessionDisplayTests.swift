import Testing
@testable import WorkoutEngine

private let start = ContinuousClock.now

private func at(_ seconds: Double) -> Session.Instant {
    start + .milliseconds(Int((seconds * 1000).rounded()))
}

private func session(_ configuration: WorkoutConfiguration, getReady: Int = 0) -> Session {
    Session(configuration: configuration, getReady: .seconds(getReady), startingAt: start)
}

/// The display after updating the session to `seconds`.
private func display(_ session: inout Session, at seconds: Double) -> SessionDisplay {
    _ = session.update(at(seconds))
    return SessionDisplay(session: session, now: at(seconds))
}

private let intervals = WorkoutConfiguration.intervals(work: .seconds(45), rest: .seconds(15), rounds: 8)
private let sets = WorkoutConfiguration.sets(rest: .seconds(90), sets: 5)
// Rounds start at 0, 6:00 and 12:00, with rests at 5:00 and 11:00.
private let circuit = WorkoutConfiguration.emom(window: .seconds(60), exercises: 5, rounds: 3, rest: .seconds(60))

@Suite struct TimeFormat {
    @Test func underAnHourShowsMinutesAndSeconds() {
        #expect(SessionDisplay.format(.seconds(45)) == "0:45")
        #expect(SessionDisplay.format(.seconds(12 * 60)) == "12:00")
    }

    @Test func overAnHourAddsHours() {
        #expect(SessionDisplay.format(.seconds(3600 + 2 * 60 + 5)) == "1:02:05")
    }

    @Test func countdownShowsTheLastSecondAsOne() {
        #expect(SessionDisplay.format(.milliseconds(400), roundingUp: true) == "0:01")
        #expect(SessionDisplay.format(.zero, roundingUp: true) == "0:00")
    }

    @Test func elapsedTimeRoundsDown() {
        #expect(SessionDisplay.format(.milliseconds(59_900)) == "0:59")
    }

    @Test func hundredthsAreCutOffNotRounded() {
        #expect(SessionDisplay.format(.milliseconds(130_679), hundredths: true) == "2:10.67")
        #expect(SessionDisplay.format(.milliseconds(59_996), hundredths: true) == "0:59.99")
    }

    @Test func hundredthsAreAlwaysTwoDigits() {
        #expect(SessionDisplay.format(.seconds(240), hundredths: true) == "4:00.00")
        #expect(SessionDisplay.format(.milliseconds(5_050), hundredths: true) == "0:05.05")
    }

    @Test func hundredthsComeAfterHours() {
        #expect(SessionDisplay.format(.milliseconds((3600 + 2 * 60 + 5) * 1000 + 500), hundredths: true) == "1:02:05.50")
    }
}

@Suite struct PresetLabels {
    @Test func wholeMinutesReadInMinutes() {
        #expect(SessionDisplay.presetLabel(.seconds(12 * 60)) == "12 min")
        #expect(SessionDisplay.presetLabel(.seconds(60)) == "1 min")
    }

    @Test func otherTimesReadInSeconds() {
        #expect(SessionDisplay.presetLabel(.seconds(20)) == "20 s")
        #expect(SessionDisplay.presetLabel(.seconds(90)) == "90 s")
    }

    @Test func zeroReadsNone() {
        #expect(SessionDisplay.presetLabel(.zero) == "None")
    }

    @Test func everyDurationPresetReadsAsWords() {
        let presets = SetupLimits.durationPresets + SetupLimits.capPresets + SetupLimits.windowPresets
            + SetupLimits.workPresets + SetupLimits.restPresets + SetupLimits.longRestPresets
        for preset in presets {
            let label = SessionDisplay.presetLabel(preset)
            #expect(label == "None" || label.hasSuffix(" min") || label.hasSuffix(" s"))
            #expect(!label.contains(":"))
        }
    }

    @Test func intervalsPresetsMatchTheSpec() {
        #expect(SetupLimits.workPresets.map(SessionDisplay.presetLabel) == ["20 s", "30 s", "40 s", "45 s", "1 min", "2 min"])
        #expect(SetupLimits.restPresets.map(SessionDisplay.presetLabel) == ["None", "10 s", "15 s", "20 s", "30 s", "1 min"])
    }
}

@Suite struct MainNumber {
    @Test func intervalsShowTimeLeftInThePhase() {
        var workout = session(intervals)

        #expect(display(&workout, at: 8).mainTime == "0:37")
    }

    @Test func forTimeShowsTimeSoFar() {
        var workout = session(.forTime(cap: nil))

        #expect(display(&workout, at: 270).mainTime == "4:30")
    }

    @Test func setsShowTimeSoFarInASetAndTimeLeftInRest() {
        var workout = session(sets)
        #expect(display(&workout, at: 25).mainTime == "0:25")

        workout.mainAction(at(30))

        #expect(display(&workout, at: 50).mainTime == "1:10")
    }

    @Test func getReadyShowsItsCountdown() {
        var workout = session(intervals, getReady: 10)

        #expect(display(&workout, at: 0.5).mainTime == "0:10")
    }

    @Test func forTimeAddsHundredthsAfterWholeSeconds() {
        var workout = session(.forTime(cap: nil))

        let screen = display(&workout, at: 270.25)

        #expect(screen.mainTime == "4:30")
        #expect(screen.mainFraction == ".25")
    }

    @Test func stopwatchStaysInWholeSeconds() {
        var workout = session(.stopwatch)

        let screen = display(&workout, at: 270.25)

        #expect(screen.mainTime == "4:30")
        #expect(screen.mainFraction == nil)
    }

    @Test func forTimeGetReadyHasNoHundredths() {
        var workout = session(.forTime(cap: nil), getReady: 10)

        #expect(display(&workout, at: 0.5).mainFraction == nil)
    }

    @Test func countdownsAndSetsHaveNoHundredths() {
        var intervalsWork = session(intervals)
        var setsWork = session(sets)

        #expect(display(&intervalsWork, at: 8.25).mainFraction == nil)
        #expect(display(&setsWork, at: 25.25).mainFraction == nil)
    }
}

@Suite struct SecondaryTotal {
    @Test func intervalsShowTotalLeft() {
        // Round 3 work starts at 2:00, so 0:37 is left at 2:08.
        var workout = session(intervals)

        let screen = display(&workout, at: 128)

        #expect(screen.mainTime == "0:37")
        #expect(screen.secondaryTotal == "5:37 left")
    }

    @Test func tabataAndEmomShowTotalLeft() {
        var tabata = session(.tabata(rounds: 8))
        var emom = session(.emom(window: .seconds(60), exercises: 1, rounds: 10, rest: .seconds(60)))

        #expect(display(&tabata, at: 0).secondaryTotal == "3:50 left")
        #expect(display(&emom, at: 90).secondaryTotal == "8:30 left")
    }

    @Test func amrapShowsTotalLeftOnlyWithSeveralBlocks() {
        var single = session(.amrap(block: .seconds(720), blocks: 1, rest: .seconds(60), countsRounds: true))
        var blocks = session(.amrap(block: .seconds(300), blocks: 3, rest: .seconds(60), countsRounds: true))

        #expect(display(&single, at: 0).secondaryTotal == nil)
        #expect(display(&blocks, at: 0).secondaryTotal == "17:00 left")
    }

    @Test func forTimeShowsCapLeftOnlyWithACap() {
        var capped = session(.forTime(cap: .seconds(20 * 60)))
        var uncapped = session(.forTime(cap: nil))

        #expect(display(&capped, at: 270).secondaryTotal == "15:30 left")
        #expect(display(&uncapped, at: 270).secondaryTotal == nil)
    }

    @Test func setsShowTotalElapsed() {
        var workout = session(sets)

        #expect(display(&workout, at: 720).secondaryTotal == "12:00 elapsed")
    }

    @Test func capLeftStaysInWholeSeconds() {
        var workout = session(.forTime(cap: .seconds(20 * 60)))

        #expect(display(&workout, at: 12 * 60 + 10.4).secondaryTotal == "7:50 left")
    }

    @Test func timerAndStopwatchShowNoTotal() {
        var timer = session(.timer(duration: .seconds(300)))
        var stopwatch = session(.stopwatch)

        #expect(display(&timer, at: 10).secondaryTotal == nil)
        #expect(display(&stopwatch, at: 10).secondaryTotal == nil)
    }
}

@Suite struct Position {
    @Test func intervalsShowTheRound() {
        var workout = session(intervals)

        #expect(display(&workout, at: 128).position == "Round 3 of 8")
    }

    @Test func emomShowsTheExerciseWithinTheRound() {
        var workout = session(circuit)

        #expect(display(&workout, at: 570).position == "Round 2 of 3, exercise 4 of 5")
    }

    @Test func emomRestShowsTheNextRound() {
        var workout = session(circuit)

        #expect(display(&workout, at: 690).position == "Round 3 of 3 next")
    }

    @Test func singleExerciseEmomShowsOnlyTheRound() {
        var workout = session(.emom(window: .seconds(60), exercises: 1, rounds: 10, rest: .seconds(60)))

        #expect(display(&workout, at: 210).position == "Round 4 of 10")
    }

    @Test func setsRestShowsTheNextSet() {
        var workout = session(sets)
        workout.mainAction(at(30))
        _ = workout.update(at(150))
        workout.mainAction(at(160))

        #expect(display(&workout, at: 170).position == "Set 3 of 5 next")
    }

    @Test func amrapShowsBlockAndRoundsCounted() {
        var blocks = session(.amrap(block: .seconds(300), blocks: 3, rest: .seconds(60), countsRounds: true))
        var single = session(.amrap(block: .seconds(720), blocks: 1, rest: .seconds(60), countsRounds: true))
        single.tap(at(30))

        #expect(display(&blocks, at: 10).position == "Block 1 of 3 · 0 rounds")
        #expect(display(&single, at: 40).position == "1 round")
    }

    @Test func amrapWithoutCountingShowsOnlyTheBlock() {
        var single = session(.amrap(block: .seconds(720), blocks: 1, rest: .seconds(60), countsRounds: false))

        #expect(display(&single, at: 10).position == nil)
    }

    @Test func forTimeShowsTheRoundNumber() {
        var workout = session(.forTime(cap: nil))
        workout.tap(at(130))

        #expect(display(&workout, at: 140).position == "Round 2")
    }

    @Test func timerAndStopwatchShowNoPosition() {
        var timer = session(.timer(duration: .seconds(300)))
        var stopwatch = session(.stopwatch)

        #expect(display(&timer, at: 10).position == nil)
        #expect(display(&stopwatch, at: 10).position == nil)
    }
}

@Suite struct NextPhase {
    @Test func workIsFollowedByRest() {
        var workout = session(intervals)

        #expect(display(&workout, at: 10).nextPhase == "Next: Rest 0:15")
    }

    @Test func restIsFollowedByWork() {
        var workout = session(intervals)

        #expect(display(&workout, at: 50).nextPhase == "Next: Work 0:45")
    }

    @Test func getReadyIsFollowedByTheFirstPhase() {
        var workout = session(intervals, getReady: 10)

        #expect(display(&workout, at: 1).nextPhase == "Next: Work 0:45")
    }

    @Test func emomNamesTheNextExercise() {
        var workout = session(circuit)

        #expect(display(&workout, at: 570).nextPhase == "Next: Exercise 5 · 1:00")
    }

    @Test func emomRoundEndsWithRest() {
        var workout = session(circuit)

        #expect(display(&workout, at: 630).nextPhase == "Next: Rest 1:00")
    }

    @Test func theFinalEmomExerciseSaysSo() {
        var workout = session(circuit)

        #expect(display(&workout, at: 990).nextPhase == "Final exercise")
    }

    @Test func theFinalWorkPhaseSaysSo() {
        var workout = session(intervals)

        #expect(display(&workout, at: 430).nextPhase == "Final round")
    }

    @Test func theFinalSetSaysSo() {
        var workout = session(.sets(rest: .seconds(90), sets: 1))

        #expect(display(&workout, at: 10).nextPhase == "Final set")
    }
}

@Suite struct StateAndProgress {
    @Test func stateFollowsThePhase() {
        var workout = session(.intervals(work: .seconds(45), rest: .seconds(15), rounds: 2), getReady: 10)

        #expect(display(&workout, at: 1).state == .getReady)
        #expect(display(&workout, at: 11).state == .work)
        #expect(display(&workout, at: 56).state == .rest)
    }

    @Test func finalSecondsAtThreeSecondsOrLess() {
        var workout = session(intervals)

        #expect(display(&workout, at: 41.9).state == .work)
        #expect(display(&workout, at: 42).state == .finalSeconds)
        #expect(display(&workout, at: 44.9).state == .finalSeconds)
    }

    @Test func getReadyHasFinalSecondsToo() {
        var workout = session(intervals, getReady: 10)

        #expect(display(&workout, at: 8).state == .finalSeconds)
    }

    @Test func countUpPhasesHaveNoFinalSeconds() {
        var workout = session(.stopwatch)

        #expect(display(&workout, at: 1).state == .work)
    }

    @Test func pausedOverridesThePhaseAndSaysSo() {
        var workout = session(intervals)
        workout.pause(at(43))

        let screen = display(&workout, at: 50)

        #expect(screen.state == .paused)
        #expect(screen.label == "PAUSED")
    }

    @Test func theLabelNamesThePhaseDuringFinalSeconds() {
        var workout = session(intervals)

        #expect(display(&workout, at: 43).label == "WORK")
    }

    @Test func halfwayThroughAPhaseIsHalfDrained() {
        var workout = session(.timer(duration: .seconds(300)), getReady: 10)

        #expect(display(&workout, at: 5).phaseProgress == 0.5)
        #expect(display(&workout, at: 160).phaseProgress == 0.5)
    }

    @Test func halfwayThroughAWorkoutFillsHalfTheBar() {
        var workout = session(.emom(window: .seconds(60), exercises: 1, rounds: 10, rest: .seconds(60)))

        #expect(display(&workout, at: 300).workoutProgress == 0.5)
    }

    @Test func getReadyLeavesTheWorkoutBarEmpty() {
        var workout = session(.emom(window: .seconds(60), exercises: 1, rounds: 10, rest: .seconds(60)), getReady: 10)

        #expect(display(&workout, at: 5).workoutProgress == 0)
    }

    @Test func stopwatchHasNoBarOrDrain() {
        var workout = session(.stopwatch)

        let screen = display(&workout, at: 30)

        #expect(screen.workoutProgress == nil)
        #expect(screen.phaseProgress == nil)
    }
}
