import CoreAudio
import Foundation
import os.log
import ServiceManagement
import SwiftUI

// 添加UI实验模式枚举
public enum UIExperimentMode: String, CaseIterable, Identifiable {
    case newUI1 = "Tuna UI"

    public var id: String { rawValue }

    public var description: String {
        switch self {
            case .newUI1:
                "Standard Tuna user interface"
        }
    }
}

// 添加操作模式枚举
public enum Mode: String, CaseIterable, Identifiable {
    case standard = "Standard"
    case experimental = "Experimental"

    public var id: String { rawValue }

    public var description: String {
        switch self {
            case .standard:
                "The current stable mode"
            case .experimental:
                "Experimental mode"
        }
    }
}

// Magic Transform 相关定义
public enum PresetStyle: String, CaseIterable, Identifiable {
    case abit = "ABit"
    case concise = "Concise"
    case custom = "Custom"

    public var id: String { rawValue }
}

public struct PromptTemplate {
    public let id: PresetStyle
    public let system: String
}

public extension PromptTemplate {
    static let library: [PresetStyle: PromptTemplate] = [
        .abit: .init(id: .abit, system: "Rephrase to sound a bit more native."),
        .concise: .init(id: .concise, system: "Summarize concisely in ≤2 lines."),
        .custom: .init(id: .custom, system: ""), // placeholder
    ]
}

public class TunaSettings: ObservableObject {
    public static var shared = TunaSettings()
    private let logger = Logger(subsystem: "ai.tuna", category: "Settings")
    private var isUpdating = false // 防止循环更新

    // 使用可注入的UserDefaults
    private let defaults: UserDefaults

    // MARK: - Published Properties
    @Published public var currentMode: Mode = .standard {
        didSet {
            if !self.isUpdating {
                self.defaults.set(self.currentMode.rawValue, forKey: "currentMode")
            }
        }
    }

    @Published public var uiExperimentMode: UIExperimentMode = .newUI1
    @Published public var enableSmartSwitching: Bool = false
    @Published public var preferredVideoChatOutputDeviceUID: String = ""
    @Published public var preferredVideoChatInputDeviceUID: String = ""
    @Published public var preferredMusicOutputDeviceUID: String = ""
    @Published public var preferredGamingOutputDeviceUID: String = ""
    @Published public var preferredGamingInputDeviceUID: String = ""
    @Published public var showVolumeSliders: Bool = false
    @Published public var showMicrophoneLevelMeter: Bool = false
    @Published public var useExperimentalUI: Bool = false
    @Published public var launchAtLogin: Bool = false
    @Published public var checkForUpdates: Bool = true
    @Published public var useSystemAppearance: Bool = true
    @Published public var isDarkMode: Bool = false
    @Published public var betaEnabled: Bool = false
    @Published public var debugEnabled: Bool = false
    @Published public var preferredOutputDeviceUID: String = ""
    @Published public var preferredInputDeviceUID: String = ""
    @Published public var transcriptionFormat: String = "txt"
    @Published public var transcriptionOutputDirectory: URL? = nil {
        didSet {
            if !self.isUpdating, oldValue != self.transcriptionOutputDirectory {
                if let url = transcriptionOutputDirectory {
                    self.defaults.set(url.absoluteString, forKey: "transcriptionOutputDirectory")
                    self.logger.debug("Saved transcription output directory: \(url.absoluteString)")
                } else {
                    self.defaults.removeObject(forKey: "transcriptionOutputDirectory")
                    self.logger.debug("Removed transcription output directory")
                }
            }
        }
    }

    @Published public var autoCopyTranscriptionToClipboard: Bool = false
    @Published public var enableDictationShortcut: Bool = false
    @Published public var dictationShortcutKeyCombo: String = "cmd+u"
    @Published public var showDictationPageOnShortcut: Bool = false
    @Published public var enableDictationSoundFeedback: Bool = true
    @Published public var transcriptionLanguage: String = ""
    @Published public var defaultOutputDeviceUID: String = ""
    @Published public var defaultInputDeviceUID: String = ""
    @Published public var magicEnabled: Bool = false
    @Published public var magicPreset: PresetStyle = .abit
    @Published public var magicCustomPrompt: String = ""
    @Published public var magicTransformEnabled: Bool = false {
        didSet {
            if !self.isUpdating {
                self.defaults.set(self.magicTransformEnabled, forKey: "magicTransformEnabled")
            }
        }
    }

