import Foundation

/// Helper class to manage UserDefaults in tests
class UserDefaultsHelper {
    /// Reset all card expansion states in UserDefaults
    static func resetCardExpansionStates() {
        let defaults = UserDefaults.standard
        let cardKeys = [
            "isShortcutOpen", "isMagicTransformOpen", "isEngineOpen", "isTranscriptionOutputOpen",
            "isLaunchOpen", "isUpdatesOpen", "isSmartSwapsOpen", "isAudioDevicesOpen",
            "isThemeOpen", "isAppearanceOpen", "isBetaOpen", "isDebugOpen", "isAboutOpen"
        ]
        cardKeys.forEach { defaults.removeObject(forKey: $0) }
        defaults.synchronize()
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
            "popoverPinned", "dictationApiKey"
        ]
        settingsKeys.forEach { defaults.removeObject(forKey: $0) }
        defaults.synchronize()
    }
} 