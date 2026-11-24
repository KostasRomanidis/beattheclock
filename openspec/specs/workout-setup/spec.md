# workout-setup Specification

## Purpose

Lets a user choose one of eight workout types and configure it in a few taps, with defaults good enough to start immediately and nothing stored between launches.

## Requirements

### Requirement: Workout type selection
The app SHALL offer eight workout types: Countdown, AMRAP, EMOM, Tabata, Intervals, For Time, Stopwatch and Sets.

#### Scenario: Choosing a workout
- **WHEN** the user opens the app
- **THEN** all eight workout types are available to choose from

#### Scenario: Starting with defaults
- **WHEN** the user chooses a workout type and starts without changing anything
- **THEN** the workout runs using that type's default settings

#### Scenario: Countdown name
- **WHEN** the user looks for the single count-down clock
- **THEN** it is offered as Countdown, and no workout type is called Timer

### Requirement: Workout settings and defaults
Each workout type SHALL offer only its own settings, with these defaults. Countdown: duration 5:00. AMRAP: duration 12:00, 1 block, rest 1:00, round counting on. EMOM: every 1:00, 1 exercise, 10 rounds, rest 1:00. Tabata: 0:20 work and 0:10 rest fixed, 8 rounds. Intervals: work 0:40, rest 0:20, 8 rounds. For Time: no cap, optional cap. Stopwatch: no settings. Sets: rest 1:30, 5 sets.

#### Scenario: Intervals settings
- **WHEN** the user sets Intervals to 8 rounds, work 0:45 and rest 0:15
- **THEN** the workout uses those values

#### Scenario: Tabata timing is fixed
- **WHEN** the user configures Tabata
- **THEN** the number of rounds can be changed and the work and rest durations cannot

#### Scenario: AMRAP rest only with multiple blocks
- **WHEN** AMRAP is set to 1 block
- **THEN** the rest setting is unavailable

#### Scenario: EMOM rest only with multiple exercises
- **WHEN** EMOM is set to 1 exercise
- **THEN** the rest setting is unavailable and no rest is applied between rounds

#### Scenario: EMOM with several exercises
- **WHEN** the user sets EMOM to every 1:00, 5 exercises, 3 rounds and rest 1:00
- **THEN** the workout uses those values

#### Scenario: Countdown default
- **WHEN** the user opens Countdown setup with default settings
- **THEN** the duration is 5:00

### Requirement: Valid settings only
The setup controls SHALL prevent invalid settings: work, timer, window and cap durations are at least 1 second, rest is at least 0 seconds, and rounds, blocks, sets and exercises are at least 1.

#### Scenario: Lower limit reached
- **WHEN** the user tries to reduce rounds below 1
- **THEN** rounds stay at 1

#### Scenario: Intervals with no rest
- **WHEN** the user sets Intervals rest to 0:00
- **THEN** the work phases run back to back with no rest phase

#### Scenario: Exercises lower limit
- **WHEN** the user tries to reduce EMOM exercises below 1
- **THEN** exercises stay at 1

### Requirement: Calculated total time
Setup SHALL show the calculated total for workouts with a known length, derived from the other settings and not entered separately. The total SHALL exclude the get-ready countdown. For Time, Stopwatch and Sets SHALL show no calculated total.

#### Scenario: Intervals total
- **WHEN** Intervals is set to 8 rounds, work 0:45 and rest 0:15
- **THEN** setup shows a total of 7:45

#### Scenario: Multiple AMRAP blocks
- **WHEN** AMRAP is set to 3 blocks of 5:00 with 1:00 rest
- **THEN** setup shows a total of 17:00

#### Scenario: Total updates with settings
- **WHEN** the user changes a setting that affects the total
- **THEN** the shown total updates immediately

### Requirement: Get-ready choice
Setup SHALL let the user choose a get-ready length of Off, 5, 10, 15 or 30 seconds, in a row visibly labelled "Get ready". One value SHALL apply across all workout types.

#### Scenario: Default on launch
- **WHEN** the app launches
- **THEN** the get-ready length is 10 seconds

#### Scenario: Shared across workouts
- **WHEN** the user chooses 30 seconds in one workout type and then opens another
- **THEN** the other workout type also shows 30 seconds

#### Scenario: Label is visible
- **WHEN** the user opens the setup of any workout type
- **THEN** the get-ready choices appear under a visible "Get ready" label

### Requirement: Settings last only while the app is open
Settings SHALL be kept while the app stays open and SHALL return to their defaults when the app is next launched. The app SHALL store no settings or workouts between launches.

#### Scenario: Returning to setup
- **WHEN** a workout ends and the user returns to setup
- **THEN** the settings used for that workout are still shown

#### Scenario: Relaunching
- **WHEN** the user quits and reopens the app
- **THEN** all settings show their defaults

### Requirement: One-tap presets
Each adjustable duration and count in setup SHALL offer a short row of common values that set the value in one tap, alongside the step control. Each setting's default SHALL be among its presets. A value set by stepping to something that isn't a preset SHALL leave no preset selected. Duration presets SHALL read in words: whole minutes as "12 min" and other times in seconds as "20 s" or "90 s". A rest preset of zero SHALL read "None".

#### Scenario: Choosing a preset
- **WHEN** the user taps the 20 min preset under AMRAP duration
- **THEN** the duration becomes 20:00 and that preset shows as selected

#### Scenario: Default is selected on open
- **WHEN** the user opens EMOM setup with default settings
- **THEN** the 1 min, 1 and 10 presets show as selected for every, exercises and rounds

#### Scenario: Custom value
- **WHEN** the user steps AMRAP duration from 12:00 to 13:00
- **THEN** no duration preset shows as selected

#### Scenario: Preset wording
- **WHEN** the user opens Intervals setup
- **THEN** the work presets read 20 s, 30 s, 40 s, 45 s, 1 min and 2 min, and the rest presets read None, 10 s, 15 s, 20 s, 30 s and 1 min

### Requirement: Workout read-back
Setup SHALL show a plain-language sentence describing what the configured workout will do, including its calculated total for workouts with a known length. The sentence SHALL update immediately when a setting changes.

#### Scenario: Intervals read-back
- **WHEN** Intervals is set to 8 rounds, work 0:40 and rest 0:20
- **THEN** setup reads "8 rounds of 0:40 work and 0:20 rest, 7:40 in total."

#### Scenario: EMOM with several exercises
- **WHEN** EMOM is set to every 1:00, 5 exercises, 3 rounds and rest 1:00
- **THEN** setup reads "3 rounds of 5 exercises, a new one every 1:00, with 1:00 rest between rounds. 17:00 in total."

#### Scenario: EMOM with one exercise
- **WHEN** EMOM is set to every 1:00, 1 exercise and 10 rounds
- **THEN** setup reads "A new round starts every 1:00 for 10 rounds, 10:00 in total."

#### Scenario: Unknown length
- **WHEN** Stopwatch is chosen
- **THEN** setup reads "Counts up until you finish." and shows no total

### Requirement: Zero and absent values read in words
Setup SHALL show a rest of zero as "None" and For Time with no cap as "No cap", rather than as a zero time. A setting that has a cap SHALL title its value "Time cap".

#### Scenario: No rest
- **WHEN** the user steps Intervals rest down to zero
- **THEN** the rest value reads "None"

#### Scenario: No cap
- **WHEN** For Time has no cap
- **THEN** setup reads "No cap" for the time cap

#### Scenario: Cap set
- **WHEN** the user switches the time cap on
- **THEN** a value titled "Time cap" appears with its presets
