# Design

## Context

- `SessionDisplay.format(_:roundingUp:)` is the one place times become text. It drops the fraction, and the live view, summary, splits, setup steppers, preset chips and read-back sentence all use it.
- `Session` stores splits and workout time as full-precision `Duration` values. A split is stamped at the instant of the tap, not at the next tick, so the data already holds hundredths. Only the formatting throws them away.
- `SessionController` ticks every 100 ms, rebuilds `SessionDisplay` and plays due cues. `Session.update` reports cues "at the moment they are due", so a faster tick can only make cues land sooner.
- The main number in `SessionView` is one `Text` that scales down to fit (`minimumScaleFactor`), with a VoiceOver label built from `mainTime`.
- Setup builds each row in `SetupView`: `DurationStepper` shows a value and a `PresetRow` of chips, both via `SessionDisplay.format`. The get-ready picker is a segmented `Picker` whose title the segmented style hides.
- Workout names come from one `WorkoutConfiguration.name` switch in `ContentView.swift`. `Timer` is also the name of the enum case used by the engine and its tests.

## Goals / Non-Goals

**Goals:**
- Hundredths for For Time only, with every other time unchanged.
- One place decides how a time or a preset is written, so the same value never reads two ways.

**Non-Goals:**
- No rename of the `timer` enum case. Only the name users see changes, so the engine and its tests stay untouched.
- No change to cue timing rules, colours, the phase rules or what is stored.
- No per-workout choice of precision. Only For Time uses hundredths.

## Decisions

**1. Hundredths are a format option, cut off, not rounded.**
`format` gains a `hundredths: Bool = false` parameter. With it on, the fraction is the whole hundredths in the time, so 2:10.679 reads `2:10.67`. Rounding could show 0:59.996 as `1:00.00` while the real time is still under a minute, and a displayed time must never be later than the real one. `roundingUp` (countdowns) and `hundredths` (count-up) never apply together.
*Alternative:* a separate formatter for For Time. Rejected because hours handling and padding would be duplicated.

**2. The live main number gets a separate fraction.**
`SessionDisplay` gains `mainFraction: String?`, for example `".25"`, which is nil outside the For Time count-up. `mainTime` stays whole seconds (`4:30`). The view draws `mainTime` and the smaller `mainFraction` in one `Text` (a concatenation), so the number still scales as one piece with fixed-width digits.
*Alternative:* put the whole `4:30.25` in `mainTime` and split the string in the view. Rejected because parsing a display string is fragile.
*Alternative:* one string at one size. Rejected because the digits would shrink about 20% with no hierarchy between seconds and fraction.

**3. VoiceOver reads `mainTime` only.**
The accessibility label stays `"\(label), \(mainTime)"` and ignores the fraction, so VoiceOver isn't asked to announce a change roughly sixty times a second. This is a requirement in the session-display spec.

**4. Splits and summary use the same format.**
Splits stay stored in full precision. The summary and split rows call `format(..., hundredths: true)` for For Time only (decided from the configuration, not from the value). The sum of the shown splits can differ from the shown total by 0.01 because each is cut off separately. Storing rounded splits would hide the real difference, so I accept it.

**5. A faster tick only while For Time counts up and runs.**
`tickInterval` becomes a function of the display: about 16 ms when the session is running and `mainFraction` is non-nil, and 100 ms otherwise (including paused, get-ready, summary and every other workout). The loop in `run()` reads it each pass.
*Alternative:* a `TimelineView(.animation)` around only the number. Rejected because `Session` time is a `ContinuousClock.Instant`, not a `Date`, so it adds a second time path next to the controller.
*Alternative:* keep 100 ms. Rejected because hundredths would visibly jump by ten.

**6. One short-label function for chips.**
`SessionDisplay.presetLabel(_:)` returns "12 min" for whole minutes, "None" for zero, and otherwise seconds such as "90 s" or "20 s". The get-ready chips already read "5 s", "10 s" and "Off", so they keep their current style, and zero there keeps reading "Off" because it is a choice to switch something off, not a missing amount. Steppers, the live screen and the read-back sentence keep clock format.
*Alternative:* write the labels by hand per preset list. Rejected because the lists change and the rule would drift.

**7. "None" and "No cap" in setup.**
`DurationStepper` takes an optional `zeroLabel` ("None") used for its value and its zero chip. For Time's cap is a switch, so it has no zero to rename. The switch is titled "Time cap", and when it is off, a secondary line under the title reads "No cap". Turning it on shows the "Time cap" stepper and presets, as today.

**8. The Get ready label sits on the picker row.**
The segmented picker's title is hidden by its style. The row becomes a `LabeledContent("Get ready")` holding the picker with its own label hidden, so the title is visible and VoiceOver still reads "Get ready".

**9. Naming changes are text only.**
`WorkoutConfiguration.name` returns "Countdown" for `.timer`. "Final round", "Final exercise" and "Next:" are text in `SessionDisplay.nextPhase`. No enum, case or type is renamed.

## Risks / Trade-offs

- [A tick of about 16 ms re-renders the whole live view roughly sixty times a second during For Time, which costs battery on iPad] → Only while For Time is running. Measure on a device. If it's too costly, move the number into its own view so the rest of the screen isn't redrawn.
- [Hundredths are more precise than a tap, which lands within roughly 30 to 50 ms] → The last digit is noise from human timing, not from the clock. It's still honest for comparing runs, and the spec cuts off rather than rounds.
- [`Task.sleep` at 16 ms isn't exact] → The displayed time always comes from the stored instants, not from counting ticks, so a late tick shows a later but correct number.
- [Shown splits may not add up to the shown total by 0.01] → Accepted, see decision 4.
- [The wider main number makes the digits smaller, most on a narrow iPad Split View] → Scaling already handles resizing. Check the narrowest width by hand.
- [The app target has no tests, so the setup wording isn't covered] → Put the shared logic (`format`, `presetLabel`) in `WorkoutEngine` where it is tested. Check the rest by hand.
