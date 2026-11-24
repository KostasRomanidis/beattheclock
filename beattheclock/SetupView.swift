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

    // Each binding reads and writes one type's current settings, so a control changes one of them in place.
    @ViewBuilder private var settings: some View {
        switch configuration {
        case .countdown(let countdown):
            let countdown = binding(countdown, WorkoutConfiguration.countdown) { if case .countdown(let current) = $0 { current } else { nil } }
            DurationStepper("Duration", value: countdown.duration, presets: SetupLimits.durationPresets)

        case .amrap(let amrap):
            let amrap = binding(amrap, WorkoutConfiguration.amrap) { if case .amrap(let current) = $0 { current } else { nil } }
            DurationStepper("Duration", value: amrap.block, presets: SetupLimits.durationPresets)
            CountStepper("Blocks", value: amrap.blocks, presets: SetupLimits.blockPresets)
            if amrap.wrappedValue.blocks > 1 {
                DurationStepper("Rest", value: amrap.rest, minimum: SetupLimits.minimumRest, presets: SetupLimits.longRestPresets)
            }
            Toggle("Count rounds", isOn: amrap.countsRounds)

        case .emom(let emom):
            let emom = binding(emom, WorkoutConfiguration.emom) { if case .emom(let current) = $0 { current } else { nil } }
            DurationStepper("Every", value: emom.window, presets: SetupLimits.windowPresets)
            CountStepper("Exercises", value: emom.exercises, presets: SetupLimits.exercisePresets)
            CountStepper("Rounds", value: emom.rounds, presets: SetupLimits.roundPresets)
            if emom.wrappedValue.exercises > 1 {
                DurationStepper("Rest", value: emom.rest, minimum: SetupLimits.minimumRest, presets: SetupLimits.longRestPresets)
            }

        case .tabata(let tabata):
            LabeledContent("Work", value: TimeFormat.format(Tabata.work))
            LabeledContent("Rest", value: TimeFormat.format(Tabata.rest))
            let tabata = binding(tabata, WorkoutConfiguration.tabata) { if case .tabata(let current) = $0 { current } else { nil } }
            CountStepper("Rounds", value: tabata.rounds, presets: SetupLimits.roundPresets)

        case .intervals(let intervals):
            let intervals = binding(intervals, WorkoutConfiguration.intervals) { if case .intervals(let current) = $0 { current } else { nil } }
            DurationStepper("Work", value: intervals.work, presets: SetupLimits.workPresets)
            DurationStepper("Rest", value: intervals.rest, minimum: SetupLimits.minimumRest, presets: SetupLimits.restPresets)
            CountStepper("Rounds", value: intervals.rounds, presets: SetupLimits.roundPresets)

        case .forTime(let forTime):
            let cap = binding(forTime, WorkoutConfiguration.forTime) { if case .forTime(let current) = $0 { current } else { nil } }.cap
            // Switching the cap off keeps its value, so switching it back on restores it.
            Toggle(isOn: Binding(get: { cap.wrappedValue != nil }, set: {
                if !$0, let current = cap.wrappedValue { lastCap = current }
                cap.wrappedValue = $0 ? lastCap : nil
            })) {
                VStack(alignment: .leading) {
                    Text("Time cap")
                    if forTime.cap == nil { Text("No cap").font(.caption).foregroundStyle(.secondary) }
                }
            }
            if let current = forTime.cap {
                DurationStepper("Time cap", value: Binding(get: { cap.wrappedValue ?? current }, set: { cap.wrappedValue = $0 }),
                                presets: SetupLimits.capPresets)
            }

        case .stopwatch:
            EmptyView()

        case .sets(let sets):
            let sets = binding(sets, WorkoutConfiguration.sets) { if case .sets(let current) = $0 { current } else { nil } }
            DurationStepper("Rest", value: sets.rest, minimum: SetupLimits.minimumRest, presets: SetupLimits.longRestPresets)
            CountStepper("Sets", value: sets.sets, presets: SetupLimits.setPresets)
        }
    }

    /// Reads the current settings, not this render's, so two changes before a redraw both count.
    private func binding<Settings>(
        _ rendered: Settings,
        _ wrap: @escaping (Settings) -> WorkoutConfiguration,
        unwrap: @escaping (WorkoutConfiguration) -> Settings?
    ) -> Binding<Settings> {
        Binding(get: { unwrap(configuration) ?? rendered }, set: { configuration = wrap($0) })
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
                label: { LabeledContent(title, value: value == .zero ? "None" : TimeFormat.format(value)) },
                onIncrement: value < SetupLimits.maximumDuration ? { value = SetupLimits.stepUp(value) } : nil,
                onDecrement: value > minimum ? { value = SetupLimits.stepDown(value, minimum: minimum) } : nil
            )
            PresetRow(title: title, values: presets, selection: $value) { TimeFormat.presetLabel($0) }
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
        case .countdown(let countdown):
            return "Counts down from \(Self.format(countdown.duration))."
        case .amrap(let amrap):
            let (block, blocks, rest) = (amrap.block, amrap.blocks, amrap.rest)
            let plan = if blocks == 1 {
                "As many rounds as possible in \(Self.format(block))."
            } else if rest == .zero {
                "\(Self.count(blocks, "block")) of \(Self.format(block)) back to back, \(total) in total."
            } else {
                "\(Self.count(blocks, "block")) of \(Self.format(block)) with \(Self.format(rest)) rest between, \(total) in total."
            }
            return amrap.countsRounds ? plan + " Count each round as you go." : plan
        case .emom(let emom):
            let (window, exercises, rounds, rest) = (emom.window, emom.exercises, emom.rounds, emom.rest)
            guard exercises > 1 else {
                return "A new round starts every \(Self.format(window)) for \(Self.count(rounds, "round")), \(total) in total."
            }
            let plan = "\(Self.count(rounds, "round")) of \(exercises) exercises, a new one every \(Self.format(window))"
            if rounds == 1 { return "\(plan). \(total) in total." }
            if rest == .zero { return "\(plan) with no rest. \(total) in total." }
            return "\(plan), with \(Self.format(rest)) rest between rounds. \(total) in total."
        case .tabata(let tabata):
            return Self.intervals(work: Tabata.work, rest: Tabata.rest, rounds: tabata.rounds, total: total)
        case .intervals(let intervals):
            return Self.intervals(work: intervals.work, rest: intervals.rest, rounds: intervals.rounds, total: total)
        case .forTime(let forTime):
            return forTime.cap.map { "Counts up until you finish or \(Self.format($0)) runs out." } ?? "Counts up until you finish."
        case .stopwatch:
            return "Counts up until you finish."
        case .sets(let workout):
            let (rest, sets) = (workout.rest, workout.sets)
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
        TimeFormat.format(duration)
    }
}

#Preview {
    NavigationStack {
        SetupView(configuration: .constant(.intervals(Intervals())), getReady: .constant(.seconds(10))) {}
    }
}
