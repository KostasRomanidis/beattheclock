# Spec Delta

## MODIFIED Requirements

### Requirement: Main number
The largest element on screen SHALL be the main number: time left in the current phase for clock-driven phases, or time so far for For Time, Stopwatch and sets in Sets. For For Time the main number SHALL include hundredths of a second, shown smaller than the minutes and seconds.

#### Scenario: Intervals work phase
- **WHEN** an Intervals work phase has 37 seconds left
- **THEN** the main number shows 0:37

#### Scenario: For Time
- **WHEN** For Time has been running for 4 minutes, 30 seconds and 250 milliseconds
- **THEN** the main number shows 4:30.25

#### Scenario: Rest in Sets
- **WHEN** a rest in Sets has 1:10 left
- **THEN** the main number shows 1:10

#### Scenario: Stopwatch stays in whole seconds
- **WHEN** Stopwatch has been running for 4 minutes, 30 seconds and 250 milliseconds
- **THEN** the main number shows 4:30

### Requirement: Time format
Times SHALL display as minutes and seconds, adding hours only when needed. A countdown SHALL show 0:00 only when its phase ends, so the last second of a phase displays as 0:01. For Time SHALL display its running time, its summary total and each of its splits with two decimal places for hundredths of a second, cut off rather than rounded, so a time never reads later than it is. Every other time, including the cap left in For Time and the get-ready countdown, SHALL stay in whole seconds.

#### Scenario: Under an hour
- **WHEN** a time is 45 seconds
- **THEN** it displays as 0:45

#### Scenario: Over an hour
- **WHEN** a time is 1 hour, 2 minutes and 5 seconds
- **THEN** it displays as 1:02:05

#### Scenario: Last second of a countdown
- **WHEN** a countdown has 0.4 seconds left
- **THEN** it displays as 0:01

#### Scenario: For Time hundredths
- **WHEN** a For Time time is 2 minutes, 10 seconds and 679 milliseconds
- **THEN** it displays as 2:10.67

#### Scenario: Whole second in For Time
- **WHEN** a For Time time is exactly 4 minutes
- **THEN** it displays as 4:00.00

#### Scenario: Cap left stays in whole seconds
- **WHEN** For Time has a 20:00 cap and 12:10.40 has passed
- **THEN** the secondary total shows 7:50 left

### Requirement: Secondary total
A smaller total SHALL appear at the top of the screen. Intervals, Tabata, EMOM and multi-block AMRAP SHALL show total time left. For Time with a cap SHALL show cap time left. Sets SHALL show total elapsed. Single-block AMRAP, Countdown, Stopwatch and For Time without a cap SHALL show no total.

#### Scenario: Intervals total left
- **WHEN** Intervals of 8 rounds, work 0:45 and rest 0:15 is in round 3 with 0:37 left
- **THEN** the secondary total shows 5:37 left

#### Scenario: Timer has no separate total
- **WHEN** a Countdown is running
- **THEN** no secondary total is shown

#### Scenario: Sets elapsed
- **WHEN** a Sets workout has been running for 12:00
- **THEN** the secondary total shows 12:00 elapsed

### Requirement: Next phase preview
Where a next phase is known, the screen SHALL show what it is and how long it lasts, introduced by "Next:". In the final phase it SHALL indicate that this is the final one. For EMOM with more than one exercise, a next window SHALL be named as the next exercise, and the final window SHALL be indicated as the final exercise.

#### Scenario: Next is rest
- **WHEN** a work phase is followed by a 0:15 rest
- **THEN** the screen shows "Next: Rest 0:15"

#### Scenario: Final phase
- **WHEN** the last work phase is running
- **THEN** the screen shows "Final round"

#### Scenario: Next EMOM exercise
- **WHEN** an EMOM of 5 exercises at 1:00 is in the fourth window of a round
- **THEN** the screen shows "Next: Exercise 5 · 1:00"

#### Scenario: Last EMOM exercise
- **WHEN** the last window of the last round of an EMOM with 5 exercises is running
- **THEN** the screen shows "Final exercise"

### Requirement: Accessible state and controls
Phase and pause state SHALL always appear as text as well as colour, and text SHALL meet a contrast ratio of at least 4.5:1 on every state's background. Every on-screen control SHALL have an accessibility label. VoiceOver SHALL read the main number in whole seconds only, so hundredths changing do not interrupt it.

#### Scenario: Without relying on colour
- **WHEN** a user cannot distinguish the phase colours
- **THEN** the word for the current state, such as WORK or REST, is visible

#### Scenario: VoiceOver
- **WHEN** VoiceOver focuses the undo control
- **THEN** it announces what the control does

#### Scenario: VoiceOver on For Time
- **WHEN** VoiceOver focuses the main number during For Time at 4:30.25
- **THEN** it reads the time as 4:30 and does not announce each change of the hundredths
