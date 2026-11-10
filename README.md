# Beat the Clock

A workout timer for Mac and iPad, built to be read from across the room. It has eight workout types: Timer, AMRAP, EMOM, Tabata, Intervals, For Time, Stopwatch and Sets.

## Requirements

- Xcode 27.2 or later (Swift 6.4)
- macOS 14 or later, or iPadOS 17 or later

## Project layout

- `beattheclock/`: the SwiftUI app: setup screens, live view, sound cues and screen wake.
- `Packages/WorkoutEngine/`: all workout rules and timing as a pure Swift package with no UI, driven by supplied time so tests run instantly.
- `openspec/`: the specs and design the app was built from.

## Test

The engine tests need no simulator:

```sh
cd Packages/WorkoutEngine
swift test
```

## Build

From the project root:

```sh
# Mac
xcodebuild -project beattheclock.xcodeproj -scheme beattheclock -destination 'platform=macOS' build

# iPad simulator
xcodebuild -project beattheclock.xcodeproj -scheme beattheclock -destination 'generic/platform=iOS Simulator' build
```

## Run

Open `beattheclock.xcodeproj` in Xcode, choose **My Mac**, an iPad simulator or a connected iPad as the run destination, and press ⌘R.

Running on a real iPad needs your Apple account selected under the target's **Signing & Capabilities**. With a free account the app expires after 7 days and needs reinstalling from Xcode; a paid developer account avoids that.
