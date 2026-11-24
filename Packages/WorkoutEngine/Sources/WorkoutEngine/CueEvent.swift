/// A sound the app should play, reported by `Session.update` at the moment it is due.
public enum CueEvent: Equatable, Sendable {
    case tick, workStart, restStart, finish
}
