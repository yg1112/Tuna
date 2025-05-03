@preconcurrency
public protocol SettingsServiceProtocol {
    nonisolated func currentSettings() async -> AppSettings
    @MainActor func save(_ settings: AppSettings)
}
