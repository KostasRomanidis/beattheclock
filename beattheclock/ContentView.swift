//
//  ContentView.swift
//  beattheclock
//
//  Created by Konstantinos Romanidis on 5/11/26.
//

import SwiftUI
import WorkoutEngine

/// The grid of workout types. Settings live here in memory only, so they last while the
/// app is open and return to their defaults on the next launch.
struct ContentView: View {
    @State private var configurations = WorkoutConfiguration.defaults
    @State private var getReady = SetupLimits.defaultGetReady
    @State private var path: [Int] = []
    @State private var controller: SessionController?
    @State private var cuePlayer = CuePlayer()

    var body: some View {
        if let controller {
            SessionView(controller: controller) { self.controller = nil }
        } else {
            setup
        }
    }

    private var setup: some View {
        NavigationStack(path: $path) {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 16)], spacing: 16) {
                    ForEach(configurations.indices, id: \.self) { index in
                        NavigationLink(value: index) {
                            Text(configurations[index].name)
                                .font(.title2.weight(.semibold))
                                .frame(maxWidth: .infinity, minHeight: 100)
                                .background(.quaternary, in: .rect(cornerRadius: 16))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationTitle("Beat the Clock")
            .navigationDestination(for: Int.self) { index in
                SetupView(configuration: $configurations[index], getReady: $getReady) {
                    controller = SessionController(configuration: configurations[index], getReady: getReady, cuePlayer: cuePlayer)
                }
            }
        }
    }
}

extension WorkoutConfiguration {
    var name: String {
        switch self {
        case .timer: "Timer"
        case .amrap: "AMRAP"
        case .emom: "EMOM"
        case .tabata: "Tabata"
        case .intervals: "Intervals"
        case .forTime: "For Time"
        case .stopwatch: "Stopwatch"
        case .sets: "Sets"
        }
    }
}

#Preview {
    ContentView()
}