    @Published public var isShortcutOpen: Bool = true {
        didSet {
            if !self.isUpdating {
                self.defaults.set(self.isShortcutOpen, forKey: "isShortcutOpen")
            }
        }
    }

    @Published public var isMagicTransformOpen: Bool = true {
        didSet {
            if !self.isUpdating {
                self.defaults.set(self.isMagicTransformOpen, forKey: "isMagicTransformOpen")
            }
        }
    }

    private var _isEngineOpen: Bool = true
    public var isEngineOpen: Bool {
        get { true } // Always return true for non-collapsible cards
        set {
            if !self.isUpdating {
                self._isEngineOpen = true
                self.defaults.set(true, forKey: "isEngineOpen")
            }
        }
    }

    private var _isTranscriptionOutputOpen: Bool = true
    public var isTranscriptionOutputOpen: Bool {
        get { true } // Always return true for non-collapsible cards
        set {
            if !self.isUpdating {
                self._isTranscriptionOutputOpen = true
                self.defaults.set(true, forKey: "isTranscriptionOutputOpen")
            }
        }
    }

    @Published public var isLaunchOpen: Bool = true {
        didSet {
            if !self.isUpdating {
                self.defaults.set(self.isLaunchOpen, forKey: "isLaunchOpen")
            }
        }
    }

    @Published public var isUpdatesOpen: Bool = true {
        didSet {
            if !self.isUpdating {
                self.defaults.set(self.isUpdatesOpen, forKey: "isUpdatesOpen")
            }
        }
    }

    @Published public var isSmartSwapsOpen: Bool = true {
        didSet {
            if !self.isUpdating {
                self.defaults.set(self.isSmartSwapsOpen, forKey: "isSmartSwapsOpen")
            }
        }
    }

    @Published public var isAudioDevicesOpen: Bool = true {
        didSet {
            if !self.isUpdating {
                self.defaults.set(self.isAudioDevicesOpen, forKey: "isAudioDevicesOpen")
            }
        }
    }

    @Published public var isThemeOpen: Bool = true {
        didSet {
            if !self.isUpdating {
                self.defaults.set(self.isThemeOpen, forKey: "isThemeOpen")
            }
        }
    }

    @Published public var isAppearanceOpen: Bool = true {
        didSet {
            if !self.isUpdating {
                self.defaults.set(self.isAppearanceOpen, forKey: "isAppearanceOpen")
            }
        }
    }

    @Published public var isBetaOpen: Bool = true {
        didSet {
            if !self.isUpdating {
                self.defaults.set(self.isBetaOpen, forKey: "isBetaOpen")
            }
        }
    }

    @Published public var isDebugOpen: Bool = true {
        didSet {
            if !self.isUpdating {
                self.defaults.set(self.isDebugOpen, forKey: "isDebugOpen")
            }
        }
    }

    @Published public var isAboutOpen: Bool = true {
        didSet {
            if !self.isUpdating {
                self.defaults.set(self.isAboutOpen, forKey: "isAboutOpen")
            }
        }
    }

    @Published public var dictationShortcut: String = "⌘⌥D"

