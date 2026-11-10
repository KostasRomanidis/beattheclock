# Tasks

## 1. Project scaffolding

- [x] 1.1 Create the `Packages/WorkoutEngine` Swift package in Swift 6 language mode with a Swift Testing target, and verify `swift test` runs from the package folder
- [x] 1.2 Link the package to the existing `beattheclock` target and add its folder to the project's file list, and verify `xcodebuild` builds for macOS and an iPad simulator and the app imports the package

## 2. Engine: configurations and timelines

- [x] 2.1 Add `WorkoutConfiguration` with one case per workout type and the spec's defaults, and verify with tests for all eight defaults
- [x] 2.2 Add `Segment` and the four timeline builders (countdown, intervals, count up, sets), and verify with tests for 8 x 0:45/0:15, 3 AMRAP blocks, EMOM, zero rest and no trailing rest
- [x] 2.3 Add the calculated total, and verify tests give 7:45 for the Intervals example, 17:00 for the AMRAP example, and no total for For Time, Stopwatch and Sets

## 3. Engine: session behaviour

- [x] 3.1 Add `Session` start, get-ready and time-driven phase advance using supplied time, and verify tests cover ordering, get-ready skip, get-ready off, several boundaries in one update, and a simulated 40-minute run ending exactly on time
- [x] 3.2 Add pause, resume and end workout, and verify tests confirm phase and total times are unchanged by a pause, and that tap and space skip the get-ready instead of pausing it
- [x] 3.3 Add main actions for AMRAP round counting with undo, For Time splits, and Sets set-done, plus Finish and the For Time cap, and verify tests cover the spec's scenarios, including split times of 2:10 and 2:20 and the last set ending the workout
- [x] 3.4 Add cue events from `update`, and verify tests cover exact-once ticks at 3, 2 and 1, phase sounds, finish, ticks across a pause, skipped get-ready ticks, and dropping events after a stall of over one second

## 4. Engine: display content

- [x] 4.1 Add `SessionDisplay` with time formatting and countdown rounding, and verify tests cover 0:45, 1:02:05 and 0.4 seconds left showing 0:01
- [x] 4.2 Add main number, secondary total, position and next-phase rules for all workout types, and verify tests cover the spec's table, including 5:37 left at round 3 with 0:37 remaining
- [x] 4.3 Add state and progress values, including final seconds at 3 seconds or less, and verify tests cover state changes, halfway phase and workout progress, and no bar for Stopwatch

## 5. App: setup

- [x] 5.1 Add the workout grid, with navigation to setup, and verify by running that all eight types appear on Mac and iPad
- [x] 5.2 Add setup forms for each type, with limits, the calculated total and the shared get-ready presets, and verify by running that the example shows 7:45, limits hold, and values reset after a relaunch

## 6. App: live session

- [x] 6.1 Add `SessionController` with the 100 ms tick, and verify by running that a short Intervals workout advances correctly and the timing is right against a separate clock
- [x] 6.2 Add the live view with scaling digits, phase colours, drain, progress bar and the secondary information, and verify by resizing the Mac window and rotating an iPad that digits never clip
- [x] 6.3 Add tap, hold and keyboard handling from the design's control table, and verify each control on Mac and iPad, including that a hold never counts a round
- [x] 6.4 Add the paused state and summary screen with repeat and back to setup, and verify by ending a workout early and repeating one, checking the correct results are shown and that nothing persists after a relaunch
- [x] 6.5 Check colour contrast at 4.5:1 or better for all states, add accessibility labels to all controls, and verify using Xcode's Accessibility Inspector and VoiceOver on the undo control

## 7. App: system integration

- [ ] 7.1 Add `CuePlayer` with generated tones and iPad audio session setup, and verify by running that each cue sounds distinct, that music keeps playing, and that cues play with the iPad's silent setting on
- [ ] 7.2 Add `DisplayWake` for both platforms, and verify the screen stays on beyond its sleep time, including while paused, and sleeps normally after the workout ends
- [ ] 7.3 Add iPad auto-pause on leaving the foreground, and verify the workout is paused on return; on Mac, verify phases and cues stay on time with the window covered for several minutes

## 8. End-to-end check

- [ ] 8.1 Run each of the eight workout types once on Mac and iPad with short settings, and verify each behaves as its specs describe
- [ ] 8.2 Do a real workout using the 8 x 0:45/0:15 Intervals setup, verify it is readable and audible from across the room, and tune colours and tones in place if needed
- [ ] 8.3 Add a short `README.md` covering how to build, run and test, and verify the documented commands run as written

## Workflow follow-up

- Archive the change after the end-to-end check passes.
