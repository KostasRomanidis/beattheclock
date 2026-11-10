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

    /// One-tap values offered under each setting; the stepper covers anything else.
    /// Each list holds its setting's default so a value is selected on first open.
    public static let durationPresets: [Duration] = minutes(3, 5, 10, 12, 15, 20)
    public static let capPresets: [Duration] = minutes(10, 15, 20, 25, 30)
    public static let windowPresets: [Duration] = [30, 60, 90, 120, 180].map { .seconds($0) }
    public static let workPresets: [Duration] = [20, 30, 40, 45, 60, 120].map { .seconds($0) }
    public static let restPresets: [Duration] = [0, 10, 15, 20, 30, 60].map { .seconds($0) }
    public static let longRestPresets: [Duration] = [30, 60, 90, 120, 180].map { .seconds($0) }
    public static let roundPresets = [4, 5, 8, 10, 12, 20]
    public static let blockPresets = [1, 2, 3, 4, 5]
    public static let setPresets = [3, 4, 5, 6, 8, 10]

    private static func minutes(_ values: Int...) -> [Duration] {
        values.map { .seconds($0 * 60) }
    }

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