    // MARK: - Initialization

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.loadDefaults()
    }

    public func loadDefaults() {
        self.isUpdating = true
        defer { isUpdating = false }

        // Load card expansion states with default values
        self.isShortcutOpen = self.defaults.object(forKey: "isShortcutOpen") as? Bool ?? true
        self.isMagicTransformOpen = self.defaults
            .object(forKey: "isMagicTransformOpen") as? Bool ?? true
        self.isEngineOpen = self.defaults.object(forKey: "isEngineOpen") as? Bool ?? true
        self.isTranscriptionOutputOpen = self.defaults
            .object(forKey: "isTranscriptionOutputOpen") as? Bool ?? true
        self.isLaunchOpen = self.defaults.object(forKey: "isLaunchOpen") as? Bool ?? true
        self.isUpdatesOpen = self.defaults.object(forKey: "isUpdatesOpen") as? Bool ?? true
        self.isSmartSwapsOpen = self.defaults.object(forKey: "isSmartSwapsOpen") as? Bool ?? true
        self.isAudioDevicesOpen = self.defaults
            .object(forKey: "isAudioDevicesOpen") as? Bool ?? true
        self.isThemeOpen = self.defaults.object(forKey: "isThemeOpen") as? Bool ?? true
        self.isAppearanceOpen = self.defaults.object(forKey: "isAppearanceOpen") as? Bool ?? true
        self.isBetaOpen = self.defaults.object(forKey: "isBetaOpen") as? Bool ?? true
        self.isDebugOpen = self.defaults.object(forKey: "isDebugOpen") as? Bool ?? true
        self.isAboutOpen = self.defaults.object(forKey: "isAboutOpen") as? Bool ?? true

        // Load feature flags with default values
        self.launchAtLogin = self.defaults.object(forKey: "launchAtLogin") as? Bool ?? false
        self.checkForUpdates = self.defaults.object(forKey: "checkForUpdates") as? Bool ?? true
        self.magicTransformEnabled = self.defaults
            .object(forKey: "magicTransformEnabled") as? Bool ?? false
        self.useSystemAppearance = self.defaults
            .object(forKey: "useSystemAppearance") as? Bool ?? true
        self.isDarkMode = self.defaults.object(forKey: "isDarkMode") as? Bool ?? false
        reduceMotion = self.defaults.object(forKey: "reduceMotion") as? Bool ?? false
        self.betaEnabled = self.defaults.object(forKey: "betaEnabled") as? Bool ?? false
        self.debugEnabled = self.defaults.object(forKey: "debugEnabled") as? Bool ?? false

        // Load dictation settings
        self.dictationShortcut = self.defaults.string(forKey: "dictationShortcut") ?? "⌘⌥D"

        // Load output directory
        if let urlString = defaults.string(forKey: "transcriptionOutputDirectory") {
            self.transcriptionOutputDirectory = URL(string: urlString)
        }

        // Ensure defaults are synchronized
        self.defaults.synchronize()
    }

    public func saveDefaults() {
        self.isUpdating = true
        defer { isUpdating = false }

        // Save card expansion states
        self.defaults.set(self.isShortcutOpen, forKey: "isShortcutOpen")
        self.defaults.set(self.isMagicTransformOpen, forKey: "isMagicTransformOpen")
        self.defaults.set(self.isEngineOpen, forKey: "isEngineOpen")
        self.defaults.set(self.isTranscriptionOutputOpen, forKey: "isTranscriptionOutputOpen")
        self.defaults.set(self.isLaunchOpen, forKey: "isLaunchOpen")
        self.defaults.set(self.isUpdatesOpen, forKey: "isUpdatesOpen")
        self.defaults.set(self.isSmartSwapsOpen, forKey: "isSmartSwapsOpen")
        self.defaults.set(self.isAudioDevicesOpen, forKey: "isAudioDevicesOpen")
        self.defaults.set(self.isThemeOpen, forKey: "isThemeOpen")
        self.defaults.set(self.isAppearanceOpen, forKey: "isAppearanceOpen")
        self.defaults.set(self.isBetaOpen, forKey: "isBetaOpen")
        self.defaults.set(self.isDebugOpen, forKey: "isDebugOpen")
        self.defaults.set(self.isAboutOpen, forKey: "isAboutOpen")

        // Save feature flags
        self.defaults.set(self.launchAtLogin, forKey: "launchAtLogin")
        self.defaults.set(self.checkForUpdates, forKey: "checkForUpdates")
        self.defaults.set(self.magicTransformEnabled, forKey: "magicTransformEnabled")
        self.defaults.set(self.useSystemAppearance, forKey: "useSystemAppearance")
        self.defaults.set(self.isDarkMode, forKey: "isDarkMode")
        self.defaults.set(reduceMotion, forKey: "reduceMotion")
        self.defaults.set(self.betaEnabled, forKey: "betaEnabled")
        self.defaults.set(self.debugEnabled, forKey: "debugEnabled")

        // Save dictation settings
        self.defaults.set(self.dictationShortcut, forKey: "dictationShortcut")

        // Save output directory
        if let url = transcriptionOutputDirectory {
            self.defaults.set(url.absoluteString, forKey: "transcriptionOutputDirectory")
        }

        // Ensure defaults are synchronized
        self.defaults.synchronize()
    }

    // Helper extension for UserDefaults

    // 从UserDefaults.standard迁移设置到带域名的UserDefaults
    private func migrateFromStandardDefaults() {
        let keys = [
            "transcriptionOutputDirectory",
            "isShortcutOpen",
            "isMagicTransformOpen",
            "isEngineOpen",
            "isTranscriptionOutputOpen",
            "isLaunchOpen",
            "isUpdatesOpen",
            "isSmartSwapsOpen",
            "isAudioDevicesOpen",
            "isThemeOpen",
            "isAppearanceOpen",
            "isBetaOpen",
            "isDebugOpen",
            "isAboutOpen",
        ]

        var migrated = false
        let standardDefaults = UserDefaults.standard

        for key in keys {
            if standardDefaults.object(forKey: key) != nil {
                if let value = standardDefaults.object(forKey: key) {
                    self.defaults.set(value, forKey: key)
                    standardDefaults.removeObject(forKey: key)
                    self.logger.debug("Migrated setting: \(key)")
                    migrated = true
                }
            }
        }

        if migrated {
            standardDefaults.synchronize()
            self.defaults.synchronize()
            self.logger.notice("Settings migrated from standard UserDefaults to ai.tuna.app domain")
        }
    }

    public var theme: String {
        get { UserDefaults.standard.string(forKey: "theme") ?? "system" }
        set { UserDefaults.standard.set(newValue, forKey: "theme") }
    }

    public var shortcutEnabled: Bool {
        get { self.enableDictationShortcut }
        set { self.enableDictationShortcut = newValue }
    }

    // MARK: - Computed Properties
    public var transcriptionOutputDirectoryDisplay: String {
        self.transcriptionOutputDirectory?.lastPathComponent ?? "Not set"
    }

    // Magic Transform settings
    public var magicTransformStyle: PresetStyle {
        get { self.magicPreset }
        set { self.magicPreset = newValue }
    }

    // Shortcut settings (aliases to existing properties)
    var shortcutKey: String {
        get { self.dictationShortcutKeyCombo }
        set { self.dictationShortcutKeyCombo = newValue }
    }

    // Smart Swaps alias
    var smartSwaps: Bool {
        get { self.enableSmartSwitching }
        set { self.enableSmartSwitching = newValue }
    }

    // Whisper API Key
    public var whisperAPIKey: String {
        get { UserDefaults.standard.string(forKey: "whisperAPIKey") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "whisperAPIKey") }
    }

    // Reset all settings
    static func resetAll() {
        let defaults = UserDefaults.standard

        // Get all default keys
        if let bundleID = Bundle.main.bundleIdentifier {
            defaults.removePersistentDomain(forName: bundleID)
        }

        // Reload default values
        TunaSettings.shared.loadDefaults()

        // Post notification for UI refresh
        NotificationCenter.default.post(name: Notification.Name("settingsReset"), object: nil)
    }
}

// MARK: - UI Settings Extension
// 添加UI设置扩展 - 计算属性而不是存储属性

// @module: SettingsUI
// @created_by_cursor: yes
// @summary: Properties extension for TunaSettings
// @depends_on: TunaSettings.swift

extension TunaSettings {
    var glassStrength: Double {
        get { UserDefaults.standard.double(forKey: "glassStrength") }
        set { UserDefaults.standard.set(newValue, forKey: "glassStrength") }
    }

    var fontScale: String {
        get { UserDefaults.standard.string(forKey: "fontScale") ?? "system" }
        set { UserDefaults.standard.set(newValue, forKey: "fontScale") }
    }

    public var reduceMotion: Bool {
        get { UserDefaults.standard.bool(forKey: "reduceMotion") }
        set { UserDefaults.standard.set(newValue, forKey: "reduceMotion") }
    }

    // Beta features
    var enableBeta: Bool {
        get { UserDefaults.standard.bool(forKey: "enableBeta") }
        set { UserDefaults.standard.set(newValue, forKey: "enableBeta") }
    }
}
