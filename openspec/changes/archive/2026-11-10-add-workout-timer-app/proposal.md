# Proposal

## Why

Beat the Clock is a workout timer for training with a Mac or iPad propped up in view. General-purpose timers handle work, rest and rounds poorly and are hard to read from across a room, so this app provides one clean, glanceable clock for the common workout formats. The project has no app yet, so this change creates it.

## What Changes

- Add a native SwiftUI app named Beat the Clock for macOS and iPadOS.
- Add eight workout types: Timer, AMRAP, EMOM, Tabata, Intervals, For Time, Stopwatch and Sets.
- Add quick setup with sensible defaults, showing the calculated total time where the end is known.
- Add a configurable get-ready countdown that defaults to 10 seconds on every launch.
- Add a full-screen live view: the current phase as the main countdown, plus round number, total time, what comes next, and colour that shows the phase.
- Add sound cues for phase changes and the final seconds, and keep the screen awake during a workout.
- Add touch and keyboard controls: pause and resume, skip the get-ready, count and undo AMRAP rounds, record For Time rounds, and finish athlete-ended phases.

**Out of scope for this change:**

- Android and iPhone-specific layouts.
- Saved timers, workout history and any other persistence, including remembered settings.
- Running with the iPad locked or the app in the background on iPad.
- Chained workouts, named circuit stations, ladders, Death By, alternating EMOM, tempo and holds.
- App Store publishing, including name availability and trademark checks.

## Capabilities

### New Capabilities

- `workout-setup`: the eight workout types, their settings and defaults, the calculated total, and the get-ready choice.
- `workout-session`: how a configured workout runs over time, including phase order, timing accuracy, pause and resume, and the controls used while it runs.
- `session-display`: what the live screen shows for each workout type and phase, and how it stays readable from a distance.
- `session-cues`: the sounds that signal phase changes and final seconds, and keeping the screen awake during a workout.

### Modified Capabilities

None. The project has no existing specs.

## Impact

- **Code:** a new Xcode project and SwiftUI app. The project currently has no application code.
- **Dependencies:** Apple frameworks only, with no third-party packages.
- **Tooling:** requires Xcode. The installed version is Xcode 27.2 with Swift 6.4.
- **Distribution:** runs locally on the Mac. Installing on an iPad with a free Apple account expires after 7 days; a paid developer account avoids that.
