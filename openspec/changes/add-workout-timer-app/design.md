# Design

## Context

The project contains the Xcode template app (`beattheclock.xcodeproj`, bundle ID `com.kroman.beattheclock`), set up for Mac and iPad, so there are no existing patterns to follow beyond its naming. Xcode 27.2 and Swift 6.4 are installed. The app target defaults to `MainActor` isolation. The specs define behaviour, and this document covers how to build it. The user asked for clean code principles, which shape the decisions below.

## Goals / Non-Goals

**Goals:**

- Keep all timing and workout rules in a pure, UI-free engine that tests can drive without waiting for real time.
- Make adding a future workout type mean adding one configuration case and its timeline, without changing the session logic.
- Share one codebase and one target across Mac and iPad, with platform differences isolated in small places.

**Non-Goals:**

- Abstractions for persistence, Android or chained workouts. None are needed yet, and the timeline model does not block them later.
- A Mac Catalyst build, or separate Mac and iPad targets.
- Haptics, music ducking and user-selectable sounds or colours.

## Decisions

### 1. Native SwiftUI in one multiplatform target

One target supports macOS and iPadOS, with iPad-only device family and no Catalyst.

- **Alternatives:** Flutter and Compose Multiplatform were rejected because Android is deferred. Catalyst gives a less native Mac app. Separate targets duplicate configuration.
- **Minimum versions:** macOS 14 and iPadOS 17, the first with `@Observable` and `onKeyPress`. Nothing here needs newer APIs, and this avoids excluding an older iPad.

### 2. Engine in a local Swift package

```
beattheclock/                  SwiftUI app source (thin), in beattheclock.xcodeproj
  App, Setup, Session views
  SessionController, CuePlayer, DisplayWake
Packages/WorkoutEngine/        pure Swift, no SwiftUI or AVFoundation
  WorkoutConfiguration, Timeline, Session, SessionDisplay
```

A package boundary means the compiler rejects UI imports in the engine, and `swift test` runs in seconds with no simulator. A folder inside the app target was rejected because the separation would rely on discipline alone.

### 3. Every workout compiles to a flat list of segments

```
WorkoutConfiguration --timeline()--> [Segment] --> Session
(enum, one case per type)            kind: work | rest | getReady
                                     ending: afterDuration | byUser(cap?)
```

The direction follows from the ending: timed segments count down and user-ended segments count up. The eight types share four builders (countdown, intervals, count up, sets), and Tabata and EMOM are parameter choices within intervals. The session has no knowledge of workout types beyond small flags on the configuration, such as whether a phase has a main action. A class per workout type was rejected as more code for the same behaviour.

### 4. The session is a value type driven by supplied time

`Session` is a struct with no clock or timer of its own. Every operation takes `now`:

```
update(now) -> [CueEvent]   start(now)   pause(now)   resume(now)
mainAction(now)             undoRound()  finish(now)  skipGetReady(now)
```

It stores the current segment index, the segment's start and the time paused. Elapsed time is always `now - start - paused`, so ticks cannot cause drift and tests can jump to any moment. When a segment ends, the next one starts at the exact moment the last one should have ended, and a loop handles several boundaries passed in one update. `update` returns the cue events crossed since the previous update, which gives exactly-once behaviour and drops events more than one second old.

A timer that decrements a counter was rejected because it drifts and is hard to test.

### 5. Display content is computed in the engine

`SessionDisplay` is a pure mapping from session state to what the screen shows: main time, secondary total, position text, next phase, state and progress. The rules in the session-display spec, including rounding up countdowns, live here as tested code, and views only render them. Scattering these rules across views was rejected, because they would need UI tests to verify.

### 6. A thin controller connects the engine to the system

`SessionController` is a `@MainActor @Observable` class that owns the `Session`. It runs one task that wakes every 100 ms, reads `ContinuousClock.now`, calls `update`, publishes `SessionDisplay` and passes cue events to `CuePlayer`. It holds no workout rules. A 100 ms tick meets the cue timing requirement. `TimelineView` was rejected as the driver because cues must fire independently of rendering. Protocols for the player and wake lock were rejected because the controller is thin enough to verify by running the app.

### 7. Controls are defined once and mapped to inputs

