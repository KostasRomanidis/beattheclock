import SwiftUI
import WorkoutEngine

/// One workout type's settings, a sentence saying what it will do and the shared get-ready choice.
struct SetupView: View {
    @Binding var configuration: WorkoutConfiguration
    @Binding var getReady: Duration
    let onStart: () -> Void
    /// The For Time cap to restore when its switch goes back on, for as long as this screen is open.
    @State private var lastCap = SetupLimits.defaultCap

    var body: some View {
        Form {
            Section {
                settings
            } footer: {
                Text(configuration.summary).font(.body)
            }
            Section {
                // A segmented picker hides its title, so the label is drawn above it.
                VStack(alignment: .leading) {
                    Text("Get ready")
                    Picker("Get ready", selection: $getReady) {
                        ForEach(SetupLimits.getReadyPresets, id: \.self) { preset in
                            Text(preset == .zero ? "Off" : "\(preset.components.seconds) s").tag(preset)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }
            }
            Section {
                Button(action: onStart) {
                    Text("Start").font(.title3.weight(.semibold)).frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)
            }
        }
        .formStyle(.grouped)
        .navigationTitle(configuration.name)
    }

    // Each binding rebuilds the case from the values of this render, changing one field.
    @ViewBuilder private var settings: some View {
        switch configuration {
        case .timer(let duration):
            DurationStepper("Duration", value: Binding(get: { duration }, set: { configuration = .timer(duration: $0) }),
                            presets: SetupLimits.durationPresets)

        case .amrap(let block, let blocks, let rest, let countsRounds):
            DurationStepper("Duration", value: Binding(get: { block }, set: {
                configuration = .amrap(block: $0, blocks: blocks, rest: rest, countsRounds: countsRounds)
            }), presets: SetupLimits.durationPresets)
            CountStepper("Blocks", value: Binding(get: { blocks }, set: {
                configuration = .amrap(block: block, blocks: $0, rest: rest, countsRounds: countsRounds)
            }), presets: SetupLimits.blockPresets)
            if blocks > 1 {
                DurationStepper("Rest", value: Binding(get: { rest }, set: {
                    configuration = .amrap(block: block, blocks: blocks, rest: $0, countsRounds: countsRounds)
                }), minimum: SetupLimits.minimumRest, presets: SetupLimits.longRestPresets)
            }
            Toggle("Count rounds", isOn: Binding(get: { countsRounds }, set: {
                configuration = .amrap(block: block, blocks: blocks, rest: rest, countsRounds: $0)
            }))

        case .emom(let window, let exercises, let rounds, let rest):
            DurationStepper("Every", value: Binding(get: { window }, set: {
                configuration = .emom(window: $0, exercises: exercises, rounds: rounds, rest: rest)
            }), presets: SetupLimits.windowPresets)
            CountStepper("Exercises", value: Binding(get: { exercises }, set: {
                configuration = .emom(window: window, exercises: $0, rounds: rounds, rest: rest)
            }), presets: SetupLimits.exercisePresets)
            CountStepper("Rounds", value: Binding(get: { rounds }, set: {
                configuration = .emom(window: window, exercises: exercises, rounds: $0, rest: rest)
            }), presets: SetupLimits.roundPresets)
            if exercises > 1 {
                DurationStepper("Rest", value: Binding(get: { rest }, set: {
                    configuration = .emom(window: window, exercises: exercises, rounds: rounds, rest: $0)
                }), minimum: SetupLimits.minimumRest, presets: SetupLimits.longRestPresets)
            }

        case .tabata(let rounds):
            LabeledContent("Work", value: SessionDisplay.format(WorkoutConfiguration.tabataWork))
            LabeledContent("Rest", value: SessionDisplay.format(WorkoutConfiguration.tabataRest))
            CountStepper("Rounds", value: Binding(get: { rounds }, set: { configuration = .tabata(rounds: $0) }),
                         presets: SetupLimits.roundPresets)

        case .intervals(let work, let rest, let rounds):
            DurationStepper("Work", value: Binding(get: { work }, set: {
                configuration = .intervals(work: $0, rest: rest, rounds: rounds)
            }), presets: SetupLimits.workPresets)
            DurationStepper("Rest", value: Binding(get: { rest }, set: {
                configuration = .intervals(work: work, rest: $0, rounds: rounds)
            }), minimum: SetupLimits.minimumRest, presets: SetupLimits.restPresets)
            CountStepper("Rounds", value: Binding(get: { rounds }, set: {
                configuration = .intervals(work: work, rest: rest, rounds: $0)
            }), presets: SetupLimits.roundPresets)

        case .forTime(let cap):
            // Switching the cap off keeps its value, so switching it back on restores it.
            Toggle(isOn: Binding(get: { cap != nil }, set: {
                if !$0, let cap { lastCap = cap }
                configuration = .forTime(cap: $0 ? lastCap : nil)
            })) {
                VStack(alignment: .leading) {
                    Text("Time cap")
                    if cap == nil { Text("No cap").font(.caption).foregroundStyle(.secondary) }
                }
            }
            if let cap {
                DurationStepper("Time cap", value: Binding(get: { cap }, set: { configuration = .forTime(cap: $0) }),
                                presets: SetupLimits.capPresets)
            }

        case .stopwatch:
            EmptyView()

        case .sets(let rest, let sets):
            DurationStepper("Rest", value: Binding(get: { rest }, set: {
                configuration = .sets(rest: $0, sets: sets)
            }), minimum: SetupLimits.minimumRest, presets: SetupLimits.longRestPresets)
            CountStepper("Sets", value: Binding(get: { sets }, set: { configuration = .sets(rest: rest, sets: $0) }),
                         presets: SetupLimits.setPresets)
        }
    }
}

private struct DurationStepper: View {
    let title: String
    @Binding var value: Duration
    let minimum: Duration
    let presets: [Duration]

    init(_ title: String, value: Binding<Duration>, minimum: Duration = SetupLimits.minimumDuration, presets: [Duration]) {
        self.title = title
        self._value = value
        self.minimum = minimum
        self.presets = presets
    }

    var body: some View {
        VStack(alignment: .leading) {
            // A nil action disables that button, so the limit is visible like the count steppers.
            Stepper(
                // Only a rest can reach zero, so zero always reads as no rest.
                label: { LabeledContent(title, value: value == .zero ? "None" : SessionDisplay.format(value)) },
                onIncrement: value < SetupLimits.maximumDuration ? { value = SetupLimits.stepUp(value) } : nil,
                onDecrement: value > minimum ? { value = SetupLimits.stepDown(value, minimum: minimum) } : nil
            )
            PresetRow(title: title, values: presets, selection: $value) { SessionDisplay.presetLabel($0) }
        }
    }
}

private struct CountStepper: View {
    let title: String
    @Binding var value: Int
    let presets: [Int]

    init(_ title: String, value: Binding<Int>, presets: [Int]) {
        self.title = title
        self._value = value
        self.presets = presets
    }

    var body: some View {
        VStack(alignment: .leading) {
            Stepper(value: $value, in: SetupLimits.counts) {
                LabeledContent(title, value: "\(value)")
            }
            PresetRow(title: title, values: presets, selection: $value) { "\($0)" }
        }
    }
}

/// Common values one tap away. A custom stepper value simply leaves none selected.
private struct PresetRow<Value: Hashable>: View {
    let title: String
    let values: [Value]
    @Binding var selection: Value
    let label: (Value) -> String

    var body: some View {
        // Scrolls rather than squeezing in a narrow Split View window.
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(values, id: \.self) { value in
                    // Bordered styles also keep each button separately tappable inside a form row.
                    if value == selection {
                        chip(value).buttonStyle(.borderedProminent)
                    } else {
                        chip(value).buttonStyle(.bordered)
                    }
                }
            }
        }
        #if os(macOS)
        .controlSize(.small)
        #endif
    }

