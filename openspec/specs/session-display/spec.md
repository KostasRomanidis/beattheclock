# session-display Specification

## Purpose

Defines what the live workout screen shows for each workout type and phase, and keeps it readable at a glance from across a room.

## Requirements

### Requirement: Main number
The largest element on screen SHALL be the main number: time left in the current phase for clock-driven phases, or time so far for For Time, Stopwatch and sets in Sets.

#### Scenario: Intervals work phase
- **WHEN** an Intervals work phase has 37 seconds left
- **THEN** the main number shows 0:37

#### Scenario: For Time
- **WHEN** For Time has been running for 4 minutes and 30 seconds
- **THEN** the main number shows 4:30

#### Scenario: Rest in Sets
- **WHEN** a rest in Sets has 1:10 left
- **THEN** the main number shows 1:10

### Requirement: Time format
Times SHALL display as minutes and seconds, adding hours only when needed. A countdown SHALL show 0:00 only when its phase ends, so the last second of a phase displays as 0:01.

#### Scenario: Under an hour
- **WHEN** a time is 45 seconds
- **THEN** it displays as 0:45

#### Scenario: Over an hour
- **WHEN** a time is 1 hour, 2 minutes and 5 seconds
- **THEN** it displays as 1:02:05

#### Scenario: Last second of a countdown
- **WHEN** a countdown has 0.4 seconds left
- **THEN** it displays as 0:01

### Requirement: Secondary total
A smaller total SHALL appear at the top of the screen. Intervals, Tabata, EMOM and multi-block AMRAP SHALL show total time left. For Time with a cap SHALL show cap time left. Sets SHALL show total elapsed. Single-block AMRAP, Timer, Stopwatch and For Time without a cap SHALL show no total.

#### Scenario: Intervals total left
- **WHEN** Intervals of 8 rounds, work 0:45 and rest 0:15 is in round 3 with 0:37 left
- **THEN** the secondary total shows 5:37 left

#### Scenario: Timer has no separate total
- **WHEN** a Timer is running
- **THEN** no secondary total is shown

#### Scenario: Sets elapsed
- **WHEN** a Sets workout has been running for 12:00
- **THEN** the secondary total shows 12:00 elapsed

### Requirement: Workout position
The screen SHALL show the current round or block and how many there are, for workouts that have them, the current set in Sets, and rounds counted in AMRAP or round number in For Time. For EMOM with more than one exercise, it SHALL also show the current exercise within the round and how many there are.

#### Scenario: Round position
- **WHEN** an Intervals workout of 8 rounds is in its third round
- **THEN** the screen shows round 3 of 8

#### Scenario: Set position
- **WHEN** a Sets workout of 5 sets is resting after the second set
- **THEN** the screen shows that set 3 of 5 is next

#### Scenario: EMOM exercise position
- **WHEN** an EMOM of 3 rounds of 5 exercises is in the fourth window of its second round
- **THEN** the screen shows "Round 2 of 3, exercise 4 of 5"

#### Scenario: Resting between EMOM rounds
- **WHEN** an EMOM of 3 rounds of 5 exercises is resting after its second round
- **THEN** the screen shows that round 3 of 3 is next

#### Scenario: EMOM with one exercise
- **WHEN** an EMOM of 10 rounds with 1 exercise is in its fourth window
- **THEN** the screen shows round 4 of 10 and no exercise position

### Requirement: Next phase preview
Where a next phase is known, the screen SHALL show what it is and how long it lasts. In the final phase it SHALL indicate that this is the last one. For EMOM with more than one exercise, a next window SHALL be named as the next exercise, and the final window SHALL be indicated as the last exercise.

#### Scenario: Next is rest
- **WHEN** a work phase is followed by a 0:15 rest
- **THEN** the screen shows the next phase as rest 0:15

#### Scenario: Final phase
- **WHEN** the last work phase is running
- **THEN** the screen indicates this is the last round

#### Scenario: Next EMOM exercise
- **WHEN** an EMOM of 5 exercises at 1:00 is in the fourth window of a round
- **THEN** the screen shows the next phase as exercise 5, 1:00

#### Scenario: Last EMOM exercise
- **WHEN** the last window of the last round of an EMOM with 5 exercises is running
- **THEN** the screen indicates this is the last exercise

### Requirement: Phase colour
The whole screen background SHALL use a distinct colour for each state: get-ready, work, rest, final seconds and paused. The final-seconds colour SHALL apply to the last 3 seconds of every countdown phase.

#### Scenario: Work to rest
- **WHEN** a work phase ends and a rest phase starts
- **THEN** the background changes to the rest colour

#### Scenario: Final seconds
- **WHEN** a countdown phase has 3 seconds or less left
- **THEN** the background changes to the final-seconds colour

### Requirement: Progress
For a countdown phase, the screen colour SHALL drain in proportion to the phase's time used. For workouts with a known length, a bar SHALL show progress through the whole workout.

#### Scenario: Halfway through a phase
- **WHEN** half of a phase's time has passed
- **THEN** half of the phase colour has drained

#### Scenario: Workout progress
- **WHEN** half of a known-length workout's time has passed
- **THEN** the bar shows it half complete

#### Scenario: Unknown length
- **WHEN** Stopwatch is running
- **THEN** no workout progress bar is shown

### Requirement: Readable at any size
The main number SHALL scale to fill the available space and remain fully visible in a resizable Mac window and on iPad in either orientation. Digits SHALL have fixed width so the number does not shift as it changes.

#### Scenario: Resizing on Mac
- **WHEN** the user resizes the window during a workout
- **THEN** the main number resizes to fit with no clipped digits

#### Scenario: Rotating iPad
- **WHEN** the iPad rotates during a workout
- **THEN** the layout adapts and the workout continues uninterrupted

### Requirement: Accessible state and controls
Phase and pause state SHALL always appear as text as well as colour, and text SHALL meet a contrast ratio of at least 4.5:1 on every state's background. Every on-screen control SHALL have an accessibility label.

#### Scenario: Without relying on colour
- **WHEN** a user cannot distinguish the phase colours
- **THEN** the word for the current state, such as WORK or REST, is visible

#### Scenario: VoiceOver
- **WHEN** VoiceOver focuses the undo control
- **THEN** it announces what the control does
