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

@Suite struct SetupPresets {
    @Test func presetsStayWithinLimits() {
        let durations = SetupLimits.durationPresets + SetupLimits.capPresets + SetupLimits.windowPresets + SetupLimits.workPresets
        #expect(durations.allSatisfy { $0 >= SetupLimits.minimumDuration && $0 <= SetupLimits.maximumDuration })
        let rests = SetupLimits.restPresets + SetupLimits.longRestPresets
        #expect(rests.allSatisfy { $0 >= SetupLimits.minimumRest && $0 <= SetupLimits.maximumDuration })
        let counts = SetupLimits.roundPresets + SetupLimits.blockPresets + SetupLimits.setPresets
        #expect(counts.allSatisfy(SetupLimits.counts.contains))
    }

    @Test func everyDefaultIsAPreset() {
        for configuration in WorkoutConfiguration.defaults {
            switch configuration {
            case .timer(let duration):
                #expect(SetupLimits.durationPresets.contains(duration))
            case .amrap(let block, let blocks, let rest, _):
                #expect(SetupLimits.durationPresets.contains(block))
                #expect(SetupLimits.blockPresets.contains(blocks))
                #expect(SetupLimits.longRestPresets.contains(rest))
            case .emom(let window, let rounds):
                #expect(SetupLimits.windowPresets.contains(window))
                #expect(SetupLimits.roundPresets.contains(rounds))
            case .tabata(let rounds):
                #expect(SetupLimits.roundPresets.contains(rounds))
            case .intervals(let work, let rest, let rounds):
                #expect(SetupLimits.workPresets.contains(work))
                #expect(SetupLimits.restPresets.contains(rest))
                #expect(SetupLimits.roundPresets.contains(rounds))
            case .forTime:
                #expect(SetupLimits.capPresets.contains(SetupLimits.defaultCap))
            case .stopwatch:
                break
            case .sets(let rest, let sets):
                #expect(SetupLimits.longRestPresets.contains(rest))
                #expect(SetupLimits.setPresets.contains(sets))
            }
        }
    }
}