The session exposes which action is available, and the live view maps inputs to it, so touch and keyboard cannot disagree:

| Input | Effect |
|---|---|
| Tap or click | Main action if the phase has one, otherwise pause or resume; skips get-ready |
| Press and hold | Pause or resume, in phases with a main action |
| Space | Pause or resume; skips get-ready |
| Return | Main action |
| Delete | Undo last AMRAP round |
| F | Finish For Time or Stopwatch |
| Escape | End workout while paused |

Tap and hold use an exclusive gesture so a hold never also counts as a tap.

### 8. Cue sounds are generated in code

`CuePlayer` uses `AVAudioEngine` to play short sine-tone buffers generated at launch, so there are no audio assets to source or license. Proposed sounds: a short high tick, a rising two-tone for work start, a falling two-tone for rest start, and a three-note finish.

On iPad, the audio session uses `.playback` with `.mixWithOthers`, which keeps music playing and ignores the silent setting. The Mac has no audio session and mixes by default. Ducking was left out because it adds session activation around every cue.

### 9. Keeping the display awake and running on Mac

`DisplayWake` is one small type with a platform branch:

- **iPad:** `isIdleTimerDisabled`.
- **Mac:** `ProcessInfo.beginActivity` with `.idleDisplaySleepDisabled` and `.userInitiated`, which also prevents App Nap from delaying cues when the window is covered.

On iPad, the root view watches `scenePhase` and pauses when it leaves `.active`. The session is otherwise unaffected, because it is driven by supplied time.

### 10. Proposed visual design

This follows the specs and can be adjusted without changing behaviour. Colours are full-screen, each checked for 4.5:1 contrast during implementation:

| State | Background | Text |
|---|---|---|
| Get-ready | Amber | Near-black |
| Work | Green | Near-black |
| Rest | Blue | White |
| Final seconds | Red | White |
| Paused | Dark grey | White |

The main number uses a heavy rounded system font with monospaced digits, sized from the available space using `GeometryReader`. The screen flow is a grid of the eight workouts, then setup, then the live view, then the summary. The drain is a darker layer rising over the phase colour.

### 11. Clean code conventions for this project

- Types and functions do one job and are named in workout language (`Segment`, `mainAction`, `timeLeft`).
- No workout rules in views or the controller, and no system frameworks in the engine.
- Use Swift's `Duration` for all times, not bare numbers. Named constants replace literals such as the 3-second warning.
- Prefer exhaustive `switch` without `default` on workout types, so a new type produces compile errors everywhere it must be handled.
- Prefer small functions and early returns, and comments only for reasoning the code cannot show.
- Swift 6 language mode and Swift Testing for tests. Engine tests name the behaviour in spec language.
- Only code the specs need: no protocols or options for hypothetical future use.

### 12. Assumptions from discovery

These were proposed by the assistant rather than explicitly confirmed, and are easy to change:

- Get-ready presets are Off, 5, 10, 15 and 30, a tap or space skips the get-ready, and the chosen value lasts while the app is open.
- A set starts on its own when rest ends, with no extra tap.
- AMRAP round counts accumulate across blocks, and counting defaults to on.
- For Time uses splits via the main action and a separate Finish control.
- Stopping and ending are handled through the pause state.
- A summary screen appears at the end, without saving anything.

## Risks / Trade-offs

- **Tap and press-and-hold can conflict, especially with a trackpad.** → Use one exclusive gesture and verify it on both devices. The on-screen undo and keyboard offer fallbacks.
- **The 100 ms tick and audio latency could exceed the cue target on a busy device.** → Cues are short, and timing is verified by hand on real hardware.
- **Without ducking, cues may be hard to hear over loud music.** → Accepted for now. Ducking can be added inside `CuePlayer` without other changes.
- **Colours and sounds cannot be fully judged from a document.** → They are isolated in one place each, for quick adjustment after trying a real workout.
- **Installing on an iPad expires after 7 days on a free Apple account.** → Reinstall from Xcode, or use a paid developer account.

## Migration Plan

None. This is a new app with no existing data or users.

## Open Questions

- Which exact colour shades and tones feel right in a real workout? This can be tuned after first use without changing the specs or structure.
