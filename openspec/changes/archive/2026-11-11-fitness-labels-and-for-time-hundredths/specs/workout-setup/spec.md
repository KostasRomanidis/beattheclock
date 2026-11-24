# Spec Delta

## MODIFIED Requirements

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

## ADDED Requirements

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
