import Combine
import Foundation
import Sparkle

@MainActor
final class LauncherUpdateController: ObservableObject {
    let updaterController: SPUStandardUpdaterController
    @Published private(set) var canCheckForUpdates = false
    private var canCheckForUpdatesSubscription: AnyCancellable?

    init(startingUpdater: Bool = true) {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: startingUpdater,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        canCheckForUpdatesSubscription = updaterController.updater
            .publisher(for: \.canCheckForUpdates)
            .receive(on: RunLoop.main)
            .sink { [weak self] value in
                self?.canCheckForUpdates = value
            }
    }

    func checkForUpdates() {
        updaterController.checkForUpdates(nil)
    }
}
