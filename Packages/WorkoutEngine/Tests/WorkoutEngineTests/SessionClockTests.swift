import Testing
@testable import WorkoutEngine

private let start = ContinuousClock.now

private func at(_ seconds: Int) -> SessionClock.Instant { start + .seconds(seconds) }

@Suite struct SessionTime {
    @Test func timeExcludesEveryPause() {
        var clock = SessionClock(startingAt: start)
        clock.pause(at(5))
        clock.resume(at(20))
        clock.pause(at(25))
        clock.resume(at(100))

        #expect(clock.time(at(103)) == .seconds(13))
    }

    @Test func timeStopsWhilePaused() {
        var clock = SessionClock(startingAt: start)
        clock.pause(at(5))

        #expect(clock.time(at(50)) == .seconds(5))
    }

    @Test func pausingAgainKeepsTheFirstPause() {
        var clock = SessionClock(startingAt: start)
        clock.pause(at(5))
        clock.pause(at(9))

        #expect(clock.state == .paused(at: .seconds(5)))
    }

    @Test func pausingOrResumingAfterTheEndDoesNothing() {
        var clock = SessionClock(startingAt: start)
        clock.end(at: .seconds(5))
        clock.pause(at(9))
        clock.resume(at(10))

        #expect(clock.state == .ended(at: .seconds(5)))
        #expect(clock.time(at(20)) == .seconds(5))
    }

    @Test func resumingWhileRunningDoesNothing() {
        var clock = SessionClock(startingAt: start)
        clock.resume(at(5))

        #expect(clock.time(at(7)) == .seconds(7))
    }
}
