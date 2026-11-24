# Proposal

## Why

Several setup and live-screen labels use generic or technical wording where athletes use gym language: the get-ready row has no visible label, "Timer" reads as a vague tile next to Stopwatch, a rest of "0:00" reads as a number instead of "None", and preset chips show clock times like `12:00` where people say "12 min". Separately, For Time records a round at each tap, but times are shown to whole seconds, which can't separate two close results.

## What Changes

- **Get ready label**: the get-ready choice in setup shows a visible "Get ready" label. Today the segmented picker hides it.
- **Countdown**: the workout type "Timer" is renamed "Countdown". Behaviour and defaults are unchanged. "Sets" keeps its name.
- **Words for zero and absent values**: a rest of 0:00 reads "None" on its stepper and its preset chip. For Time with its cap off reads "No cap".
- **Preset chip format**: chips read `12 min`, `90 s` and `20 s` instead of `12:00`, `1:30` and `0:20`. Steppers and the live screen keep clock format.
- **Wording**:
  - The For Time cap stepper is titled "Time cap", matching its switch.
  - "Last round" and "Last exercise" read "Final round" and "Final exercise".
  - The next-phase line reads `Next: Exercise 2 · 1:00` and `Next: Rest 0:20`.
- **Hundredths for For Time**: while For Time counts up, the main number shows hundredths, such as `4:30.25`. The summary's total time and every split show hundredths too. Stopwatch, Sets, every countdown phase, the cap-left total and the get-ready countdown stay in whole seconds.
- Not included: hundredths for Stopwatch or Sets, a setting to turn hundredths off, milliseconds (a third digit), a new final-seconds tick setting, and saved results.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `workout-setup`: workout type name (Countdown), visible Get ready label, "None" and "No cap" wording, preset chip format.
- `session-display`: time format with hundredths for For Time, "Next:" and "Final" wording, Countdown name in the secondary-total rules, VoiceOver reading whole seconds.
- `workout-session`: the Countdown name in the phase-order rule, and For Time splits and the summary recorded and shown to hundredths.

## Impact

- `Packages/WorkoutEngine`:
  - `SessionDisplay` (hundredths format, a separate fraction for the main number, "Next:" and "Final" text, a short chip format);
  - the tests for `SessionDisplay`, with new cases for hundredths, truncation and chip labels.
- `beattheclock/ContentView.swift`: the "Countdown" tile name.
- `beattheclock/SetupView.swift`: the Get ready label, "None" and "No cap", chip labels, "Time cap".
- `beattheclock/SessionView.swift`: the main number with a smaller fraction, whole-second VoiceOver label, summary and split times.
- `beattheclock/SessionController.swift`: a roughly 16 ms tick while For Time is counting up and running. Everything else keeps the 100 ms tick.
- No change to cues, colours or the engine's timing rules. No new dependencies, no stored data, nothing to migrate. The `timer` case keeps its internal name.
