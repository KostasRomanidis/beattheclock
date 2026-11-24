# Proposal

## Why

Each workout type's rules are scattered over five exhaustive switches and four `if`/`guard case` checks in the engine, and `Session` mixes five jobs. Clear domain types would put each rule in one place and make illegal states impossible, without changing what the specs require.

## What Changes

- Each workout type becomes a public struct with its own settings that makes a `WorkoutPlan`. `WorkoutConfiguration` stays a closed enum, now wrapping those structs.
- `Segment` becomes `Phase`, which carries its main action, whether Finish is allowed, and its round, block, set or exercise place.
- `Session` runs a plan and no longer knows workout types. Its timekeeping moves to `SessionClock` and its cue queue to `CueQueue`.
- Time formatting moves from `SessionDisplay` to `TimeFormat`.
- Setup binds directly to each struct's settings instead of rebuilding an enum case.
- **BREAKING** (package API only): `.timer` becomes `.countdown`, and the enum payloads, `Segment`, `timeline()`, the `Session` initializer and the formatting functions change. The app is the only known caller.

No requirement changes. Review found four places where the app fell short of its specs or was fragile, and this change fixes them: input just after a phase boundary acted on the old phase, End Workout could play a waiting sound, a zero-length workout had no valid progress, and two quick setup changes could lose one. Workout names and read-back sentences stay in the app.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None. This is a pure refactor, so `.openspec.yaml` sets `skip_specs: true`.

## Impact

- `Packages/WorkoutEngine`: all sources, plus test call sites. Expected test values do not change.
- `beattheclock/`: `SetupView`, `SessionView`, `ContentView` and `SessionController`.
- No new dependencies and no stored data.
