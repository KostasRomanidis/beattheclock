# Spec Delta

## Purpose

Lets the user follow a workout by ear through distinct sounds at phase changes and in the final seconds, and keeps the device awake so the clock stays visible throughout.

## ADDED Requirements

### Requirement: Final seconds countdown cue
The app SHALL play a short tick at 3, 2 and 1 seconds before every countdown phase ends, including the get-ready countdown.

#### Scenario: End of a work phase
- **WHEN** a countdown phase reaches 3, 2 and then 1 seconds left
- **THEN** one tick plays at each of those moments

#### Scenario: Skipped get-ready
- **WHEN** the user skips the get-ready countdown before its final seconds
- **THEN** no ticks play for it

### Requirement: Phase change cues
The app SHALL play a distinct sound when work starts, when rest starts and when the workout finishes. In Sets, the work-start sound SHALL also signal that a rest has ended.

#### Scenario: Work starts
- **WHEN** a work phase, EMOM window or set begins
- **THEN** the work-start sound plays

#### Scenario: Rest starts
- **WHEN** a rest phase begins
- **THEN** the rest-start sound plays and is audibly different from the work-start sound

#### Scenario: Workout finishes
- **WHEN** a workout ends by running out of time or being finished by the user
- **THEN** the finish sound plays

### Requirement: Cues play exactly once and on time
Each cue SHALL play once, within 100 milliseconds of its moment. No cue SHALL play while paused. A cue whose moment was passed during a stall of more than one second SHALL be dropped rather than played late.

#### Scenario: Pausing during final seconds
- **WHEN** the user pauses with 2.5 seconds left and resumes later
- **THEN** the ticks for 2 and 1 seconds play after resuming and the tick for 3 seconds does not repeat

#### Scenario: Long stall
- **WHEN** updates stall for several seconds across a cue's moment
- **THEN** that cue does not play late

### Requirement: Works alongside music
Cues SHALL play over other audio without stopping it. Other audio SHALL keep playing when a workout starts, runs and ends. On iPad, cues SHALL play even when the device's silent setting is on.

#### Scenario: Music playing
- **WHEN** music is playing from another app during a workout
- **THEN** the music continues and the cues are heard over it

### Requirement: Screen stays awake
The device's display SHALL NOT sleep from inactivity during a workout, including while paused. Normal sleep behaviour SHALL return when the workout ends.

#### Scenario: Long phase without touching the device
- **WHEN** a phase runs for longer than the device's display sleep time
- **THEN** the screen stays on

#### Scenario: After the workout
- **WHEN** the workout has ended and the summary is showing
- **THEN** the device's normal sleep behaviour applies
