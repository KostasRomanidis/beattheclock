# workout-session Specification

## Purpose

Defines how a configured workout runs over time: the order of its phases, how each phase ends, how accurately time is kept, and the controls available while it runs.

## Requirements

### Requirement: Get-ready countdown
A workout SHALL begin with the chosen get-ready countdown, unless get-ready is Off. A tap, a click or the space bar during the countdown SHALL skip straight to the workout. The countdown SHALL NOT count towards workout time.

#### Scenario: Countdown then workout
- **WHEN** the user starts a workout with a 10-second get-ready
- **THEN** a 10-second countdown runs and the first phase then begins

#### Scenario: Skipping the countdown
- **WHEN** the user taps during the get-ready countdown
- **THEN** the first phase begins immediately

#### Scenario: Get-ready off
- **WHEN** the user starts a workout with get-ready set to Off
- **THEN** the first phase begins immediately

### Requirement: Phase order for clock-driven workouts
Timer, AMRAP, EMOM, Tabata and Intervals SHALL run their phases in order and move on automatically when each phase's time runs out. Rest SHALL occur only between work phases, never after the last one. EMOM windows within a round SHALL run back to back; with more than one exercise, EMOM SHALL rest between rounds, and with one exercise it SHALL run all windows back to back.

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

### Requirement: Open-ended count-up workouts
For Time and Stopwatch SHALL count up from zero until the user finishes them. For Time SHALL also end automatically when its cap is reached, if a cap is set.

#### Scenario: Finishing For Time
- **WHEN** the user activates Finish during For Time
- **THEN** the workout ends with the time reached

#### Scenario: Reaching the cap
- **WHEN** For Time has a 20:00 cap and the time reaches 20:00
- **THEN** the workout ends at 20:00

### Requirement: Sets alternate user and clock
In Sets, each set SHALL count up until the user marks it done, then the rest SHALL count down and end automatically. When a rest ends, the next set SHALL begin counting up from zero without further input. Marking the last set done SHALL end the workout.

#### Scenario: Set then rest
- **WHEN** the user marks a set done with rest set to 1:30
- **THEN** a 1:30 rest countdown begins

#### Scenario: Rest ends
- **WHEN** a rest countdown reaches zero
- **THEN** the next set begins counting up, showing how long has passed since the rest ended

#### Scenario: Last set
- **WHEN** the user marks the last set done
- **THEN** the workout ends with no further rest

### Requirement: Accurate time
Workout time SHALL be based on real elapsed time, not on counting display updates, so that error does not accumulate. Slow screen updates SHALL NOT shorten or lengthen a phase, and any overrun SHALL be taken from the next phase.

#### Scenario: Long workout
- **WHEN** a 40-minute workout runs without being paused
- **THEN** it ends within 1 second of 40 minutes of real time

#### Scenario: Delayed update
- **WHEN** display updates stall and resume after a phase should have ended
- **THEN** the workout resumes at the correct position in the correct phase

### Requirement: Pause and resume
The user SHALL be able to pause any running workout, in every phase. While paused, all time SHALL stop, and on resuming, every time SHALL continue from where it stopped. The paused state SHALL offer Resume and End Workout.

#### Scenario: Pausing an interval
- **WHEN** the user pauses with 0:37 left in a work phase and resumes two minutes later
- **THEN** the phase continues from 0:37 and the total time left is unchanged by the pause

#### Scenario: Ending early
- **WHEN** the user chooses End Workout while paused
- **THEN** the workout ends and the summary shows the workout time reached

### Requirement: Touch and pointer controls
A tap or click anywhere SHALL perform the phase's main action if it has one: count a round in AMRAP work with counting on, record a split in For Time, or mark a set done during a set. Otherwise it SHALL pause or resume. A press and hold SHALL pause or resume in phases with a main action.

#### Scenario: Tap with no main action
- **WHEN** the user taps during an Intervals phase
- **THEN** the workout pauses

#### Scenario: Tap counts a round
- **WHEN** the user taps during AMRAP work with round counting on
- **THEN** one round is added and the workout keeps running

#### Scenario: Hold pauses
- **WHEN** the user presses and holds during AMRAP work with round counting on
- **THEN** the workout pauses and no round is added

#### Scenario: Tap during AMRAP rest
- **WHEN** the user taps during a rest between AMRAP blocks
- **THEN** the workout pauses and no round is added

### Requirement: Keyboard controls
With a keyboard, the space bar SHALL pause or resume, or skip the get-ready. Return SHALL perform the phase's main action. Delete SHALL undo the last counted AMRAP round. F SHALL finish For Time or Stopwatch. Escape SHALL end the workout while paused.

#### Scenario: Space bar pauses
- **WHEN** the user presses the space bar during a running phase that has a main action
- **THEN** the workout pauses and the main action is not performed

#### Scenario: Return marks a set done
- **WHEN** the user presses Return during a set
- **THEN** the set is marked done

### Requirement: AMRAP round counting
With round counting on, the app SHALL count rounds across all blocks and offer a visible undo that removes the last counted round. With round counting off, a tap SHALL pause or resume as in any other phase without a main action.

#### Scenario: Undoing a round
- **WHEN** the user has counted 4 rounds and activates undo
- **THEN** the count becomes 3

#### Scenario: Nothing to undo
- **WHEN** the count is 0
- **THEN** undo has no effect

### Requirement: For Time splits
For Time SHALL treat each main action as the end of a round and record the time taken for that round. Finish SHALL be a separate visible control so that recording a split cannot end the workout by accident.

#### Scenario: Recording a split
- **WHEN** the user taps at 2:10 and again at 4:30
- **THEN** the recorded round times are 2:10 and 2:20

### Requirement: Leaving the app
On iPad, a running workout SHALL pause automatically when the app leaves the foreground. On Mac, a running workout SHALL keep running on time when its window is covered or another app is active.

#### Scenario: Switching apps on iPad
- **WHEN** the user switches to another app during a workout on iPad
- **THEN** the workout is paused when the user returns

#### Scenario: Covered window on Mac
- **WHEN** another app covers the window during a workout on Mac
- **THEN** the workout keeps running and its phases change on time

### Requirement: Workout summary
When a workout ends, the app SHALL show a summary with the workout time and any rounds or splits recorded, and offer to repeat the workout or return to setup. The summary SHALL NOT be saved.

#### Scenario: AMRAP summary
- **WHEN** an AMRAP with counted rounds ends
- **THEN** the summary shows the workout time and the rounds counted

#### Scenario: Repeating
- **WHEN** the user chooses to repeat from the summary
- **THEN** the same workout starts again from its get-ready countdown
