# Spec Delta

## MODIFIED Requirements

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
