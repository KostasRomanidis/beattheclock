import SwiftUI
import WorkoutEngine

/// One workout type's settings, its calculated total and the shared get-ready choice.
struct SetupView: View {
    @Binding var configuration: WorkoutConfiguration
    @Binding var getReady: Duration

    var body: some View {
        Form {
            Section { settings }
            if let total = configuration.total {
                Section {
                    LabeledContent("Total", value: SessionDisplay.format(total))
                }
            }
            Section {
                Picker("Get ready", selection: $getReady) {
                    ForEach(SetupLimits.getReadyPresets, id: \.self) { preset in
                        Text(preset == .zero ? "Off" : "\(preset.components.seconds) s").tag(preset)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
        .formStyle(.grouped)
        .navigationTitle(configuration.name)
    }

    // Each binding rebuilds the case from the values of this render, changing one field.
    @ViewBuilder private var settings: some View {
        switch configuration {
        case .timer(let duration):
            DurationStepper("Duration", value: Binding(get: { duration }, set: { configuration = .timer(duration: $0) }))

        case .amrap(let block, let blocks, let rest, let countsRounds):
            DurationStepper("Duration", value: Binding(get: { block }, set: {
                configuration = .amrap(block: $0, blocks: blocks, rest: rest, countsRounds: countsRounds)
            }))
            CountStepper("Blocks", value: Binding(get: { blocks }, set: {
                configuration = .amrap(block: block, blocks: $0, rest: rest, countsRounds: countsRounds)
            }))
            if blocks > 1 {
                DurationStepper("Rest", value: Binding(get: { rest }, set: {
                    configuration = .amrap(block: block, blocks: blocks, rest: $0, countsRounds: countsRounds)
                }), minimum: SetupLimits.minimumRest)
            }
            Toggle("Count rounds", isOn: Binding(get: { countsRounds }, set: {
                configuration = .amrap(block: block, blocks: blocks, rest: rest, countsRounds: $0)
            }))

        case .emom(let window, let rounds):
            DurationStepper("Every", value: Binding(get: { window }, set: { configuration = .emom(window: $0, rounds: rounds) }))
            CountStepper("Rounds", value: Binding(get: { rounds }, set: { configuration = .emom(window: window, rounds: $0) }))

        case .tabata(let rounds):
            LabeledContent("Work", value: SessionDisplay.format(WorkoutConfiguration.tabataWork))
            LabeledContent("Rest", value: SessionDisplay.format(WorkoutConfiguration.tabataRest))
            CountStepper("Rounds", value: Binding(get: { rounds }, set: { configuration = .tabata(rounds: $0) }))

        case .intervals(let work, let rest, let rounds):
            DurationStepper("Work", value: Binding(get: { work }, set: {
                configuration = .intervals(work: $0, rest: rest, rounds: rounds)
            }))
            DurationStepper("Rest", value: Binding(get: { rest }, set: {
                configuration = .intervals(work: work, rest: $0, rounds: rounds)
            }), minimum: SetupLimits.minimumRest)
            CountStepper("Rounds", value: Binding(get: { rounds }, set: {
                configuration = .intervals(work: work, rest: rest, rounds: $0)
            }))

        case .forTime(let cap):
            Toggle("Time cap", isOn: Binding(get: { cap != nil }, set: {
                configuration = .forTime(cap: $0 ? SetupLimits.defaultCap : nil)
            }))
            if let cap {
                DurationStepper("Cap", value: Binding(get: { cap }, set: { configuration = .forTime(cap: $0) }))
            }

        case .stopwatch:
            Text("No settings. Start and finish when you are done.")
                .foregroundStyle(.secondary)

        case .sets(let rest, let sets):
            DurationStepper("Rest", value: Binding(get: { rest }, set: {
                configuration = .sets(rest: $0, sets: sets)
            }), minimum: SetupLimits.minimumRest)
            CountStepper("Sets", value: Binding(get: { sets }, set: { configuration = .sets(rest: rest, sets: $0) }))
        }
    }
}

private struct DurationStepper: View {
    let title: String
    @Binding var value: Duration
    let minimum: Duration

    init(_ title: String, value: Binding<Duration>, minimum: Duration = SetupLimits.minimumDuration) {
        self.title = title
        self._value = value
        self.minimum = minimum
    }

    var body: some View {
        Stepper {
            LabeledContent(title, value: SessionDisplay.format(value))
        } onIncrement: {
            value = SetupLimits.stepUp(value)
        } onDecrement: {
            value = SetupLimits.stepDown(value, minimum: minimum)
        }
    }
}

private struct CountStepper: View {
    let title: String
    @Binding var value: Int

    init(_ title: String, value: Binding<Int>) {
        self.title = title
        self._value = value
    }

    var body: some View {
        Stepper(value: $value, in: SetupLimits.counts) {
            LabeledContent(title, value: "\(value)")
        }
    }
}

#Preview {
    NavigationStack {
        SetupView(configuration: .constant(WorkoutConfiguration.defaults[4]), getReady: .constant(.seconds(10)))
    }
}
