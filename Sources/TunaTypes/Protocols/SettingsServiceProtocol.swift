// @module: SettingsService
// @created_by_cursor: yes
// @summary: Protocol for settings service abstraction, used for saving and retrieving app settings.
// @depends_on: TunaSettings, AppSettings
import Foundation
import TunaTypes // for TunaSettings, AppSettings

@MainActor
public protocol SettingsServiceProtocol {
    /// 获取当前设置
    nonisolated func currentSettings() async -> AppSettings
    /// 保存设置
    @MainActor func save(_ settings: AppSettings)
}
