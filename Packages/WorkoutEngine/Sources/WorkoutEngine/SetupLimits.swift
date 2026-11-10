/// The allowed ranges and steps for setup controls, so invalid settings cannot be entered.
public enum SetupLimits {
    /// Work, timer, window and cap durations.
    public static let minimumDuration: Duration = .seconds(1)
    public static let minimumRest: Duration = .zero
    public static let maximumDuration: Duration = .seconds(99 * 60 + 59)
    /// Rounds, blocks and sets.
    public static let counts: ClosedRange<Int> = 1...99

    public static let getReadyPresets: [Duration] = [.zero, .seconds(5), .seconds(10), .seconds(15), .seconds(30)]
    public static let defaultGetReady: Duration = .seconds(10)
    public static let defaultCap: Duration = .seconds(20 * 60)

    /// The next step up, snapping to the step so values stay round.
    public static func stepUp(_ duration: Duration) -> Duration {
        let seconds = wholeSeconds(duration)
        let step = step(for: seconds)
        return min(.seconds((seconds / step + 1) * step), maximumDuration)
    }

    /// The next step down, snapping to the step and never below `minimum`.
    public static func stepDown(_ duration: Duration, minimum: Duration) -> Duration {
        let seconds = wholeSeconds(duration)
        let step = step(for: seconds - 1)
        return max(.seconds((seconds - 1) / step * step), minimum)
    }

    /// Finer steps for short times, so both 0:15 and 12:00 are a few taps away.
    private static func step(for seconds: Int) -> Int {
        if seconds < 60 { return 5 }
        if seconds < 5 * 60 { return 15 }
        return 60
    }

    private static func wholeSeconds(_ duration: Duration) -> Int {
        Int(duration.components.seconds)
    }
}
