# Tasks

Each group ends with all engine tests passing. Existing expected test values must not change, only types and call sites.

## 1. Time format

- [x] 1.1 Move `format`, `fraction` and `presetLabel` from `SessionDisplay` to `TimeFormat`, updating tests and app callers; verify with `swift test` and the Mac `xcodebuild` command from README.md

## 2. Phases and plan

- [x] 2.1 Rename `Segment` to `Phase`, including `Session` members named after it, and update tests; verify with `swift test`
- [x] 2.2 Add `WorkoutPlan` and build it from the existing enum, with each phase's main action, finish flag and place; verify with new tests for places in EMOM, rest and single-block AMRAP
- [x] 2.3 Make `Session` run a plan, prepending get-ready with the first place, and `SessionController` keep the configuration; verify with `swift test` and the Mac build
- [x] 2.4 Make `SessionDisplay` read only the plan and phases, deleting the old type checks; verify `SessionDisplayTests` expected strings are unchanged and no workout-type case remains in `Session.swift` or `SessionDisplay.swift`

## 3. Session clock

- [x] 3.1 Extract `SessionClock` with running, paused and ended states, keeping `status` computed; verify with `swift test`, including End Workout from pause keeping its time and playing no finish cue

## 4. Cue schedule

- [x] 4.1 Extract the cue queue and shift it with the clock in one resume step; verify the cue tests pass unchanged, including pausing in the final seconds and the one-second cutoff

## 5. Workout types

- [x] 5.1 Add eight structs with default settings, each making its plan and tested on its defaults; verify with `swift test`
- [x] 5.2 Make `WorkoutConfiguration` wrap the structs, renaming `.timer` to `.countdown`, and update engine tests and the app's `name`, `summary` and setup to compile; verify with `swift test` and the Mac build

## 6. Setup

- [x] 6.1 Bind setup controls directly to each struct, keeping the For Time cap restore; verify with the Mac build and by changing every setting in all eight setup screens
- [x] 6.2 Update the README's engine description if the layout it describes changed; verify it matches the sources

## 7. Integration

- [x] 7.1 Run `swift test` and both README `xcodebuild` commands; verify all pass
- [x] 7.2 Run all eight workouts in the app, pausing and resuming in the final 3 seconds of a countdown phase; verify sounds, display and summary match the specs

## 8. Review fixes

- [x] 8.1 Advance before each control, cancel cues on End Workout and guard zero-length progress; verify with the `LateInput`, `EndingWithCuesWaiting` and zero-length tests
- [x] 8.2 Use session time in `SessionClock`, `CueQueue` and `Session`, with one final-seconds rule; verify with direct clock and queue tests
- [x] 8.3 Add public initializers, remove the `Workout` protocol, derive plan traits and enforce non-empty plans; verify with `swift test`
- [x] 8.4 Make setup bindings read current settings; verify with the Mac and iPad simulator builds
- [ ] 8.5 Recheck the app; verify by hand that settings change on every setup screen, the For Time cap restores when switched off and on, and sounds are right when pausing and resuming in the final 3 seconds
