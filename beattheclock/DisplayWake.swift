import Foundation
#if os(iOS)
import UIKit
#endif

/// Keeps the display from sleeping while active. On Mac the activity also stops App Nap
/// from delaying cues when the window is covered. Released on deinit, so closing a window
/// mid-workout never leaves the display awake.
final class DisplayWake {
    var isActive = false {
        didSet {
            guard isActive != oldValue else { return }
            apply(isActive)
        }
    }

    #if os(iOS)
    /// Wakes held across all windows; the idle timer is one app-wide flag.
    private static var activeCount = 0
    #else
    private var activity: NSObjectProtocol?
    #endif

    isolated deinit {
        if isActive { apply(false) }
    }

    private func apply(_ active: Bool) {
        #if os(iOS)
        Self.activeCount += active ? 1 : -1
        UIApplication.shared.isIdleTimerDisabled = Self.activeCount > 0
        #else
        if active {
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
