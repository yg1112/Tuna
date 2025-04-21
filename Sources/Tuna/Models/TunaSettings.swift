import Foundation
import SwiftUI

/// Manages all application settings and preferences
@MainActor
public final class TunaSettings: ObservableObject {
    public static let shared = TunaSettings()
    
    // MARK: - General Settings
    @Published public var launchAtLogin: Bool = false
    @Published public var showInDock: Bool = true
    @Published public var showInMenuBar: Bool = true
    @Published public var magicEnabled: Bool = true
    
    // MARK: - UI State
    @Published public var isLaunchOpen: Bool = false
    @Published public var isShortcutOpen: Bool = false
    @Published public var isSmartSwapsOpen: Bool = false
    @Published public var isThemeOpen: Bool = false
    @Published public var isBetaOpen: Bool = false
    @Published public var isAboutOpen: Bool = false
    @Published public var isUpdatesOpen: Bool = false
    @Published public var isDebugOpen: Bool = false
    @Published public var isAppearanceOpen: Bool = false
    @Published public var isAudioDevicesOpen: Bool = false
    @Published public var isEngineOpen: Bool = false
    @Published public var isTranscriptionOutputOpen: Bool = false
    
    // MARK: - Dictation Settings
    @Published public var enableDictationShortcut: Bool = true
    @Published public var dictationShortcutKeyCombo: String = "⌘ + Space"
    @Published public var dictationLanguage: String = "English (US)"
    @Published public var autoCopyToClipboard: Bool = true
    @Published public var autoStopAfterSilence: Bool = false
    @Published public var silenceThreshold: Double = 2.0
    @Published public var showDictationPageOnShortcut: Bool = true
    @Published public var transcriptionFormat: String = "txt"
    @Published public var transcriptionOutputDirectory: URL?
    @Published public var presetStyle: PresetStyle = .clean
    
    // MARK: - Audio Settings
    @Published public var enableSmartSwitching: Bool = false
    @Published public var showVolumeSliders: Bool = true
    @Published public var selectedInputDevice: String?
    @Published public var selectedOutputDevice: String?
    @Published public var inputVolume: Double = 1.0
    @Published public var outputVolume: Double = 1.0
    
    // MARK: - Theme Settings
    @Published public var theme: String = "system"
    @Published public var menuBarIconStyle: String = "default"
    
    // MARK: - Advanced Settings
    @Published public var enableBetaFeatures: Bool = false
    @Published public var debugLoggingEnabled: Bool = false
    
    private init() {
        loadSettings()
    }
    
    // MARK: - Settings Management
    public func loadSettings() {
        let defaults = UserDefaults.standard
        
        // General Settings
        launchAtLogin = defaults.bool(forKey: "launchAtLogin")
        showInDock = defaults.bool(forKey: "showInDock")
        showInMenuBar = defaults.bool(forKey: "showInMenuBar")
        magicEnabled = defaults.bool(forKey: "magicEnabled")
        
        // Dictation Settings
        enableDictationShortcut = defaults.bool(forKey: "enableDictationShortcut")
        dictationShortcutKeyCombo = defaults.string(forKey: "dictationShortcutKeyCombo") ?? "⌘ + Space"
        dictationLanguage = defaults.string(forKey: "dictationLanguage") ?? "English (US)"
        autoCopyToClipboard = defaults.bool(forKey: "autoCopyToClipboard")
        autoStopAfterSilence = defaults.bool(forKey: "autoStopAfterSilence")
        silenceThreshold = defaults.double(forKey: "silenceThreshold")
        showDictationPageOnShortcut = defaults.bool(forKey: "showDictationPageOnShortcut")
        transcriptionFormat = defaults.string(forKey: "transcriptionFormat") ?? "txt"
        if let outputDirPath = defaults.string(forKey: "transcriptionOutputDirectory") {
            transcriptionOutputDirectory = URL(fileURLWithPath: outputDirPath)
        }
        if let styleRawValue = defaults.string(forKey: "presetStyle") {
            presetStyle = PresetStyle(rawValue: styleRawValue) ?? .clean
        }
        
        // Audio Settings
        enableSmartSwitching = defaults.bool(forKey: "enableSmartSwitching")
        showVolumeSliders = defaults.bool(forKey: "showVolumeSliders")
        selectedInputDevice = defaults.string(forKey: "selectedInputDevice")
        selectedOutputDevice = defaults.string(forKey: "selectedOutputDevice")
        inputVolume = defaults.double(forKey: "inputVolume")
        outputVolume = defaults.double(forKey: "outputVolume")
        
        // Theme Settings
        theme = defaults.string(forKey: "theme") ?? "system"
        menuBarIconStyle = defaults.string(forKey: "menuBarIconStyle") ?? "default"
        
        // Advanced Settings
        enableBetaFeatures = defaults.bool(forKey: "enableBetaFeatures")
        debugLoggingEnabled = defaults.bool(forKey: "debugLoggingEnabled")
    }
    
