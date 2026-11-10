import SwiftUI
import WorkoutEngine

/// The full-screen live workout, then its summary.
struct SessionView: View {
    let controller: SessionController
    let onExit: () -> Void
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if controller.session.status == .finished {
                SummaryView(session: controller.session, onRepeat: controller.restart, onExit: onExit)
            } else {
                LiveView(controller: controller)
            }
        }
        .task { await controller.run() }
        #if os(iOS)
        // The iPad cannot keep time in the background, so pause on leaving the foreground.
        // The Mac keeps running when covered or inactive.
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { controller.perform { $0.pause($1) } }
        }
        #endif
    }
}

private struct LiveView: View {
    let controller: SessionController
    @FocusState private var focused: Bool

    private var display: SessionDisplay { controller.display }
    private var session: Session { controller.session }
    private var palette: Palette { Palette(display.state) }

    var body: some View {
        VStack(spacing: 16) {
            header
            mainNumber
            footer
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { background.ignoresSafeArea() }
        .foregroundStyle(palette.text)
        .contentShape(.rect)
        // Exclusive, so a hold never also counts as a tap.
        .gesture(
            LongPressGesture(minimumDuration: 0.6)
                .onEnded { _ in controller.perform { $0.hold($1) } }
                .exclusively(before: TapGesture().onEnded { controller.perform { $0.tap($1) } })
        )
        .focusable()
        .focused($focused)
        .focusEffectDisabled()
        .onAppear { focused = true }
        .onKeyPress(keys: [.space, .return, .delete, .escape, "f"]) { press in
            handle(press.key)
            return .handled
        }
        .persistentSystemOverlays(.hidden)
    }

    private var background: some View {
        palette.background.overlay(alignment: .bottom) {
            if let progress = display.phaseProgress, display.state != .paused {
                GeometryReader { geometry in
                    Color.black.opacity(Palette.drainOpacity)
                        .frame(height: geometry.size.height * progress)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            if let progress = display.workoutProgress {
                ProgressView(value: progress)
                    .tint(palette.text)
                    .accessibilityLabel("Workout progress")
            }
            HStack {
                Text(display.label).font(.largeTitle.weight(.heavy))
                Spacer()
                if let total = display.secondaryTotal {
                    Text(total).font(.largeTitle.weight(.semibold)).monospacedDigit()
                }
            }
            .accessibilityElement(children: .combine)
        }
    }

    private var mainNumber: some View {
        Text(display.mainTime)
            .font(.system(size: 1000, weight: .heavy, design: .rounded))
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.01)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityLabel("\(display.label), \(display.mainTime)")
            .accessibilityAddTraits(.isButton)
            .accessibilityHint(tapHint)
            .accessibilityAction { controller.perform { $0.tap($1) } }
    }

    private var footer: some View {
        HStack(alignment: .bottom, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                if let position = display.position { Text(position) }
                if let next = display.nextPhase { Text(next).opacity(0.85) }
            }
            .font(.title.weight(.semibold))
            .monospacedDigit()
            .accessibilityElement(children: .combine)
            Spacer()
            controls
        }
    }

    @ViewBuilder private var controls: some View {
        Group {
            if session.status == .paused {
                Button("End Workout") { controller.perform { session, _ in session.endWorkout() } }
                Button("Resume") { controller.perform { $0.resume($1) } }
            } else {
                if session.configuration.countsRounds {
                    Button { controller.perform { session, _ in session.undoRound() } } label: {
                        Label("Undo last round", systemImage: "arrow.uturn.backward")
                    }
                    .disabled(session.roundsCounted == 0)
                }
                if session.canFinish {
                    Button("Finish") { controller.perform { $0.finish($1) } }
                }
            }
        }
        .font(.title2.weight(.semibold))
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .tint(palette.text)
        .foregroundStyle(palette.background)
    }

    private var tapHint: String {
        switch session.availableAction {
        case .countRound: "Counts a round"
        case .split: "Records the round time"
        case .setDone: "Marks the set done"
        case nil where session.isInGetReady: "Skips the countdown"
        case nil: session.status == .paused ? "Resumes the workout" : "Pauses the workout"
        }
    }

    private func handle(_ key: KeyEquivalent) {
        switch key {
        case .space: controller.perform { $0.togglePause($1) }
        case .return: controller.perform { $0.mainAction($1) }
        case .delete: controller.perform { session, _ in session.undoRound() }
        case .escape: controller.perform { session, _ in session.endWorkout() }
        case "f": controller.perform { $0.finish($1) }
        default: break
        }
    }
}

/// Full-screen colours per state. Each text colour is at least 5.5:1 against its
/// background, including where the drain darkens it.
private struct Palette {
    static let drainOpacity = 0.2

    private static let nearBlack = Color(red: 0x11 / 255, green: 0x11 / 255, blue: 0x11 / 255)

    let background: Color
    let text: Color

    init(_ state: SessionDisplay.State) {
        switch state {
        case .getReady: (background, text) = (Color(red: 1, green: 0xB0 / 255, blue: 0), Self.nearBlack)
        case .work: (background, text) = (Color(red: 0x34 / 255, green: 0xC7 / 255, blue: 0x59 / 255), Self.nearBlack)
        case .rest: (background, text) = (Color(red: 0x1D / 255, green: 0x5F / 255, blue: 0xC4 / 255), .white)
        case .finalSeconds: (background, text) = (Color(red: 0xC6 / 255, green: 0x28 / 255, blue: 0x28 / 255), .white)
        case .paused, .finished: (background, text) = (Color(red: 0x2C / 255, green: 0x2C / 255, blue: 0x2E / 255), .white)
        }
    }
}

private struct SummaryView: View {
    let session: Session
    let onRepeat: () -> Void
    let onExit: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text(session.configuration.name).font(.largeTitle.weight(.bold))
            Text(SessionDisplay.format(session.workoutTime(.now)))
                .font(.system(size: 96, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .accessibilityLabel("Workout time \(SessionDisplay.format(session.workoutTime(.now)))")
            VStack(spacing: 8) {
                if session.configuration.countsRounds {
                    LabeledContent("Rounds", value: "\(session.roundsCounted)")
                }
                ForEach(Array(session.splits.enumerated()), id: \.offset) { index, split in
                    LabeledContent("Round \(index + 1)", value: SessionDisplay.format(split))
                }
            }
            .font(.title2)
            .monospacedDigit()
            .frame(maxWidth: 320)
            HStack(spacing: 16) {
                Button("Back to Setup", action: onExit)
                Button("Repeat", action: onRepeat)
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
            }
            .controlSize(.large)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
