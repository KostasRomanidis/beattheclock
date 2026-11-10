# workout-setup Specification

## Purpose

Lets a user choose one of eight workout types and configure it in a few taps, with defaults good enough to start immediately and nothing stored between launches.

## Requirements

### Requirement: Workout type selection
The app SHALL offer eight workout types: Timer, AMRAP, EMOM, Tabata, Intervals, For Time, Stopwatch and Sets.

#### Scenario: Choosing a workout
- **WHEN** the user opens the app
- **THEN** all eight workout types are available to choose from

#### Scenario: Starting with defaults
- **WHEN** the user chooses a workout type and starts without changing anything
- **THEN** the workout runs using that type's default settings

### Requirement: Workout settings and defaults
Each workout type SHALL offer only its own settings, with these defaults. Timer: duration 5:00. AMRAP: duration 12:00, 1 block, rest 1:00, round counting on. EMOM: every 1:00, 10 rounds. Tabata: 0:20 work and 0:10 rest fixed, 8 rounds. Intervals: work 0:40, rest 0:20, 8 rounds. For Time: no cap, optional cap. Stopwatch: no settings. Sets: rest 1:30, 5 sets.

#### Scenario: Intervals settings
- **WHEN** the user sets Intervals to 8 rounds, work 0:45 and rest 0:15
- **THEN** the workout uses those values

#### Scenario: Tabata timing is fixed
- **WHEN** the user configures Tabata
- **THEN** the number of rounds can be changed and the work and rest durations cannot

#### Scenario: AMRAP rest only with multiple blocks
- **WHEN** AMRAP is set to 1 block
- **THEN** the rest setting is unavailable

### Requirement: Valid settings only
The setup controls SHALL prevent invalid settings: work, timer, window and cap durations are at least 1 second, rest is at least 0 seconds, and rounds, blocks and sets are at least 1.

#### Scenario: Lower limit reached
- **WHEN** the user tries to reduce rounds below 1
- **THEN** rounds stay at 1

#### Scenario: Intervals with no rest
- **WHEN** the user sets Intervals rest to 0:00
- **THEN** the work phases run back to back with no rest phase

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
Setup SHALL let the user choose a get-ready length of Off, 5, 10, 15 or 30 seconds. One value SHALL apply across all workout types.

#### Scenario: Default on launch
- **WHEN** the app launches
- **THEN** the get-ready length is 10 seconds

#### Scenario: Shared across workouts
- **WHEN** the user chooses 30 seconds in one workout type and then opens another
- **THEN** the other workout type also shows 30 seconds

### Requirement: Settings last only while the app is open
Settings SHALL be kept while the app stays open and SHALL return to their defaults when the app is next launched. The app SHALL store no settings or workouts between launches.

#### Scenario: Returning to setup
- **WHEN** a workout ends and the user returns to setup
- **THEN** the settings used for that workout are still shown

#### Scenario: Relaunching
- **WHEN** the user quits and reopens the app
- **THEN** all settings show their defaults
