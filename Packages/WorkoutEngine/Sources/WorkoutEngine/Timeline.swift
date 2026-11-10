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
        case .emom(let window, let rounds):
            Self.intervals(work: window, rest: .zero, rounds: rounds)
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
