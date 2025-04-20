// @module: NotificationExtensions
// @created_by_cursor: yes
// @summary: 扩展Notification.Name，提供标准化通知名称常量

import Foundation

extension Notification.Name {
    // 快捷键设置相关通知
    static let dictationShortcutSettingsChanged = Notification
        .Name("dictationShortcutSettingsChanged")

    // 标签切换通知
    static let switchToTab = Notification.Name("switchToTab")

    // 设置通知
    static let settingsChangedNotification = Notification.Name("settingsChangedNotification")
    static let showSettings = Notification.Name("showSettings")

    // 文件选择通知
    static let fileSelectionStarted = Notification.Name("fileSelectionStarted")
    static let fileSelectionEnded = Notification.Name("fileSelectionEnded")

    // Popover状态通知
    static let togglePinned = Notification.Name("togglePinned")
}
