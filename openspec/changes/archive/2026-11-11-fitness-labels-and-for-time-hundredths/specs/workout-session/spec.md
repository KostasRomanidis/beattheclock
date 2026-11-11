# Spec Delta

## MODIFIED Requirements

### Requirement: Phase order for clock-driven workouts
Countdown, AMRAP, EMOM, Tabata and Intervals SHALL run their phases in order and move on automatically when each phase's time runs out. Rest SHALL occur only between work phases, never after the last one. EMOM windows within a round SHALL run back to back; with more than one exercise, EMOM SHALL rest between rounds, and with one exercise it SHALL run all windows back to back.

#### Scenario: Intervals sequence
- **WHEN** Intervals runs with 8 rounds, work 0:45 and rest 0:15
- **THEN** 8 work phases run with 7 rest phases between them, and the workout ends when the eighth work phase ends

#### Scenario: Multiple AMRAP blocks
- **WHEN** AMRAP runs with 3 blocks of 5:00 and 1:00 rest
- **THEN** the phases run as block, rest, block, rest, block

#### Scenario: EMOM windows
- **WHEN** EMOM runs every 1:00 for 10 rounds with 1 exercise
- **THEN** 10 windows of 1:00 run consecutively and the workout ends after the tenth

#### Scenario: EMOM rounds of exercises
- **WHEN** EMOM runs every 1:00 with 5 exercises, 3 rounds and 1:00 rest
- **THEN** 5 windows run, then a 1:00 rest, then 5 windows, then a 1:00 rest, then 5 windows, and the workout ends after the fifteenth window at 17:00

#### Scenario: EMOM rounds with no rest
- **WHEN** EMOM runs every 1:00 with 5 exercises, 3 rounds and rest 0:00
- **THEN** 15 windows of 1:00 run consecutively

#### Scenario: Next exercise cue
- **WHEN** an EMOM window ends and the next exercise's window begins
- **THEN** the work-start sound plays

### Requirement: For Time splits
For Time SHALL treat each main action as the end of a round and record the time taken for that round, to hundredths of a second. Finish SHALL be a separate visible control so that recording a split cannot end the workout by accident.

#### Scenario: Recording a split
- **WHEN** the user taps at 2:10.25 and again at 4:30.50
- **THEN** the recorded round times are 2:10.25 and 2:20.25

#### Scenario: Hundredths are not rounded up
- **WHEN** the user taps at 1:00.999
- **THEN** the recorded time is 1:00.99

### Requirement: Workout summary
When a workout ends, the app SHALL show a summary with the workout time and any rounds or splits recorded, and offer to repeat the workout or return to setup. For For Time, the workout time and every split SHALL show hundredths of a second. The summary SHALL NOT be saved.

#### Scenario: AMRAP summary
- **WHEN** an AMRAP with counted rounds ends
- **THEN** the summary shows the workout time and the rounds counted

#### Scenario: For Time summary
- **WHEN** a For Time workout is finished at 4:30.50 after splits of 2:10.25 and 2:20.25
- **THEN** the summary shows 4:30.50 as the workout time and the splits 2:10.25 and 2:20.25

#### Scenario: Repeating
- **WHEN** the user chooses to repeat from the summary
- **THEN** the same workout starts again from its get-ready countdown
