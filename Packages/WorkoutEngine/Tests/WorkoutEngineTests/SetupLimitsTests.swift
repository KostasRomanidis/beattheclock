import Testing
@testable import WorkoutEngine

@Suite struct SetupSteps {
    @Test func stepsAreFinerForShortTimes() {
        #expect(SetupLimits.stepUp(.seconds(40)) == .seconds(45))
        #expect(SetupLimits.stepUp(.seconds(60)) == .seconds(75))
        #expect(SetupLimits.stepUp(.seconds(5 * 60)) == .seconds(6 * 60))
    }

    @Test func stepsDownMirrorStepsUp() {
        #expect(SetupLimits.stepDown(.seconds(45), minimum: .seconds(1)) == .seconds(40))
        #expect(SetupLimits.stepDown(.seconds(60), minimum: .seconds(1)) == .seconds(55))
        #expect(SetupLimits.stepDown(.seconds(5 * 60), minimum: .seconds(1)) == .seconds(285))
        #expect(SetupLimits.stepDown(.seconds(6 * 60), minimum: .seconds(1)) == .seconds(5 * 60))
    }

    @Test func offStepValuesSnapToTheStep() {
        #expect(SetupLimits.stepUp(.seconds(1)) == .seconds(5))
        #expect(SetupLimits.stepDown(.seconds(43), minimum: .seconds(1)) == .seconds(40))
    }

    @Test func workDurationsStopAtOneSecond() {
        #expect(SetupLimits.stepDown(.seconds(5), minimum: SetupLimits.minimumDuration) == .seconds(1))
        #expect(SetupLimits.stepDown(.seconds(1), minimum: SetupLimits.minimumDuration) == .seconds(1))
    }

    @Test func restCanReachZero() {
        #expect(SetupLimits.stepDown(.seconds(5), minimum: SetupLimits.minimumRest) == .zero)
        #expect(SetupLimits.stepDown(.zero, minimum: SetupLimits.minimumRest) == .zero)
    }

    @Test func durationsStopAtTheMaximum() {
        #expect(SetupLimits.stepUp(SetupLimits.maximumDuration) == SetupLimits.maximumDuration)
    }

    @Test func countsStartAtOne() {
        #expect(SetupLimits.counts.lowerBound == 1)
    }

    @Test func getReadyPresetsDefaultToTenSeconds() {
        #expect(SetupLimits.getReadyPresets == [.zero, .seconds(5), .seconds(10), .seconds(15), .seconds(30)])
        #expect(SetupLimits.defaultGetReady == .seconds(10))
    }
}
