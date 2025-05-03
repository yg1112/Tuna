import Foundation

public extension Notification.Name {
    // Audio device notifications
    static let audioDevicesChanged = Notification.Name("audioDevicesChanged")
    static let audioDeviceDefaultChanged = Notification.Name("audioDeviceDefaultChanged")

    // Dictation notifications
    static let dictationAPIKeyUpdated = Notification.Name("dictationAPIKeyUpdated")
    static let dictationAPIKeyMissing = Notification.Name("dictationAPIKeyMissing")
    static let dictationError = Notification.Name("dictationError")
    static let dictationDebugMessage = Notification.Name("dictationDebugMessage")
    static let dictationFinished = Notification.Name("dictationFinished")
    static let dictationStarted = Notification.Name("dictationStarted")
    static let dictationStopped = Notification.Name("dictationStopped")

    // UI notifications
    static let showSettings = Notification.Name("showSettings")
    static let togglePinned = Notification.Name("togglePinned")
    static let switchToTab = Notification.Name("switchToTab")
    static let fileSelectionStarted = Notification.Name("fileSelectionStarted")
    static let fileSelectionEnded = Notification.Name("fileSelectionEnded")
}
