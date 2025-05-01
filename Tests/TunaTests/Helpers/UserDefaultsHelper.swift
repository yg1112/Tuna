import Foundation
import TunaCore

/// Helper class to manage UserDefaults in tests
class UserDefaultsHelper {
    /// Reset all card expansion states in UserDefaults
    static func resetCardExpansionStates() {
        let defaults = UserDefaults.standard
        let cardKeys = [
            "isShortcutOpen", "isMagicTransformOpen", "isEngineOpen", "isTranscriptionOutputOpen",
            "isLaunchOpen", "isUpdatesOpen", "isSmartSwapsOpen", "isAudioDevicesOpen",
            "isThemeOpen", "isAppearanceOpen", "isBetaOpen", "isDebugOpen", "isAboutOpen",
        ]

        // First remove all existing values
        cardKeys.forEach { defaults.removeObject(forKey: $0) }

        // Then set all card states to true (expanded)
        cardKeys.forEach { defaults.set(true, forKey: $0) }

        // Force synchronize to ensure changes are written
        defaults.synchronize()

        // Also reset the TunaSettings shared instance
        TunaSettings.shared.loadDefaults()
    }

    /// Reset all settings in UserDefaults
    static func resetAllSettings() {
        let defaults = UserDefaults.standard
        let settingsKeys = [
            // Card expansion states
            "isShortcutOpen", "isMagicTransformOpen", "isEngineOpen", "isTranscriptionOutputOpen",
            "isLaunchOpen", "isUpdatesOpen", "isSmartSwapsOpen", "isAudioDevicesOpen",
            "isThemeOpen", "isAppearanceOpen", "isBetaOpen", "isDebugOpen", "isAboutOpen",

            // Theme and appearance
            "theme", "glassStrength", "fontScale", "reduceMotion",

            // Features
            "enableBeta", "whisperAPIKey", "enableSmartDeviceSwapping",

            // Audio devices
            "selectedOutputDeviceUID", "selectedInputDeviceUID",
            "historicalOutputDevices", "historicalInputDevices",
            "backupOutputDeviceUID", "backupInputDeviceUID",

            // Stats
            "stats_consecutiveDays", "stats_wordsFreed", "stats_smartSwaps", "stats_lastUsedDate",

            // Audio modes
            "currentModeID", "audioModes",

            // Other settings
            "popoverPinned", "dictationApiKey",
        ]

        // First remove all settings
        settingsKeys.forEach { defaults.removeObject(forKey: $0) }

        // Then set all card expansion states to true
        let cardKeys = [
            "isShortcutOpen", "isMagicTransformOpen", "isEngineOpen", "isTranscriptionOutputOpen",
            "isLaunchOpen", "isUpdatesOpen", "isSmartSwapsOpen", "isAudioDevicesOpen",
            "isThemeOpen", "isAppearanceOpen", "isBetaOpen", "isDebugOpen", "isAboutOpen",
        ]
        cardKeys.forEach { defaults.set(true, forKey: $0) }

        defaults.synchronize()
    }
}
