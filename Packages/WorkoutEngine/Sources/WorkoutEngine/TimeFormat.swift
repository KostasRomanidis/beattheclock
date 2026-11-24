/// How times read on screen, shared by setup, the live view and the summary.
public enum TimeFormat {
    /// Minutes and seconds, with hours only when needed. Countdowns round up,
    /// so they show 0:00 only when the phase ends. `hundredths` adds the whole
    /// hundredths cut off, never rounded, so a time never reads later than it is;
    /// it is for count-up times and not combined with `roundingUp`.
    public static func format(_ duration: Duration, roundingUp: Bool = false, hundredths: Bool = false) -> String {
        let (seconds, attoseconds) = max(duration, .zero).components
        let wholeSeconds = Int(seconds) + (roundingUp && attoseconds > 0 ? 1 : 0)
        let (hours, minutes, secondsPart) = (wholeSeconds / 3600, wholeSeconds / 60 % 60, wholeSeconds % 60)
        let paddedSeconds = secondsPart < 10 ? "0\(secondsPart)" : "\(secondsPart)"
        let time: String
        if hours > 0 {
            let paddedMinutes = minutes < 10 ? "0\(minutes)" : "\(minutes)"
            time = "\(hours):\(paddedMinutes):\(paddedSeconds)"
        } else {
            time = "\(minutes):\(paddedSeconds)"
        }
        return hundredths ? time + fraction(attoseconds) : time
    }

    /// The hundredths of a second in `attoseconds`, such as ".25".
    static func fraction(_ attoseconds: Int64) -> String {
        let hundredths = Int(attoseconds / 10_000_000_000_000_000)
        return hundredths < 10 ? ".0\(hundredths)" : ".\(hundredths)"
    }

    /// A preset in words: whole minutes as "12 min", zero as "None", otherwise seconds.
    public static func presetLabel(_ duration: Duration) -> String {
        let seconds = Int(duration.components.seconds)
        if seconds == 0 { return "None" }
        return seconds % 60 == 0 ? "\(seconds / 60) min" : "\(seconds) s"
    }
}
