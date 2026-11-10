# Tasks

## 1. Setup presets and read-back (already built, uncommitted)

- [x] 1.1 Add one-tap preset lists to `SetupLimits`, with tests that every preset is within limits and every default is a preset. Verified: `swift test` passes (101 tests).
- [x] 1.2 Add preset rows under each stepper and the read-back sentence footer in `SetupView.swift`. Verified: Mac and iPad simulator builds succeed.

## 2. EMOM model and timeline

- [x] 2.1 Change `WorkoutConfiguration.emom` to `emom(window:exercises:rounds:rest:)`, set the default to `emom(window: 1:00, exercises: 1, rounds: 10, rest: 1:00)`, and update the pattern matches in `Session.swift`, `SessionDisplay.swift` and `Timeline.swift`. Verify the package builds.
- [x] 2.2 Add a private EMOM builder in `Timeline.swift`: rounds of `exercises` back-to-back windows, rest between rounds only when exercises > 1 and rest > 0, never after the last round. Verify with new `TimelineTests`: 3×5 with 1:00 rest is 17 segments and a 17:00 total, 3×5 with no rest is 15 windows, 1 exercise with a stored 1:00 rest is 10 back-to-back windows.
- [x] 2.3 Update the existing tests that build EMOM (`TimelineTests`, `SessionTests`, `SessionDisplayTests`, `WorkoutConfigurationTests`, `SetupLimitsTests`) to the new case. Verify `swift test` passes with the 1-exercise results unchanged.

## 3. Live view text

- [x] 3.1 In `SessionDisplay.position`, show "Round r of R, exercise e of E" during work for EMOM with more than 1 exercise, and "Round r of R next" during rest and get-ready. Verify with new `SessionDisplayTests` matching the session-display spec scenarios, including 1 exercise still showing "Round 4 of 10".
- [x] 3.2 In `SessionDisplay.nextPhase`, name a following EMOM window "Exercise e 1:00" and the final window "Last exercise" when there's more than 1 exercise. Verify with new `SessionDisplayTests` for the next-exercise, before-rest ("Rest 1:00") and last-exercise cases.
- [x] 3.3 Add a `SessionTests` case: entering the next exercise window reports the work-start cue, and entering the between-rounds rest reports the rest-start cue. Verify `swift test` passes.

## 4. Setup for EMOM

- [x] 4.1 Add `SetupLimits.exercisePresets = [1, 2, 3, 4, 5, 6]` and change `roundPresets` to `[3, 5, 8, 10, 12, 20]`. Extend the preset tests to cover the exercises default. Verify `swift test` passes.
- [x] 4.2 In `SetupView.settings`, show the EMOM rows Every, Exercises, Rounds, then Rest (only when exercises > 1, using `longRestPresets`), each rebuilding the full `emom` case. Verify the Mac and iPad simulator builds succeed.
- [x] 4.3 Extend `WorkoutConfiguration.summary` for EMOM: the single-exercise sentence stays the same, plus the multi-exercise sentences for "with 1:00 rest between rounds", "with no rest" and 1 round. Verify by hand in setup that the spec's read-back scenarios match word for word.

## 5. Integration check

- [x] 5.1 Run EMOM 3 rounds × 5 exercises × 0:10 with 0:05 rest, on Mac and an iPad simulator. Verify the position line, the next-phase line, a work-start tone for each new exercise, the rest colour and tone between rounds, and the 0:40 total ending. Also check that the position text fits at the narrowest iPad Split View width.

## Workflow follow-up

- Archive the change with `/opsx:archive` after review, which syncs the three spec deltas into `openspec/specs/`.
