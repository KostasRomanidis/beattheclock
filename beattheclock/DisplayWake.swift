import Foundation
#if os(iOS)
import UIKit
#endif

/// Keeps the display from sleeping while active. On Mac the activity also stops App Nap
/// from delaying cues when the window is covered.
final class DisplayWake {
    var isActive = false {
        didSet {
            guard isActive != oldValue else { return }
            apply()
        }
    }

    #if os(macOS)
    private var activity: NSObjectProtocol?
    #endif

    private func apply() {
        #if os(iOS)
        UIApplication.shared.isIdleTimerDisabled = isActive
        #else
        if isActive {
            activity = ProcessInfo.processInfo.beginActivity(
                options: [.idleDisplaySleepDisabled, .userInitiated],
                reason: "Workout in progress"
            )
        } else if let activity {
            ProcessInfo.processInfo.endActivity(activity)
            self.activity = nil
        }
        #endif
    }
}
