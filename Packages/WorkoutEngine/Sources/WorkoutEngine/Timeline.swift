/// One phase of a workout. Timed segments count down; user-ended segments count up.
public struct Segment: Equatable, Sendable {
    public enum Kind: Equatable, Sendable {
        case work, rest, getReady
    }

    public enum Ending: Equatable, Sendable {
        case afterDuration(Duration)
        case byUser(cap: Duration?)
    }

    public let kind: Kind
    public let ending: Ending
}

extension WorkoutConfiguration {
    /// The workout as a flat list of segments, excluding the get-ready countdown.
    public func timeline() -> [Segment] {
        switch self {
        case .timer(let duration):
            Self.countdown(duration)
        case .amrap(let block, let blocks, let rest, _):
            Self.intervals(work: block, rest: rest, rounds: blocks)
        case .emom(let window, let exercises, let rounds, let rest):
            Self.emom(window: window, exercises: exercises, rounds: rounds, rest: rest)
        case .tabata(let rounds):
            Self.intervals(work: Self.tabataWork, rest: Self.tabataRest, rounds: rounds)
        case .intervals(let work, let rest, let rounds):
            Self.intervals(work: work, rest: rest, rounds: rounds)
        case .forTime(let cap):
            Self.countUp(cap: cap)
        case .stopwatch:
            Self.countUp(cap: nil)
        case .sets(let rest, let sets):
            Self.sets(rest: rest, sets: sets)
        }
    }

    /// The calculated total, or nil when the athlete decides when a phase ends.
    public var total: Duration? {
        var total = Duration.zero
        for segment in timeline() {
            guard case .afterDuration(let duration) = segment.ending else { return nil }
            total += duration
        }
        return total
    }

    private static func countdown(_ duration: Duration) -> [Segment] {
        [Segment(kind: .work, ending: .afterDuration(duration))]
    }

    private static func intervals(work: Duration, rest: Duration, rounds: Int) -> [Segment] {
        alternating(Segment(kind: .work, ending: .afterDuration(work)), rest: rest, count: rounds)
    }

    /// Rounds of back-to-back windows. A stored rest is ignored with one exercise,
    /// so a single-exercise EMOM never turns into intervals.
    private static func emom(window: Duration, exercises: Int, rounds: Int, rest: Duration) -> [Segment] {
        let windows = Array(repeating: Segment(kind: .work, ending: .afterDuration(window)), count: exercises)
        let restSegment = Segment(kind: .rest, ending: .afterDuration(rest))
        var segments: [Segment] = []
        for round in 0..<rounds {
            if round > 0 && exercises > 1 && rest > .zero { segments.append(restSegment) }
            segments += windows
        }
        return segments
    }

    private static func countUp(cap: Duration?) -> [Segment] {
        [Segment(kind: .work, ending: .byUser(cap: cap))]
    }

    private static func sets(rest: Duration, sets: Int) -> [Segment] {
        alternating(Segment(kind: .work, ending: .byUser(cap: nil)), rest: rest, count: sets)
    }

    /// Repeats `work` with rest only between repeats, and none when rest is zero.
    private static func alternating(_ work: Segment, rest: Duration, count: Int) -> [Segment] {
        let restSegment = Segment(kind: .rest, ending: .afterDuration(rest))
        var segments: [Segment] = []
        for index in 0..<count {
            if index > 0 && rest > .zero { segments.append(restSegment) }
            segments.append(work)
        }
        return segments
    }
}
