import Testing
@testable import WorkoutEngine

@Suite struct CueQueues {
    @Test func cuesWaitForTheirMomentAndAreReportedOnce() {
        var cues = CueQueue()
        cues.queue(.finish, at: .seconds(60))

        #expect(cues.takeDue(.seconds(1)) == [])
        #expect(cues.takeDue(.seconds(60)) == [.finish])
        #expect(cues.takeDue(.seconds(60)) == [])
    }

    @Test func cuesMoreThanASecondLateAreDropped() {
        var cues = CueQueue()
        cues.queue(.workStart, at: .seconds(5))
        cues.queue(.restStart, at: .seconds(6))

        #expect(cues.takeDue(.seconds(7)) == [.restStart])
    }

    @Test func ticksFallInTheFinalSeconds() {
        var cues = CueQueue()
        cues.queueTicks(from: .zero, to: .seconds(10))

        let reported = (0...10).filter { cues.takeDue(.seconds($0)) == [.tick] }

        #expect(reported == [7, 8, 9])
    }

    @Test func aPhaseAsShortAsTheFinalSecondsHasNoTickAtItsStart() {
        var cues = CueQueue()
        cues.queueTicks(from: .zero, to: .seconds(3))

        #expect(cues.takeDue(.zero) == [])
        #expect(cues.takeDue(.seconds(1)) == [.tick])
    }

    @Test func cancellingDropsOnlyWhatIsStillToCome() {
        var cues = CueQueue()
        cues.queueTicks(from: .zero, to: .seconds(10))
        cues.cancel(after: .seconds(7))

        #expect(cues.takeDue(.seconds(7)) == [.tick])
        #expect(cues.takeDue(.seconds(8)) == [])
    }
}
