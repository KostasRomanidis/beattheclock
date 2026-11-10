# Spec Delta

## MODIFIED Requirements

### Requirement: Workout settings and defaults
Each workout type SHALL offer only its own settings, with these defaults. Timer: duration 5:00. AMRAP: duration 12:00, 1 block, rest 1:00, round counting on. EMOM: every 1:00, 1 exercise, 10 rounds, rest 1:00. Tabata: 0:20 work and 0:10 rest fixed, 8 rounds. Intervals: work 0:40, rest 0:20, 8 rounds. For Time: no cap, optional cap. Stopwatch: no settings. Sets: rest 1:30, 5 sets.

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

## ADDED Requirements

### Requirement: One-tap presets
Each adjustable duration and count in setup SHALL offer a short row of common values that set the value in one tap, alongside the step control. Each setting's default SHALL be among its presets. A value set by stepping to something that isn't a preset SHALL leave no preset selected.

#### Scenario: Choosing a preset
- **WHEN** the user taps the 20:00 preset under AMRAP duration
- **THEN** the duration becomes 20:00 and that preset shows as selected

#### Scenario: Default is selected on open
- **WHEN** the user opens EMOM setup with default settings
- **THEN** the 1:00, 1 and 10 presets show as selected for every, exercises and rounds

#### Scenario: Custom value
- **WHEN** the user steps AMRAP duration from 12:00 to 13:00
- **THEN** no duration preset shows as selected

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
