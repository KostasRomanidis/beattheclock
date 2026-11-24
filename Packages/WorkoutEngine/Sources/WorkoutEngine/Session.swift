/// A running workout. It has no clock of its own: every operation takes the current time,
/// so elapsed time is always measured from stored instants and never drifts.
public struct Session: Sendable {
    public typealias Instant = ContinuousClock.Instant

    public enum Status: Equatable, Sendable {
        case running, paused, finished
    }

    /// The plan being run, after get-ready if there is one.
    public let plan: WorkoutPlan
    private(set) var phaseIndex = 0
    public private(set) var roundsCounted = 0
    public private(set) var splits: [Duration] = []

    private var clock: SessionClock
    private var cues = CueQueue()
    // In session time, which excludes pauses.
    private var phaseStart: Duration = .zero
    private var workoutStart: Duration?

    /// Starts the workout at `now`, beginning with get-ready unless `getReady` is zero.
    public init(plan: WorkoutPlan, getReady: Duration, startingAt now: Instant) {
        self.plan = plan.starting(with: getReady)
        self.clock = SessionClock(startingAt: now)
        begin(0, at: .zero)
    }

    public var status: Status {
        switch clock.state {
        case .running: .running
        case .paused: .paused
        case .ended: .finished
        }
    }

    public var currentPhase: Phase { plan.phases[phaseIndex] }

    public var isInGetReady: Bool { currentPhase.kind == .getReady }

    /// The action a tap or Return performs right now, if the phase has one.
    public var availableAction: Phase.MainAction? {
        status == .running ? currentPhase.mainAction : nil
    }

    /// Whether Finish can end the workout now: For Time and Stopwatch, once past get-ready.
    public var canFinish: Bool {
        status == .running && currentPhase.canFinish
    }

    // MARK: Time

    public func elapsedInPhase(_ now: Instant) -> Duration {
        clock.time(now) - phaseStart
    }

    /// Time left in the current phase, or nil for a phase that counts up.
    public func timeLeftInPhase(_ now: Instant) -> Duration? {
        currentPhase.countdownDuration.map { $0 - elapsedInPhase(now) }
    }

    /// Workout time so far, excluding get-ready and pauses.
    public func workoutTime(_ now: Instant) -> Duration {
        guard let workoutStart else { return .zero }
        return clock.time(now) - workoutStart
    }

    /// Advances through every phase boundary passed by `now` and returns the cues due since
    /// the previous update, dropping any more than a second late.
    public mutating func update(_ now: Instant) -> [CueEvent] {
        guard status != .paused else { return [] }
        advance(to: now)
        return cues.takeDue(clock.timeIfRunning(now))
    }

    // MARK: Controls
    // Each advances first, so it acts on the phase at `now` and not the one at the last update.

    public mutating func pause(_ now: Instant) {
        advance(to: now)
        clock.pause(now)
    }

    public mutating func resume(_ now: Instant) {
        clock.resume(now)
    }

    /// Space bar: skips get-ready, otherwise pauses or resumes.
    public mutating func togglePause(_ now: Instant) {
        advance(to: now)
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
        advance(to: now)
        if availableAction != nil {
            mainAction(now)
        } else {
            togglePause(now)
        }
    }

    public mutating func skipGetReady(_ now: Instant) {
        advance(to: now)
        guard status == .running, isInGetReady else { return }
        beginNext(at: clock.time(now))
    }

    public mutating func mainAction(_ now: Instant) {
        advance(to: now)
        switch availableAction {
        case .countRound: roundsCounted += 1
        case .split: splits.append(workoutTime(now) - splits.reduce(.zero, +))
        case .setDone: beginNext(at: clock.time(now))
        case nil: break
        }
    }

    public mutating func undoRound() {
        guard roundsCounted > 0 else { return }
        roundsCounted -= 1
    }

    public mutating func finish(_ now: Instant) {
        advance(to: now)
        guard canFinish else { return }
        end(at: clock.time(now))
    }

    /// End Workout from the paused state, keeping the workout time reached when paused.
    public mutating func endWorkout() {
        guard case .paused(let time) = clock.state else { return }
        clock.end(at: time)
        cues.cancelAll()
    }

    // MARK: Private

    private mutating func advance(to now: Instant) {
        while status == .running {
            guard let limit = currentPhase.limit, clock.time(now) - phaseStart >= limit else { return }
            // The next phase starts when this one should have ended, so a late update loses no time.
            beginNext(at: phaseStart + limit)
        }
    }

    private mutating func beginNext(at moment: Duration) {
        cues.cancel(after: moment)
        if phaseIndex + 1 < plan.phases.count {
            begin(phaseIndex + 1, at: moment)
        } else {
            end(at: moment)
        }
    }

    private mutating func begin(_ index: Int, at moment: Duration) {
        phaseIndex = index
        phaseStart = moment
        switch currentPhase.kind {
        case .getReady:
            break
        case .work:
            if workoutStart == nil { workoutStart = moment }
            cues.queue(.workStart, at: moment)
        case .rest:
            cues.queue(.restStart, at: moment)
        }
        if let countdown = currentPhase.countdownDuration {
            cues.queueTicks(from: moment, to: moment + countdown)
        }
    }

    private mutating func end(at moment: Duration) {
        clock.end(at: moment)
        cues.cancel(after: moment)
        cues.queue(.finish, at: moment)
    }
}
