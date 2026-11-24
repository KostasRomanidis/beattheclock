# Design

## Context

See proposal.md for motivation. The engine is a UI-free Swift package driven by supplied time, and these properties stay. The existing specs define behaviour. The baseline is 130 passing engine tests.

```
 SETUP                                 RUN
 +------------------------+            +---------------------------+
 | WorkoutConfiguration   |            | Session   aggregate root  |
 |  enum of 8 structs,    |            |  + plan: WorkoutPlan      |
 |  each with plan()      |            |  + clock: SessionClock    |
 +-----------+------------+            |  + cues: CueQueue         |
             | makes                   |  + rounds, splits         |
             v                         +------+-------------+------+
 +------------------------+   runs            | cues        | read by
 | WorkoutPlan            |<------------------+             v
 |  phases, total, traits |                   |     +----------------+
 +-----------+------------+                   v     | SessionDisplay |
             | 1..*                      CuePlayer  +-------+--------+
             v                                              | uses
 +------------------------+                                 v
 | Phase                  |                           TimeFormat
 |  kind, ending, action, |
 |  canFinish, place      |
 +------------------------+
```

## Goals / Non-Goals

**Goals:**

- One place per workout type for its rules.
- No workout-type checks in `Session` or `SessionDisplay`.
- Status and its instants cannot disagree.

**Non-Goals:**

- Custom or chained workouts, and persistence.
- State classes, factories, observers, repositories, or protocols for the player. Swift enums and `@Observable` cover what is needed.
- Moving names or read-back sentences into the engine.

## Decisions

### 1. A closed enum over one struct per type

Each struct (`Countdown`, `Amrap`, `Emom`, `Tabata`, `Intervals`, `ForTime`, `Stopwatch`, `Sets`) has a public initializer with its defaults and makes its own `WorkoutPlan`. `WorkoutConfiguration.plan()` forwards through one switch, and `defaults` keeps its order.

The type set rarely grows, so the enum keeps compile errors in every switch. A `Workout` protocol was tried and removed in review: the enum already dispatches, and nothing else used it. The archived design (2026-11-10, decision 3) rejected a class per type; these are value types with no inheritance, and this supersedes that decision.

### 2. Phases carry their own answers

`Phase` holds `kind`, `ending`, `mainAction`, `canFinish` and an optional `place` (unit, number, count, optional exercise number and count). Rest phases carry the upcoming place, and get-ready carries the first phase's place. `exercise` is nil for a single-exercise EMOM. `place` is nil for single-block AMRAP, Countdown, For Time and Stopwatch.

This replaces `workBefore`, `workCount` and the EMOM arithmetic. Putting these answers on each workout type was rejected, because they depend on the phase and not only the type.

### 3. WorkoutPlan derives what is true of the whole workout

`phases` is never empty: `alternating` and `Emom` clamp counts, and the initializer has a precondition. `total`, `secondaryTotal` and `record` (rounds or splits) are derived from all the phases, so they cannot contradict them. `record` is not read from the current phase, because undo appears during AMRAP rest and For Time shows "Round 1" during get-ready. `showsHundredths` is set by For Time.

`starting(with:)` adds get-ready, which `total` excludes, so `Session` holds one plan. `SessionController` keeps the name and the plan without get-ready, for the summary and repeating.

### 4. SessionClock and CueQueue use session time

`SessionClock` turns instants into session time, a `Duration` excluding pauses, with a state of `running`, `paused(at:)` or `ended(at:)`. `Session` and `CueQueue` store only session time, so resuming changes the clock alone. Moving stored instants on resume was rejected, because each new one could be forgotten.

`CueQueue` gets a phase's ticks when the phase begins, reports cues once due, drops late ones and cancels what is left when a phase ends early. It belongs in the engine because these are session-cues rules that need no audio. The final seconds are defined once, on `Phase`.

Each control advances to `now` before acting, so it applies to the phase at that moment.

### 5. Setup binds to structs

Each case in `SetupView` makes one binding to its struct, then uses `emom.rounds` style bindings. It reads the current configuration, not the rendered copy, so quick changes are not lost.

## Risks / Trade-offs

- [A tap meant to skip get-ready lands just after it ends] → It acts on the first phase, such as pausing it. Accepted, because the phase has truly changed.
- [Pauses shift cues off the clock] → All stored times are session time; keep the final-seconds pause tests.
- [End Workout from pause must not play the finish sound, as today] → `ended(at:)` takes the pause time and waiting cues are cancelled; tested.
- [Display text changes subtly] → Keep all expected strings in `SessionDisplayTests` unchanged.
- [Setup is not covered by engine tests] → Build both platforms and check every setup screen by hand.
