# Tasks

## 1. Time format and chip labels (engine)

- [x] 1.1 Add `hundredths: Bool = false` to `SessionDisplay.format`, cutting the fraction off rather than rounding. Verify new `SessionDisplayTests`: 2:10.679 reads `2:10.67`, exactly 4:00 reads `4:00.00`, 0:59.996 reads `0:59.99`, 1:02:05.5 reads `1:02:05.50`, and the default call still reads `0:45`.
- [x] 1.2 Add `SessionDisplay.presetLabel(_:)`: "12 min" for whole minutes, "None" for zero, otherwise seconds ("20 s", "90 s"). Verify new tests cover every value in `SetupLimits`' duration, cap, window, work, rest and long-rest presets.
- [x] 1.3 Verify with the `SetupLimitsTests` that no preset list changed, so every default is still a preset. Run `swift test` and confirm it passes.

## 2. Live display text (engine)

- [x] 2.1 Add `mainFraction: String?` to `SessionDisplay`, set only while For Time counts up (for example `".25"`), with `mainTime` staying whole seconds. Verify new tests: For Time at 4:30.250 gives `4:30` and `.25`, Stopwatch at the same time gives `4:30` and nil, and a For Time get-ready countdown gives nil.
- [x] 2.2 Make the For Time cap-left total stay in whole seconds. Verify a test: a 20:00 cap with 12:10.40 passed shows `7:50 left`.
- [x] 2.3 Change `nextPhase` to read "Next: Rest 0:15" and "Next: Exercise 5 · 1:00", and the last-phase text to "Final round" and "Final exercise". Update the existing `SessionDisplayTests` expectations to match the session-display spec scenarios and verify `swift test` passes.
- [x] 2.4 Add a For Time `SessionTests` case: taps at 2:10.25 and 4:30.50 give splits of 2:10.25 and 2:20.25 when formatted with hundredths, and a tap at 1:00.999 reads `1:00.99`. Verify `swift test` passes.

## 3. Names and setup labels (app)

- [x] 3.1 In `ContentView.swift`, change the `.timer` name to "Countdown" and update the Countdown test or preview names that read "Timer". Verify with `grep -rn '"Timer"'` returning nothing and the Mac build succeeding.
- [x] 3.2 In `SetupView`, show the get-ready picker in a `LabeledContent("Get ready")` with the picker's own title hidden. Verify in the Mac and iPad simulators that "Get ready" is visible, and with VoiceOver that it reads "Get ready".
- [x] 3.3 Use `presetLabel` for the chips in `PresetRow`, and give `DurationStepper` a `zeroLabel` of "None" for rest values and the zero chip. Verify in setup that Intervals rest presets read None, 10 s, 15 s, 20 s, 30 s, 1 min, and that stepping rest to zero reads "None".
- [x] 3.4 In For Time setup, title the switch "Time cap" with a "No cap" secondary line when off, and title the stepper "Time cap". Verify by hand that both states read as the workout-setup spec says.

## 4. Live view and controller (app)

- [x] 4.1 In `SessionView`, draw `mainTime` with a smaller `mainFraction` in one `Text`, keep the VoiceOver label to `mainTime` only, and format the summary total and splits with hundredths for For Time. Verify in the simulator that the number scales without clipping in a narrow window, and that VoiceOver doesn't re-announce the hundredths.
- [x] 4.2 In `SessionController`, tick about every 16 ms only while the session is running and `mainFraction` is non-nil, and every 100 ms otherwise. Verify that the For Time hundredths run smoothly, other workouts still tick at 100 ms, and a paused For Time stops fast ticking.
- [x] 4.3 Update the cue timing check: run a For Time workout with 10-second get-ready and confirm the 3-2-1 ticks and the finish sound play once each and on time. Verify with `swift test` and by ear on a device.

## 5. Integration check

- [x] 5.1 Run For Time with a 2:00 cap on Mac and an iPad simulator. Verify the live hundredths, a split at each tap, the whole-second cap-left total, the summary total and splits with hundredths, and that Stopwatch and Sets still show whole seconds.
- [x] 5.2 On an iPad, run For Time for 5 minutes and compare battery and heat to a Stopwatch run. Verify that it is acceptable, otherwise isolate the number in its own view as noted in design.md.

## Workflow follow-up

- Archive the change with `/opsx:archive` after review, which syncs the three spec deltas into `openspec/specs/`.
