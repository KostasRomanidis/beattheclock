# Design

## Context

- `WorkoutConfiguration.emom(window:rounds:)` produces a flat timeline through the shared `intervals(work:rest:rounds:)` helper, with rest set to zero (`Timeline.swift`).
- `Session` runs any flat list of segments. It already plays the work-start cue whenever a work segment begins (`Session.swift`), so exercise changes get the right tone for free.
- `SessionDisplay.position` and `nextPhase` work out "Round n of N" and "Work 1:00" by counting work segments. Nothing in a segment says which exercise it is.
- Setup builds EMOM's rows in `SetupView.settings`, and the read-back sentence comes from `WorkoutConfiguration.summary` in `SetupView.swift`. The preset lists are in `SetupLimits`.

## Goals / Non-Goals

**Goals:**
- Model rounds of exercises without changing `Segment` or `Session`.
- Keep EMOM with 1 exercise identical to today: the same segments, total and display text.

**Non-Goals:**
- No per-segment metadata, such as exercise index or names, on `Segment`.
- No changes to cues, colours or the live view layout.

## Decisions

**1. Extend the `emom` case: `emom(window:, exercises:, rounds:, rest:)`.**
Every switch over the enum already handles EMOM, so the compiler finds every site to update. *Alternative:* a new `circuit` workout type. Rejected because it would duplicate EMOM, and 1 exercise is today's EMOM exactly.

**2. The timeline ignores rest when `exercises == 1`.**
The default stores rest 1:00, so switching from 5 exercises back to 1 keeps the user's rest value for later. A stored rest must never turn a 1-exercise EMOM into intervals. Otherwise a round holds `exercises` work segments back to back, with a rest segment between rounds only when rest is more than zero. This goes in a new private `emom` builder in `Timeline.swift`, not in `alternating`. *Alternative:* reset rest to zero when exercises drops to 1. Rejected because it loses the user's value, and setup would have to reach into engine rules.

**3. Work out exercise position from the configuration, not the segments.**
In `SessionDisplay`, for EMOM with more than 1 exercise, take `workSoFar` (the work segments before the current one) and split it into a round (`workSoFar / exercises`) and an exercise (`workSoFar % exercises`).
- During work: "Round 2 of 3, exercise 4 of 5".
- During rest and get-ready, the existing "next" form names the next round: "Round 3 of 3 next".
- `nextPhase` names a following work segment "Exercise 5 1:00". The final window reads "Last exercise" instead of "Last round".
*Alternative:* tag each segment with its exercise index. Rejected because it changes `Segment` equality and every timeline, all to serve one workout type.

**4. Presets.**
- Add `SetupLimits.exercisePresets = [1, 2, 3, 4, 5, 6]`.
- EMOM rest reuses `longRestPresets`.
- `roundPresets` becomes `[3, 5, 8, 10, 12, 20]`. That still holds the Tabata and Intervals default (8) and the EMOM default (10), so the existing preset tests keep passing.

**5. Setup rows and read-back.**
- Row order is Every, Exercises, Rounds, then Rest. Rest shows only when exercises is more than 1, which mirrors AMRAP's Blocks/Rest pattern.
- `summary` gains the multi-exercise sentences from the spec. Edge cases: 1 round leaves out the rest clause, and rest 0:00 reads "with no rest".

## Risks / Trade-offs

- [The `emom` case signature changes, so every pattern match and test that builds EMOM breaks] → The compiler lists each site. The tests get mechanical updates plus new cases for 3×5 with rest, 3×5 without rest, and 1 exercise with a non-zero stored rest.
- [The read-back sentence lives in the app target, which has no test target, so it isn't covered by tests] → Check it by hand. If more of its logic grows, move `summary` into `WorkoutEngine`.
- [Long position text ("Round 2 of 3, exercise 4 of 5") on a narrow iPad Split View] → The footer already uses `.title` text in an `HStack` that can wrap. Check it at the narrowest width.