    private func chip(_ value: Value) -> some View {
        Button(label(value)) { selection = value }
            .monospacedDigit()
            .accessibilityLabel("\(title), \(label(value))")
            .accessibilityAddTraits(value == selection ? .isSelected : [])
    }
}

extension WorkoutConfiguration {
    /// What the workout will do, with its total when the length is known.
    var summary: String {
        let total = total.map { Self.format($0) } ?? ""
        switch self {
        case .timer(let duration):
            return "Counts down from \(Self.format(duration))."
        case .amrap(let block, let blocks, let rest, let countsRounds):
            let plan = if blocks == 1 {
                "As many rounds as possible in \(Self.format(block))."
            } else if rest == .zero {
                "\(Self.count(blocks, "block")) of \(Self.format(block)) back to back, \(total) in total."
            } else {
                "\(Self.count(blocks, "block")) of \(Self.format(block)) with \(Self.format(rest)) rest between, \(total) in total."
            }
            return countsRounds ? plan + " Count each round as you go." : plan
        case .emom(let window, let exercises, let rounds, let rest):
            guard exercises > 1 else {
                return "A new round starts every \(Self.format(window)) for \(Self.count(rounds, "round")), \(total) in total."
            }
            let plan = "\(Self.count(rounds, "round")) of \(exercises) exercises, a new one every \(Self.format(window))"
            if rounds == 1 { return "\(plan). \(total) in total." }
            if rest == .zero { return "\(plan) with no rest. \(total) in total." }
            return "\(plan), with \(Self.format(rest)) rest between rounds. \(total) in total."
        case .tabata(let rounds):
            return Self.intervals(work: Self.tabataWork, rest: Self.tabataRest, rounds: rounds, total: total)
        case .intervals(let work, let rest, let rounds):
            return Self.intervals(work: work, rest: rest, rounds: rounds, total: total)
        case .forTime(let cap):
            return cap.map { "Counts up until you finish or \(Self.format($0)) runs out." } ?? "Counts up until you finish."
        case .stopwatch:
            return "Counts up until you finish."
        case .sets(let rest, let sets):
            if sets == 1 { return "1 set. Mark it done when you finish." }
            if rest == .zero { return "\(sets) sets back to back. Mark each set done as you finish it." }
            return "\(sets) sets with \(Self.format(rest)) rest between. Mark a set done to start the rest."
        }
    }

    private static func intervals(work: Duration, rest: Duration, rounds: Int, total: String) -> String {
        let work = "\(count(rounds, "round")) of \(format(work)) work"
        if rounds == 1 { return "\(work), \(total) in total." }
        if rest == .zero { return "\(work) back to back, \(total) in total." }
        return "\(work) and \(format(rest)) rest, \(total) in total."
    }

    private static func count(_ value: Int, _ noun: String) -> String {
        value == 1 ? "1 \(noun)" : "\(value) \(noun)s"
    }

    private static func format(_ duration: Duration) -> String {
        SessionDisplay.format(duration)
    }
}

#Preview {
    NavigationStack {
        SetupView(configuration: .constant(WorkoutConfiguration.defaults[4]), getReady: .constant(.seconds(10))) {}
    }
}
