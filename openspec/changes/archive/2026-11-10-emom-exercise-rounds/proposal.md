# Proposal

## Why

EMOM runs a single exercise per window, so a common circuit can't be set up: for example, 3 rounds of 5 exercises at 1:00 each, with rest between rounds. The setup screen also gained one-tap presets and a read-back sentence in the last pass, and those aren't in the specs yet.

## What Changes

- EMOM gains two settings:
  - **Exercises**: how many windows make one round. Default 1.
  - **Rest**: the rest between rounds. Default 1:00. It's offered and applied only when Exercises is more than 1.
- With 1 exercise, EMOM behaves exactly as today: the same defaults, phases, total and display.
- With 2 or more exercises, EMOM runs each round's windows back to back, rests between rounds, and never rests after the last round.
- The live view shows the exercise within the round: "Round 2 of 3, exercise 4 of 5". The next-phase line names the next exercise, and the final window reads "Last exercise".
- Moving to the next exercise plays the existing work-start tone. No new tone is added.
- Setup offers one-tap presets for EMOM's Exercises and Rest. Round presets change from 4, 5, 8, 10, 12, 20 to 3, 5, 8, 10, 12, 20, so 3 rounds is one tap.
- The specs now record the setup behaviour already built: one-tap presets under each setting, and a read-back sentence that includes the calculated total.
- Not included: exercise names, a different length for each exercise, and saved workout presets.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `workout-setup`: EMOM settings and defaults; exercises must be at least 1; one-tap presets; a read-back sentence describing the configured workout.
- `workout-session`: EMOM phase order with exercises per round and rest between rounds.
- `session-display`: workout position shows the exercise within the round; the next-phase line and the final-phase indication cover EMOM exercises.

## Impact

- `Packages/WorkoutEngine`:
  - `WorkoutConfiguration` (**BREAKING** within the package: the `emom` case gains `exercises` and `rest`);
  - `Timeline` (EMOM segments);
  - `SessionDisplay` (position and next-phase text);
  - `SetupLimits` (exercise presets, round presets);
  - `Session` (pattern matches only);
  - the tests that build EMOM sessions.
- `beattheclock/SetupView.swift`: EMOM rows and the EMOM read-back sentence.
- No new dependencies. No stored data, so there's nothing to migrate.
