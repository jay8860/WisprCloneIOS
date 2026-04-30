import AppKit
import Foundation
import Sparkle

@MainActor
final class SpeakDashSparkleUpdater: NSObject, SPUUpdaterDelegate {
    private lazy var updaterController: SPUStandardUpdaterController = {
        // `startingUpdater: true` starts automatically and will check on schedule if configured.
        SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: self, userDriverDelegate: nil)
    }()

    func checkForUpdates() {
        updaterController.checkForUpdates(nil)
    }

    // MARK: SPUUpdaterDelegate
    func allowedChannels(for updater: SPUUpdater) -> Set<String> {
        // Default stable channel only.
        return []
    }
}
