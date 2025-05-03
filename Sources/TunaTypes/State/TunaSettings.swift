import Foundation
import SwiftUI

@MainActor
public class TunaSettings: ObservableObject {
    @MainActor public static let shared = TunaSettings()

    // Core settings
    @Published public var currentMode: String = "automatic"
    @Published public var magicEnabled: Bool = false
    @Published public var magicPreset: PresetStyle = .none
    @Published public var transcriptionLanguage: String = "en"
    @Published public var launchAtLogin: Bool = false

    // UI State
    @Published public var isLaunchOpen: Bool = false
    @Published public var isAudioDevicesOpen: Bool = false
    @Published public var isThemeOpen: Bool = false
    @Published public var isBetaOpen: Bool = false
    @Published public var isAboutOpen: Bool = false
    @Published public var isEngineOpen: Bool = false
    @Published public var isTranscriptionOutputOpen: Bool = false
    @Published public var isUpdatesOpen: Bool = false
    @Published public var isAppearanceOpen: Bool = false
    @Published public var isDebugOpen: Bool = false
    @Published public var useSystemAppearance: Bool = true
    @Published public var betaEnabled: Bool = false

    // Keyboard Shortcuts
    @Published public var enableDictationShortcut: Bool = true
    @Published public var dictationShortcutKeyCombo: String = "⌘⌥D"
    @Published public var showDictationPageOnShortcut: Bool = true

    // Transcription Settings
    @Published public var autoCopyTranscriptionToClipboard: Bool = false
    @Published public var transcriptionOutputDirectory: URL?
    @Published public var transcriptionFormat: String = "txt"
    @Published public var whisperAPIKey: String = ""

    // MARK: - Published Properties
    @Published public var checkForUpdates: Bool = true
    @Published public var isDarkMode: Bool = false
    @Published public var debugEnabled: Bool = false
    @Published public var isMagicEnabled: Bool = false
    @Published public var reduceMotion: Bool = false
    @Published public var magicCustomPrompt: String = ""

    private init() {
        // Load saved settings
        self.loadSettings()
    }

    private func loadSettings() {
        if let data = UserDefaults.standard.data(forKey: "tunaSettings") {
            do {
                let decoder = JSONDecoder()
                let settings = try decoder.decode(TunaSettingsData.self, from: data)
                self.updateFromData(settings)
            } catch {
                print("Failed to load settings: \(error)")
            }
        }
    }

    private func saveSettings() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(self.asData)
            UserDefaults.standard.set(data, forKey: "tunaSettings")
        } catch {
            print("Failed to save settings: \(error)")
        }
    }

    private var asData: TunaSettingsData {
        TunaSettingsData(
            currentMode: self.currentMode,
            magicEnabled: self.magicEnabled,
            magicPreset: self.magicPreset,
            transcriptionLanguage: self.transcriptionLanguage,
            launchAtLogin: self.launchAtLogin,
            enableDictationShortcut: self.enableDictationShortcut,
            dictationShortcutKeyCombo: self.dictationShortcutKeyCombo,
            showDictationPageOnShortcut: self.showDictationPageOnShortcut,
            autoCopyTranscriptionToClipboard: self.autoCopyTranscriptionToClipboard,
            transcriptionOutputDirectory: self.transcriptionOutputDirectory,
            transcriptionFormat: self.transcriptionFormat,
            useSystemAppearance: self.useSystemAppearance,
            betaEnabled: self.betaEnabled
        )
    }

    private func updateFromData(_ data: TunaSettingsData) {
        self.currentMode = data.currentMode
        self.magicEnabled = data.magicEnabled
        self.magicPreset = data.magicPreset
        self.transcriptionLanguage = data.transcriptionLanguage
        self.launchAtLogin = data.launchAtLogin
        self.enableDictationShortcut = data.enableDictationShortcut
        self.dictationShortcutKeyCombo = data.dictationShortcutKeyCombo
        self.showDictationPageOnShortcut = data.showDictationPageOnShortcut
        self.autoCopyTranscriptionToClipboard = data.autoCopyTranscriptionToClipboard
        self.transcriptionOutputDirectory = data.transcriptionOutputDirectory
        self.transcriptionFormat = data.transcriptionFormat
        self.useSystemAppearance = data.useSystemAppearance
        self.betaEnabled = data.betaEnabled
    }

    public func update(from settings: AppSettings) {
        self.currentMode = settings.mode.rawValue
        self.magicEnabled = settings.isMagicEnabled
        self.magicPreset = settings.magicPreset
        self.transcriptionLanguage = settings.transcriptionLanguage
        self.saveSettings()
    }

    public var asAppSettings: AppSettings {
        AppSettings(
            mode: Mode(rawValue: self.currentMode) ?? .quickDictation,
            isMagicEnabled: self.magicEnabled,
            magicPreset: self.magicPreset,
            transcriptionLanguage: self.transcriptionLanguage
        )
    }

    public func setOutputDirectory(_ path: String) async {
        // TODO: Implement output directory setting
    }
}

private struct TunaSettingsData: Codable {
    var currentMode: String
    var magicEnabled: Bool
    var magicPreset: PresetStyle
    var transcriptionLanguage: String
    var launchAtLogin: Bool
    var enableDictationShortcut: Bool
    var dictationShortcutKeyCombo: String
    var showDictationPageOnShortcut: Bool
    var autoCopyTranscriptionToClipboard: Bool
    var transcriptionOutputDirectory: URL?
    var transcriptionFormat: String
    var useSystemAppearance: Bool
    var betaEnabled: Bool
}
