import Foundation
import SwiftUI

@MainActor
final class TunaSettings: ObservableObject {
    static let shared = TunaSettings()
    
    // General Settings
    @Published var launchAtLogin: Bool = false
    @Published var showInDock: Bool = true
    @Published var showInMenuBar: Bool = true
    @Published var magicEnabled: Bool = true
    
    // UI State
    @Published var isLaunchOpen: Bool = false
    @Published var isShortcutOpen: Bool = false
    @Published var isSmartSwapsOpen: Bool = false
    @Published var isThemeOpen: Bool = false
    @Published var isBetaOpen: Bool = false
    @Published var isAboutOpen: Bool = false
    
    // Dictation Settings
    @Published var enableDictationShortcut: Bool = true
    @Published var dictationHotkey: String = "⌘ + Space"
    @Published var dictationLanguage: String = "English (US)"
    @Published var autoCopyTranscriptionToClipboard: Bool = true
    @Published var autoStopAfterSilence: Bool = false
    @Published var silenceThreshold: Double = 2.0
    
    // Audio Settings
    @Published var enableSmartSwitching: Bool = false
    
    private init() {
        loadSettings()
    }
    
    func loadSettings() {
        let defaults = UserDefaults.standard
        launchAtLogin = defaults.bool(forKey: "launchAtLogin")
        showInDock = defaults.bool(forKey: "showInDock")
        showInMenuBar = defaults.bool(forKey: "showInMenuBar")
        magicEnabled = defaults.bool(forKey: "magicEnabled")
        enableDictationShortcut = defaults.bool(forKey: "enableDictationShortcut")
        dictationHotkey = defaults.string(forKey: "dictationHotkey") ?? "⌘ + Space"
        dictationLanguage = defaults.string(forKey: "dictationLanguage") ?? "English (US)"
        autoCopyTranscriptionToClipboard = defaults.bool(forKey: "autoCopyTranscriptionToClipboard")
        autoStopAfterSilence = defaults.bool(forKey: "autoStopAfterSilence")
        silenceThreshold = defaults.double(forKey: "silenceThreshold")
        enableSmartSwitching = defaults.bool(forKey: "enableSmartSwitching")
    }
    
    func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(launchAtLogin, forKey: "launchAtLogin")
        defaults.set(showInDock, forKey: "showInDock")
        defaults.set(showInMenuBar, forKey: "showInMenuBar")
        defaults.set(magicEnabled, forKey: "magicEnabled")
        defaults.set(enableDictationShortcut, forKey: "enableDictationShortcut")
        defaults.set(dictationHotkey, forKey: "dictationHotkey")
        defaults.set(dictationLanguage, forKey: "dictationLanguage")
        defaults.set(autoCopyTranscriptionToClipboard, forKey: "autoCopyTranscriptionToClipboard")
        defaults.set(autoStopAfterSilence, forKey: "autoStopAfterSilence")
        defaults.set(silenceThreshold, forKey: "silenceThreshold")
        defaults.set(enableSmartSwitching, forKey: "enableSmartSwitching")
    }
    
    func resetToDefaults() {
        launchAtLogin = false
        showInDock = true
        showInMenuBar = true
        magicEnabled = true
        enableDictationShortcut = true
        dictationHotkey = "⌘ + Space"
        dictationLanguage = "English (US)"
        autoCopyTranscriptionToClipboard = true
        autoStopAfterSilence = false
        silenceThreshold = 2.0
        enableSmartSwitching = false
        saveSettings()
    }
} 