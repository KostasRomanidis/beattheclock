//
//  beattheclockApp.swift
//  beattheclock
//
//  Created by Konstantinos Romanidis on 5/11/26.
//

import SwiftUI
import WorkoutEngine

@main
struct beattheclockApp: App {
    @State private var cuePlayer = CuePlayer()

    var body: some Scene {
        WindowGroup {
            ContentView(cuePlayer: cuePlayer)
        }
    }
}
