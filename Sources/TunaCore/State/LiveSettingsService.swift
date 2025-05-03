import Foundation
import TunaTypes

@MainActor
public struct LiveSettingsService: SettingsServiceProtocol {
    private let settings: TunaSettings

    public init(settings: TunaSettings) {
        self.settings = settings
    }

    public nonisolated func currentSettings() async -> AppSettings {
        await Task { @MainActor in
            self.settings.asAppSettings
        }.value
    }

    public func save(_ settings: AppSettings) {
        self.settings.update(from: settings)
    }
}
