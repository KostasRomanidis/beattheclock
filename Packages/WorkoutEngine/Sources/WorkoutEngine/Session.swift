/// A sound the app should play, reported by `Session.update` at the moment it is due.
public enum CueEvent: Equatable, Sendable {
    case tick, workStart, restStart, finish
}

/// A running workout. It has no clock of its own: every operation takes the current time,
/// so elapsed time is always measured from stored instants and never drifts.
public struct Session: Sendable {
    public typealias Instant = ContinuousClock.Instant

    public enum Status: Equatable, Sendable {
        case running, paused, finished
    }

    public enum MainAction: Equatable, Sendable {
        case countRound, split, setDone
    }

    static let finalSecondsTicks: [Duration] = [.seconds(3), .seconds(2), .seconds(1)]
    static let staleCueLimit: Duration = .seconds(1)

    public let configuration: WorkoutConfiguration
    public let segments: [Segment]
    public private(set) var status: Status = .running
    public private(set) var segmentIndex = 0
    public private(set) var roundsCounted = 0
    public private(set) var splits: [Duration] = []

    private var segmentStart: Instant
    private var workoutStart: Instant?
    private var pausedAt: Instant?
    private var endedAt: Instant?
    private var cueCursor: Instant
    private var pendingCues: [TimedCue] = []

    private struct TimedCue: Sendable {
        var moment: Instant
        let cue: CueEvent
    }

    /// Starts the workout at `now`, beginning with get-ready unless `getReady` is zero.
    public init(configuration: WorkoutConfiguration, getReady: Duration, startingAt now: Instant) {
        let getReadySegments = getReady > .zero ? [Segment(kind: .getReady, ending: .afterDuration(getReady))] : []
        self.configuration = configuration
        self.segments = getReadySegments + configuration.timeline()
        self.segmentStart = now
        self.cueCursor = now
        begin(0, at: now)
    }

    public var currentSegment: Segment { segments[segmentIndex] }

    public var isInGetReady: Bool { currentSegment.kind == .getReady }

    /// The action a tap or Return performs right now, if the phase has one.
    public var availableAction: MainAction? {
        guard status == .running, currentSegment.kind == .work else { return nil }
        switch configuration {
        case .amrap(_, _, _, let countsRounds): return countsRounds ? .countRound : nil
        case .forTime: return .split
        case .sets: return .setDone
        case .timer, .emom, .tabata, .intervals, .stopwatch: return nil
        }
    }

    /// Whether Finish can end the workout now: For Time and Stopwatch, once past get-ready.
    public var canFinish: Bool {
        guard status == .running, currentSegment.kind == .work else { return false }
        switch configuration {
        case .forTime, .stopwatch: return true
        case .timer, .amrap, .emom, .tabata, .intervals, .sets: return false
        }
    }

    // MARK: Time

    public func elapsedInSegment(_ now: Instant) -> Duration {
        frozen(now) - segmentStart
    }

    /// Time left in the current phase, or nil for a phase that counts up.
    public func timeLeftInSegment(_ now: Instant) -> Duration? {
        currentSegment.countdownDuration.map { $0 - elapsedInSegment(now) }
    }

    /// Workout time so far, excluding get-ready and pauses.
    public func workoutTime(_ now: Instant) -> Duration {
        guard let workoutStart else { return .zero }
        return frozen(now) - workoutStart
    }

    /// Advances through every phase boundary passed by `now` and returns the cues due since
    /// the previous update, dropping any more than a second late.
    public mutating func update(_ now: Instant) -> [CueEvent] {
        guard status != .paused else { return [] }
        if status == .running { advance(to: now) }
        let due = pendingCues.filter { now - $0.moment <= Self.staleCueLimit }.map(\.cue)
        pendingCues = []
        cueCursor = now
        return due
    }

    // MARK: Controls

    public mutating func pause(_ now: Instant) {
        guard status == .running else { return }
        pausedAt = now
        status = .paused
    }