    public func saveSettings() {
        let defaults = UserDefaults.standard
        
        // General Settings
        defaults.set(launchAtLogin, forKey: "launchAtLogin")
        defaults.set(showInDock, forKey: "showInDock")
        defaults.set(showInMenuBar, forKey: "showInMenuBar")
        defaults.set(magicEnabled, forKey: "magicEnabled")
        
        // Dictation Settings
        defaults.set(enableDictationShortcut, forKey: "enableDictationShortcut")
        defaults.set(dictationShortcutKeyCombo, forKey: "dictationShortcutKeyCombo")
        defaults.set(dictationLanguage, forKey: "dictationLanguage")
        defaults.set(autoCopyToClipboard, forKey: "autoCopyToClipboard")
        defaults.set(autoStopAfterSilence, forKey: "autoStopAfterSilence")
        defaults.set(silenceThreshold, forKey: "silenceThreshold")
        defaults.set(showDictationPageOnShortcut, forKey: "showDictationPageOnShortcut")
        defaults.set(transcriptionFormat, forKey: "transcriptionFormat")
        defaults.set(transcriptionOutputDirectory?.path, forKey: "transcriptionOutputDirectory")
        defaults.set(presetStyle.rawValue, forKey: "presetStyle")
        
        // Audio Settings
        defaults.set(enableSmartSwitching, forKey: "enableSmartSwitching")
        defaults.set(showVolumeSliders, forKey: "showVolumeSliders")
        defaults.set(selectedInputDevice, forKey: "selectedInputDevice")
        defaults.set(selectedOutputDevice, forKey: "selectedOutputDevice")
        defaults.set(inputVolume, forKey: "inputVolume")
        defaults.set(outputVolume, forKey: "outputVolume")
        
        // Theme Settings
        defaults.set(theme, forKey: "theme")
        defaults.set(menuBarIconStyle, forKey: "menuBarIconStyle")
        
        // Advanced Settings
        defaults.set(enableBetaFeatures, forKey: "enableBetaFeatures")
        defaults.set(debugLoggingEnabled, forKey: "debugLoggingEnabled")
    }
    
    public func resetToDefaults() {
        // General Settings
        launchAtLogin = false
        showInDock = true
        showInMenuBar = true
        magicEnabled = true
        
        // Dictation Settings
        enableDictationShortcut = true
        dictationShortcutKeyCombo = "⌘ + Space"
        dictationLanguage = "English (US)"
        autoCopyToClipboard = true
        autoStopAfterSilence = false
        silenceThreshold = 2.0
        showDictationPageOnShortcut = true
        transcriptionFormat = "txt"
        transcriptionOutputDirectory = nil
        presetStyle = .clean
        
        // Audio Settings
        enableSmartSwitching = false
        showVolumeSliders = true
        selectedInputDevice = nil
        selectedOutputDevice = nil
        inputVolume = 1.0
        outputVolume = 1.0
        
        // Theme Settings
        theme = "system"
        menuBarIconStyle = "default"
        
        // Advanced Settings
        enableBetaFeatures = false
        debugLoggingEnabled = false
        
        saveSettings()
    }
}

// MARK: - Notification Names
public extension Notification.Name {
    static let appearanceChanged = Notification.Name("appearanceChanged")
    static let dictationShortcutSettingsChanged = Notification.Name("dictationShortcutSettingsChanged")
} 