    public mutating func resume(_ now: Instant) {
        guard status == .paused, let pausedAt else { return }
        let pause = now - pausedAt
        segmentStart += pause
        workoutStart? += pause
        cueCursor += pause
        for index in pendingCues.indices { pendingCues[index].moment += pause }
        self.pausedAt = nil
        status = .running
    }

    /// Space bar: skips get-ready, otherwise pauses or resumes.
    public mutating func togglePause(_ now: Instant) {
        switch status {
        case .running where isInGetReady: skipGetReady(now)
        case .running: pause(now)
        case .paused: resume(now)
        case .finished: break
        }
    }

    /// Press and hold: pauses or resumes in any phase, never performing the main action.
    public mutating func hold(_ now: Instant) {
        if status == .paused {
            resume(now)
        } else {
            pause(now)
        }
    }

    /// Tap or click: the phase's main action if it has one, otherwise the same as the space bar.
    public mutating func tap(_ now: Instant) {
        if availableAction != nil {
            mainAction(now)
        } else {
            togglePause(now)
        }
    }

    public mutating func skipGetReady(_ now: Instant) {
        guard status == .running, isInGetReady else { return }
        beginNext(at: now)
    }

    public mutating func mainAction(_ now: Instant) {
        switch availableAction {
        case .countRound: roundsCounted += 1
        case .split: splits.append(workoutTime(now) - splits.reduce(.zero, +))
        case .setDone: beginNext(at: now)
        case nil: break
        }
    }

    public mutating func undoRound() {
        guard roundsCounted > 0 else { return }
        roundsCounted -= 1
    }

    public mutating func finish(_ now: Instant) {
        guard canFinish else { return }
        end(at: now)
    }

    /// End Workout from the paused state, keeping the workout time reached when paused.
    public mutating func endWorkout() {
        guard status == .paused, let pausedAt else { return }
        endedAt = pausedAt
        status = .finished
    }

    // MARK: Private

    /// The time to measure against: stopped while paused or after the end.
    private func frozen(_ now: Instant) -> Instant {
        endedAt ?? pausedAt ?? now
    }

    private mutating func advance(to now: Instant) {
        while status == .running {
            if let countdown = currentSegment.countdownDuration {
                queueTicks(endingAt: segmentStart + countdown, upTo: now)
            }
            guard let limit = currentSegment.limit, now - segmentStart >= limit else { return }
            // The next phase starts when this one should have ended, so a late update loses no time.
            beginNext(at: segmentStart + limit)
        }
    }

    private mutating func queueTicks(endingAt end: Instant, upTo now: Instant) {
        for secondsLeft in Self.finalSecondsTicks {
            let moment = end - secondsLeft
            if moment > segmentStart && moment > cueCursor && moment <= now {
                pendingCues.append(TimedCue(moment: moment, cue: .tick))
            }
        }
    }

    private mutating func beginNext(at moment: Instant) {
        if segmentIndex + 1 < segments.count {
            begin(segmentIndex + 1, at: moment)
        } else {
            end(at: moment)
        }
    }

    private mutating func begin(_ index: Int, at moment: Instant) {
        segmentIndex = index
        segmentStart = moment
        switch currentSegment.kind {
        case .getReady:
            break
        case .work:
            if workoutStart == nil { workoutStart = moment }
            pendingCues.append(TimedCue(moment: moment, cue: .workStart))
        case .rest:
            pendingCues.append(TimedCue(moment: moment, cue: .restStart))
        }
    }

    private mutating func end(at moment: Instant) {
        endedAt = moment
        status = .finished
        pendingCues.append(TimedCue(moment: moment, cue: .finish))
    }
}

extension Segment {
    /// How long a timed phase runs, or nil when it counts up.
    var countdownDuration: Duration? {
        guard case .afterDuration(let duration) = ending else { return nil }
        return duration
    }

    /// When the phase ends on its own: its duration, or the cap of a count-up phase.
    var limit: Duration? {
        switch ending {
        case .afterDuration(let duration): duration
        case .byUser(let cap): cap
        }
    }
}
