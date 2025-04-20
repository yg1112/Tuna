import CoreAudio
import Foundation
import os.log
import ServiceManagement
import SwiftUI

// 添加UI实验模式枚举
enum UIExperimentMode: String, CaseIterable {
    case standard
    case experimental
}

// 添加操作模式枚举
enum Mode: String, CaseIterable, Identifiable {
    case standard = "Standard"
    case experimental = "Experimental"

    var id: String { rawValue }

    var description: String {
        switch self {
            case .standard:
                "The current stable mode"
            case .experimental:
                "Experimental mode"
        }
    }
}

// Magic Transform 相关定义
enum PresetStyle: String, CaseIterable, Identifiable {
    case abit = "ABit"
    case concise = "Concise"
    case custom = "Custom"

    var id: String { rawValue }
}

struct PromptTemplate {
    let id: PresetStyle
    let system: String
}

extension PromptTemplate {
    static let library: [PresetStyle: PromptTemplate] = [
        .abit: .init(id: .abit, system: "Rephrase to sound a bit more native."),
        .concise: .init(id: .concise, system: "Summarize concisely in ≤2 lines."),
        .custom: .init(id: .custom, system: ""), // placeholder
    ]
}

extension Notification.Name {
    static let appearanceChanged = Notification.Name("TunaAppearanceDidChange")
}

class TunaSettings: ObservableObject {
    static let shared = TunaSettings()
    private let logger = Logger(subsystem: "ai.tuna", category: "Settings")
    private var isUpdating = false // 防止循环更新

    // 使用标准UserDefaults
    private let defaults = UserDefaults.standard
    private let standardDefaults = UserDefaults.standard // 用于迁移旧数据

    // 当前操作模式
    @Published var currentMode: Mode = .standard {
        didSet {
            if oldValue != self.currentMode, !self.isUpdating {
                self.isUpdating = true
                self.defaults.set(self.currentMode.rawValue, forKey: "currentMode")
                self.logger.debug("Saved current mode: \(self.currentMode.rawValue)")
                print("[SETTINGS] Current mode: \(self.currentMode.rawValue)")
                fflush(stdout)
                self.isUpdating = false
            }
        }
    }

    // 添加UI实验模式属性
    @Published var uiExperimentMode: UIExperimentMode {
        didSet {
            if oldValue != self.uiExperimentMode, !self.isUpdating {
                self.isUpdating = true
                self.defaults.set(self.uiExperimentMode.rawValue, forKey: "uiExperimentMode")
                self.logger.debug("Saved UI experiment mode: \(self.uiExperimentMode.rawValue)")
                print(
                    "\u{001B}[36m[SETTINGS]\u{001B}[0m UI experiment mode: \(self.uiExperimentMode.rawValue)"
                )
                fflush(stdout)
                self.isUpdating = false
            }
        }
    }

    // 智能设备切换
    @Published var enableSmartSwitching: Bool {
        didSet {
            if oldValue != self.enableSmartSwitching, !self.isUpdating {
                self.isUpdating = true
                self.defaults.set(self.enableSmartSwitching, forKey: "enableSmartSwitching")
                self.logger.debug("Saved smart switching: \(self.enableSmartSwitching)")
                print(
                    "[SETTINGS] Smart switching: \(self.enableSmartSwitching ? "enabled" : "disabled")"
                )
                fflush(stdout)
                self.isUpdating = false
            }
        }
    }

    // 视频会议偏好设备
    @Published var preferredVideoChatOutputDeviceUID: String {
        didSet {
            if oldValue != self.preferredVideoChatOutputDeviceUID {
                self.defaults.set(
                    self.preferredVideoChatOutputDeviceUID,
                    forKey: "preferredVideoChatOutputDeviceUID"
                )
                self.logger
                    .debug(
                        "Saved video chat output device: \(self.preferredVideoChatOutputDeviceUID)"
                    )
                print(
                    "[SETTINGS] Video chat output device: \(self.preferredVideoChatOutputDeviceUID)"
                )
                fflush(stdout)
            }
        }
    }

    @Published var preferredVideoChatInputDeviceUID: String {
        didSet {
            if oldValue != self.preferredVideoChatInputDeviceUID {
                self.defaults.set(
                    self.preferredVideoChatInputDeviceUID,
                    forKey: "preferredVideoChatInputDeviceUID"
                )
                self.logger
                    .debug(
                        "Saved video chat input device: \(self.preferredVideoChatInputDeviceUID)"
                    )
                print(
                    "[SETTINGS] Video chat input device: \(self.preferredVideoChatInputDeviceUID)"
                )
                fflush(stdout)
            }
        }
    }

    // 音乐偏好设备
    @Published var preferredMusicOutputDeviceUID: String {
        didSet {
            if oldValue != self.preferredMusicOutputDeviceUID {
                self.defaults.set(
                    self.preferredMusicOutputDeviceUID,
                    forKey: "preferredMusicOutputDeviceUID"
                )
                self.logger
                    .debug("Saved music output device: \(self.preferredMusicOutputDeviceUID)")
                print("[SETTINGS] Music output device: \(self.preferredMusicOutputDeviceUID)")
                fflush(stdout)
            }
        }
    }

    // 游戏偏好设备
    @Published var preferredGamingOutputDeviceUID: String {
        didSet {
            if oldValue != self.preferredGamingOutputDeviceUID {
                self.defaults.set(
                    self.preferredGamingOutputDeviceUID,
                    forKey: "preferredGamingOutputDeviceUID"
                )
                self.logger
                    .debug("Saved gaming output device: \(self.preferredGamingOutputDeviceUID)")
                print("[SETTINGS] Gaming output device: \(self.preferredGamingOutputDeviceUID)")
                fflush(stdout)
            }
        }
    }

    @Published var preferredGamingInputDeviceUID: String {
        didSet {
            if oldValue != self.preferredGamingInputDeviceUID {
                self.defaults.set(
                    self.preferredGamingInputDeviceUID,
                    forKey: "preferredGamingInputDeviceUID"
                )
                self.logger
                    .debug("Saved gaming input device: \(self.preferredGamingInputDeviceUID)")
                print("[SETTINGS] Gaming input device: \(self.preferredGamingInputDeviceUID)")
                fflush(stdout)
            }
        }
    }

    // UI 设置
    @Published var showVolumeSliders: Bool {
        didSet {
            if oldValue != self.showVolumeSliders, !self.isUpdating {
                self.isUpdating = true
                self.defaults.set(self.showVolumeSliders, forKey: "showVolumeSliders")
                self.logger.debug("Saved show volume sliders: \(self.showVolumeSliders)")
                print(
                    "[SETTINGS] Show volume sliders: \(self.showVolumeSliders ? "enabled" : "disabled")"
                )
                fflush(stdout)
                self.isUpdating = false
            }
        }
    }

    @Published var showMicrophoneLevelMeter: Bool {
        didSet {
            if oldValue != self.showMicrophoneLevelMeter, !self.isUpdating {
                self.isUpdating = true
                self.defaults.set(self.showMicrophoneLevelMeter, forKey: "showMicrophoneLevelMeter")
                self.logger
                    .debug("Saved show microphone level meter: \(self.showMicrophoneLevelMeter)")
                print(
                    "[SETTINGS] Show microphone level meter: \(self.showMicrophoneLevelMeter ? "enabled" : "disabled")"
                )
                fflush(stdout)
                self.isUpdating = false
            }
        }
    }

    @Published var useExperimentalUI: Bool {
        didSet {
            if oldValue != self.useExperimentalUI, !self.isUpdating {
                self.isUpdating = true
                self.defaults.set(self.useExperimentalUI, forKey: "useExperimentalUI")
                self.logger.debug("Saved use experimental UI: \(self.useExperimentalUI)")
                print(
                    "[SETTINGS] Use experimental UI: \(self.useExperimentalUI ? "enabled" : "disabled")"
                )
                fflush(stdout)
                self.isUpdating = false
            }
        }
    }

    @Published var launchAtLogin: Bool {
        didSet {
            // 只在值真的改变时才更新
            if oldValue != self.launchAtLogin {
                // Save user preference
                self.defaults.set(self.launchAtLogin, forKey: "launchAtLogin")
                print("[SETTINGS] Launch at login: \(self.launchAtLogin ? "enabled" : "disabled")")
                fflush(stdout)

                // Apply system settings asynchronously
                if self.launchAtLogin {
                    LaunchAtLogin.enable()
                } else {
                    LaunchAtLogin.disable()
                }
            }
        }
    }

    @Published var preferredOutputDeviceUID: String {
        didSet {
            if oldValue != self.preferredOutputDeviceUID {
                self.defaults.set(self.preferredOutputDeviceUID, forKey: "preferredOutputDeviceUID")
                self.logger.debug("Saved preferred output device: \(self.preferredOutputDeviceUID)")
            }
        }
    }

    @Published var preferredInputDeviceUID: String {
        didSet {
            if oldValue != self.preferredInputDeviceUID {
                self.defaults.set(self.preferredInputDeviceUID, forKey: "preferredInputDeviceUID")
                self.logger.debug("Saved preferred input device: \(self.preferredInputDeviceUID)")
            }
        }
    }

    // 添加语音转录文件格式配置
    @Published var transcriptionFormat: String {
        didSet {
            if oldValue != self.transcriptionFormat, !self.isUpdating {
                self.isUpdating = true
                self.defaults.set(self.transcriptionFormat, forKey: "dictationFormat")
                self.logger.debug("Saved transcription format: \(self.transcriptionFormat)")
                print("[SETTINGS] Transcription format: \(self.transcriptionFormat)")
                fflush(stdout)
                self.isUpdating = false
            }
        }
    }

    // 自动复制转录内容到剪贴板
    @Published var autoCopyTranscriptionToClipboard: Bool {
        didSet {
            if oldValue != self.autoCopyTranscriptionToClipboard, !self.isUpdating {
                self.isUpdating = true
                self.defaults.set(
                    self.autoCopyTranscriptionToClipboard,
                    forKey: "autoCopyTranscriptionToClipboard"
                )
                self.logger
                    .debug(
                        "Saved auto copy transcription: \(self.autoCopyTranscriptionToClipboard)"
                    )
                print(
                    "[SETTINGS] Auto copy transcription: \(self.autoCopyTranscriptionToClipboard ? "enabled" : "disabled")"
                )
                fflush(stdout)
                self.isUpdating = false
            }
        }
    }

    // Dictation全局快捷键开关
    @Published var enableDictationShortcut: Bool {
        didSet {
            if oldValue != self.enableDictationShortcut, !self.isUpdating {
                self.isUpdating = true
                self.defaults.set(self.enableDictationShortcut, forKey: "enableDictationShortcut")
                self.logger
                    .debug("Saved dictation shortcut enabled: \(self.enableDictationShortcut)")
                print(
                    "[SETTINGS] Dictation shortcut: \(self.enableDictationShortcut ? "enabled" : "disabled")"
                )
                fflush(stdout)
                self.isUpdating = false

                NotificationCenter.default.post(
                    name: Notification.Name.dictationShortcutSettingsChanged,
                    object: nil
                )
            }
        }
    }

    // Dictation快捷键组合
    @Published var dictationShortcutKeyCombo: String {
        didSet {
            if oldValue != self.dictationShortcutKeyCombo, !self.isUpdating {
                self.isUpdating = true
                self.defaults.set(
                    self.dictationShortcutKeyCombo,
                    forKey: "dictationShortcutKeyCombo"
                )
                self.logger
                    .info(
                        "Dictation shortcut key combo changed to \(self.dictationShortcutKeyCombo, privacy: .public)"
                    )
                print(
                    "[SETTINGS] Dictation shortcut key combo: \(self.dictationShortcutKeyCombo)"
                )
                fflush(stdout)
                self.isUpdating = false

                NotificationCenter.default.post(
                    name: Notification.Name.dictationShortcutSettingsChanged,
                    object: nil
                )
            }
        }
    }

    // 快捷键触发时显示听写页面
    @Published var showDictationPageOnShortcut: Bool {
        didSet {
            if oldValue != self.showDictationPageOnShortcut, !self.isUpdating {
                self.isUpdating = true
                self.defaults.set(
                    self.showDictationPageOnShortcut,
                    forKey: "showDictationPageOnShortcut"
                )
                self.logger
                    .debug(
                        "Saved show dictation page on shortcut: \(self.showDictationPageOnShortcut)"
                    )
                print(
                    "[SETTINGS] Show dictation page on shortcut: \(self.showDictationPageOnShortcut ? "enabled" : "disabled")"
                )
                fflush(stdout)
                self.isUpdating = false

                NotificationCenter.default.post(
                    name: Notification.Name.dictationShortcutSettingsChanged,
                    object: nil
                )
            }
        }
    }

    // 启用听写声音反馈
    @Published var enableDictationSoundFeedback: Bool {
        didSet {
            if oldValue != self.enableDictationSoundFeedback, !self.isUpdating {
                self.isUpdating = true
                self.defaults.set(
                    self.enableDictationSoundFeedback,
                    forKey: "enableDictationSoundFeedback"
                )
                self.logger
                    .debug(
                        "Saved enable dictation sound feedback: \(self.enableDictationSoundFeedback)"
                    )
                print(
                    "[SETTINGS] Dictation sound feedback: \(self.enableDictationSoundFeedback ? "enabled" : "disabled")"
                )
                fflush(stdout)
                self.isUpdating = false
            }
        }
    }

    // 转写输出目录
    @Published var transcriptionOutputDirectory: URL? = nil {
        didSet {
            guard oldValue != self.transcriptionOutputDirectory else { return }
            self.isUpdating = true
            let pathString = self.transcriptionOutputDirectory?.absoluteString ?? ""
            defaults.set(pathString, forKey: "transcriptionOutputDirectory")
            logger.debug("Saved transcription output dir: \(pathString)")
            self.isUpdating = false
        }
    }

    /// Helper for UI display
    var transcriptionOutputDirectoryDisplay: String {
        transcriptionOutputDirectory?.lastPathComponent ?? "Not set"
    }

    // 卡片展开状态 - 默认全部展开
    @Published var isShortcutOpen: Bool = true {
        didSet {
            if oldValue != self.isShortcutOpen {
                self.defaults.set(self.isShortcutOpen, forKey: "isShortcutOpen")
            }
        }
    }

    @Published var isMagicTransformOpen: Bool = true {
        didSet {
            if oldValue != self.isMagicTransformOpen {
                self.defaults.set(self.isMagicTransformOpen, forKey: "isMagicTransformOpen")
            }
        }
    }

    @Published var isEngineOpen: Bool = true {
        didSet {
            if oldValue != self.isEngineOpen {
                self.defaults.set(self.isEngineOpen, forKey: "isEngineOpen")
            }
        }
    }

    @Published var isTranscriptionOutputOpen: Bool = true {
        didSet {
            if oldValue != self.isTranscriptionOutputOpen {
                self.defaults.set(self.isTranscriptionOutputOpen, forKey: "isTranscriptionOutputOpen")
            }
        }
    }

    // 其他卡片展开状态
    @Published var isLaunchOpen: Bool = true {
        didSet {
            if oldValue != self.isLaunchOpen {
                self.defaults.set(self.isLaunchOpen, forKey: "isLaunchOpen")
            }
        }
    }

    @Published var isUpdatesOpen: Bool = true {
        didSet {
            if oldValue != self.isUpdatesOpen {
                self.defaults.set(self.isUpdatesOpen, forKey: "isUpdatesOpen")
            }
        }
    }

    @Published var isSmartSwapsOpen: Bool = true {
        didSet {
            if oldValue != self.isSmartSwapsOpen {
                self.defaults.set(self.isSmartSwapsOpen, forKey: "isSmartSwapsOpen")
            }
        }
    }

    @Published var isAudioDevicesOpen: Bool = true {
        didSet {
            if oldValue != self.isAudioDevicesOpen {
                self.defaults.set(self.isAudioDevicesOpen, forKey: "isAudioDevicesOpen")
            }
        }
    }

    @Published var isThemeOpen: Bool = true {
        didSet {
            if oldValue != self.isThemeOpen {
                self.defaults.set(self.isThemeOpen, forKey: "isThemeOpen")
            }
        }
    }

    @Published var isAppearanceOpen: Bool = true {
        didSet {
            if oldValue != self.isAppearanceOpen {
                self.defaults.set(self.isAppearanceOpen, forKey: "isAppearanceOpen")
            }
        }
    }

    @Published var isBetaOpen: Bool = true {
        didSet {
            if oldValue != self.isBetaOpen {
                self.defaults.set(self.isBetaOpen, forKey: "isBetaOpen")
            }
        }
    }

    @Published var isDebugOpen: Bool = true {
        didSet {
            if oldValue != self.isDebugOpen {
                self.defaults.set(self.isDebugOpen, forKey: "isDebugOpen")
            }
        }
    }

    @Published var isAboutOpen: Bool = true {
        didSet {
            if oldValue != self.isAboutOpen {
                self.defaults.set(self.isAboutOpen, forKey: "isAboutOpen")
            }
        }
    }

    // 添加语音转录语言设置
    @Published var transcriptionLanguage: String {
        didSet {
            if oldValue != self.transcriptionLanguage, !self.isUpdating {
                self.isUpdating = true
                self.defaults.set(self.transcriptionLanguage, forKey: "transcriptionLanguage")
                self.logger.debug("Saved transcription language: \(self.transcriptionLanguage)")
                print(
                    "[SETTINGS] Transcription language: \(self.transcriptionLanguage.isEmpty ? "Auto Detect" : self.transcriptionLanguage)"
                )
                fflush(stdout)
                self.isUpdating = false

                NotificationCenter.default.post(
                    name: Notification.Name("transcriptionLanguageChanged"),
                    object: nil,
                    userInfo: ["language": self.transcriptionLanguage]
                )
            }
        }
    }

    // 添加语音转录文件保存路径配置
    @Published var transcriptionOutputDirectoryURL: URL? {
        didSet {
            if !self.isUpdating {
                self.isUpdating = true
                if let url = self.transcriptionOutputDirectoryURL {
                    if oldValue?.path != url.path {
                        self.defaults.set(url, forKey: "dictationOutputDirectory")
                        self.logger.debug("Saved transcription output directory: \(url.path)")
                        print("[SETTINGS] Transcription output directory: \(url.path)")
                    }
                } else if oldValue != nil {
                    self.defaults.removeObject(forKey: "dictationOutputDirectory")
                    self.logger.debug("Removed transcription output directory setting")
                }
                fflush(stdout)
                self.isUpdating = false
            }
        }
    }

    // 默认音频输出设备
    @Published var defaultOutputDeviceUID: String {
        didSet {
            if oldValue != self.defaultOutputDeviceUID, !self.isUpdating {
                self.isUpdating = true
                self.defaults.set(self.defaultOutputDeviceUID, forKey: "defaultOutputDeviceUID")
                self.logger.debug("Saved default output device: \(self.defaultOutputDeviceUID)")
                print("[SETTINGS] Default output device: \(self.defaultOutputDeviceUID)")
                fflush(stdout)
                self.isUpdating = false
            }
        }
    }

    // 默认音频输入设备
    @Published var defaultInputDeviceUID: String {
        didSet {
            if oldValue != self.defaultInputDeviceUID, !self.isUpdating {
                self.isUpdating = true
                self.defaults.set(self.defaultInputDeviceUID, forKey: "defaultInputDeviceUID")
                self.logger.debug("Saved default input device: \(self.defaultInputDeviceUID)")
                print("[SETTINGS] Default input device: \(self.defaultInputDeviceUID)")
                fflush(stdout)
                self.isUpdating = false
            }
        }
    }

    // 设备偏好属性 - 标准模式
    @Published var preferredStandardInputDeviceName: String? {
        didSet {
            self.defaults.setValue(
                self.preferredStandardInputDeviceName,
                forKey: "preferredStandardInputDeviceName"
            )
            print(
                "[SETTINGS] Standard mode preferred input device: \(self.preferredStandardInputDeviceName ?? "None")"
            )
        }
    }

    @Published var preferredStandardOutputDeviceName: String? {
        didSet {
            self.defaults.setValue(
                self.preferredStandardOutputDeviceName,
                forKey: "preferredStandardOutputDeviceName"
            )
            print(
                "[SETTINGS] Standard mode preferred output device: \(self.preferredStandardOutputDeviceName ?? "None")"
            )
        }
    }

    // 设备偏好属性 - 实验模式
    @Published var preferredExperimentalInputDeviceName: String? {
        didSet {
            self.defaults.setValue(
                self.preferredExperimentalInputDeviceName,
                forKey: "preferredExperimentalInputDeviceName"
            )
            print(
                "[SETTINGS] Experimental mode preferred input device: \(self.preferredExperimentalInputDeviceName ?? "None")"
            )
        }
    }

    @Published var preferredExperimentalOutputDeviceName: String? {
        didSet {
            self.defaults.setValue(
                self.preferredExperimentalOutputDeviceName,
                forKey: "preferredExperimentalOutputDeviceName"
            )
            print(
                "[SETTINGS] Experimental mode preferred output device: \(self.preferredExperimentalOutputDeviceName ?? "None")"
            )
        }
    }

    // Magic Transform 功能设置
    @Published var magicEnabled: Bool {
        didSet {
            if oldValue != self.magicEnabled, !self.isUpdating {
                self.isUpdating = true
                self.defaults.set(self.magicEnabled, forKey: "magicEnabled")
                self.logger.debug("Saved magic enabled: \(self.magicEnabled)")
                print("[SETTINGS] Magic transform: \(self.magicEnabled ? "enabled" : "disabled")")
                fflush(stdout)
                self.isUpdating = false
            }
        }
    }

    @Published var magicPreset: PresetStyle {
        didSet {
            if oldValue != self.magicPreset, !self.isUpdating {
                self.isUpdating = true
                self.defaults.set(self.magicPreset.rawValue, forKey: "magicPreset")
                self.logger.debug("Saved magic preset: \(self.magicPreset.rawValue)")
                print("[SETTINGS] Magic preset: \(self.magicPreset.rawValue)")
                fflush(stdout)
                self.isUpdating = false
            }
        }
    }

    @Published var magicCustomPrompt: String {
        didSet {
            if oldValue != self.magicCustomPrompt, !self.isUpdating {
                self.isUpdating = true
                self.defaults.set(self.magicCustomPrompt, forKey: "magicCustomPrompt")
                self.logger.debug("Saved magic custom prompt: \(self.magicCustomPrompt)")
                print("[SETTINGS] Magic custom prompt updated")
                fflush(stdout)
                self.isUpdating = false
            }
        }
    }

    @Published var selectedTheme: String {
        didSet {
            if oldValue != self.selectedTheme {
                UserDefaults.standard.set(self.selectedTheme, forKey: "selectedTheme")
                NotificationCenter.default.post(name: .appearanceChanged, object: nil)
            }
        }
    }

    private init() {
        // Initialize selectedTheme first
        self.selectedTheme = UserDefaults.standard.string(forKey: "selectedTheme") ?? "system"
        
        // Initialize other properties
        self.launchAtLogin = UserDefaults.standard.bool(forKey: "launchAtLogin")
        self.uiExperimentMode = UIExperimentMode(rawValue: UserDefaults.standard.string(forKey: "uiExperimentMode") ?? "standard") ?? .standard
        
        // Migrate old settings
        self.migrateOldSettings()
        
        // Log initial state
        print("[SETTINGS] Launch at login: \(self.launchAtLogin ? "enabled" : "disabled")")
        print(
            "\u{001B}[36m[SETTINGS]\u{001B}[0m UI experiment mode: \(self.uiExperimentMode.rawValue)"
        )
        fflush(stdout)

        // 初始化操作模式
        let savedModeString = self.defaults.string(forKey: "currentMode") ?? Mode.standard.rawValue
        if let mode = Mode(rawValue: savedModeString) {
            self.currentMode = mode
        } else {
            self.currentMode = .standard
        }

        // 初始化UI实验模式
        let savedUIString = self.defaults.string(forKey: "uiExperimentMode") ?? UIExperimentMode
            .standard
            .rawValue
        self.uiExperimentMode = UIExperimentMode.allCases
            .first { $0.rawValue == savedUIString } ?? .standard

        // Initialize with actual launch agent status
        self.launchAtLogin = LaunchAtLogin.isEnabled

        // Load saved device UIDs
        self.preferredOutputDeviceUID = self.defaults
            .string(forKey: "preferredOutputDeviceUID") ?? ""
        self.preferredInputDeviceUID = self.defaults.string(forKey: "preferredInputDeviceUID") ?? ""

        // 初始化智能设备切换设置
        self.enableSmartSwitching = self.defaults.bool(forKey: "enableSmartSwitching")
        self.preferredVideoChatOutputDeviceUID = self.defaults
            .string(forKey: "preferredVideoChatOutputDeviceUID") ?? ""
        self.preferredVideoChatInputDeviceUID = self.defaults
            .string(forKey: "preferredVideoChatInputDeviceUID") ?? ""
        self.preferredMusicOutputDeviceUID = self.defaults
            .string(forKey: "preferredMusicOutputDeviceUID") ?? ""
        self.preferredGamingOutputDeviceUID = self.defaults
            .string(forKey: "preferredGamingOutputDeviceUID") ?? ""
        self.preferredGamingInputDeviceUID = self.defaults
            .string(forKey: "preferredGamingInputDeviceUID") ?? ""

        // 初始化UI设置
        self.showVolumeSliders = self.defaults.bool(forKey: "showVolumeSliders")
        self.showMicrophoneLevelMeter = self.defaults.bool(forKey: "showMicrophoneLevelMeter")
        self.useExperimentalUI = self.defaults.bool(forKey: "useExperimentalUI")

        // 初始化语音转录设置
        self.transcriptionFormat = self.defaults.string(forKey: "dictationFormat") ?? "txt"
        if let saved = defaults.string(forKey: "transcriptionOutputDirectory"),
           let url = URL(string: saved), !saved.isEmpty {
            self.transcriptionOutputDirectory = url
        }
        self.autoCopyTranscriptionToClipboard = self.defaults
            .bool(forKey: "autoCopyTranscriptionToClipboard")

        // 初始化Dictation快捷键设置
        self.enableDictationShortcut = self.defaults.bool(forKey: "enableDictationShortcut")
        self.dictationShortcutKeyCombo = self.defaults
            .string(forKey: "dictationShortcutKeyCombo") ?? "cmd+u"
        self.showDictationPageOnShortcut = self.defaults.bool(forKey: "showDictationPageOnShortcut")

        // 初始化卡片展开状态 - 全部默认展开
        self.isShortcutOpen = self.defaults.object(forKey: "isShortcutOpen") != nil ? 
            self.defaults.bool(forKey: "isShortcutOpen") : true
        self.isMagicTransformOpen = self.defaults.object(forKey: "isMagicTransformOpen") != nil ? 
            self.defaults.bool(forKey: "isMagicTransformOpen") : true
        self.isEngineOpen = self.defaults.object(forKey: "isEngineOpen") != nil ? 
            self.defaults.bool(forKey: "isEngineOpen") : true
        self.isTranscriptionOutputOpen = self.defaults.object(forKey: "isTranscriptionOutputOpen") != nil ? 
            self.defaults.bool(forKey: "isTranscriptionOutputOpen") : true
        
        // 其他卡片展开状态初始化
        self.isLaunchOpen = self.defaults.object(forKey: "isLaunchOpen") != nil ? 
            self.defaults.bool(forKey: "isLaunchOpen") : true
        self.isUpdatesOpen = self.defaults.object(forKey: "isUpdatesOpen") != nil ? 
            self.defaults.bool(forKey: "isUpdatesOpen") : true
        self.isSmartSwapsOpen = self.defaults.object(forKey: "isSmartSwapsOpen") != nil ? 
            self.defaults.bool(forKey: "isSmartSwapsOpen") : true
        self.isAudioDevicesOpen = self.defaults.object(forKey: "isAudioDevicesOpen") != nil ? 
            self.defaults.bool(forKey: "isAudioDevicesOpen") : true
        self.isThemeOpen = self.defaults.object(forKey: "isThemeOpen") != nil ? 
            self.defaults.bool(forKey: "isThemeOpen") : true
        self.isAppearanceOpen = self.defaults.object(forKey: "isAppearanceOpen") != nil ? 
            self.defaults.bool(forKey: "isAppearanceOpen") : true
        self.isBetaOpen = self.defaults.object(forKey: "isBetaOpen") != nil ? 
            self.defaults.bool(forKey: "isBetaOpen") : true
        self.isDebugOpen = self.defaults.object(forKey: "isDebugOpen") != nil ? 
            self.defaults.bool(forKey: "isDebugOpen") : true
        self.isAboutOpen = self.defaults.object(forKey: "isAboutOpen") != nil ? 
            self.defaults.bool(forKey: "isAboutOpen") : true

        // 初始化默认音频设备设置
        self.defaultOutputDeviceUID = self.defaults.string(forKey: "defaultOutputDeviceUID") ?? ""
        self.defaultInputDeviceUID = self.defaults.string(forKey: "defaultInputDeviceUID") ?? ""

        // 初始化声音反馈设置
        self.enableDictationSoundFeedback = self.defaults
            .object(forKey: "enableDictationSoundFeedback") != nil ?
            self.defaults.bool(forKey: "enableDictationSoundFeedback") : true // 默认启用声音反馈

        // 初始化语音转录语言设置
        self.transcriptionLanguage = self.defaults
            .string(forKey: "transcriptionLanguage") ?? "" // 默认为空字符串，表示自动检测

        // 初始化设备偏好属性
        self.preferredStandardInputDeviceName = self.defaults
            .string(forKey: "preferredStandardInputDeviceName")
        self.preferredStandardOutputDeviceName = self.defaults
            .string(forKey: "preferredStandardOutputDeviceName")
        self.preferredExperimentalInputDeviceName = self.defaults
            .string(forKey: "preferredExperimentalInputDeviceName")
        self.preferredExperimentalOutputDeviceName = self.defaults
            .string(forKey: "preferredExperimentalOutputDeviceName")

        // 初始化Magic Transform设置
        self.magicEnabled = self.defaults.bool(forKey: "magicEnabled")
        let savedPresetString = self.defaults.string(forKey: "magicPreset") ?? PresetStyle.abit
            .rawValue
        self.magicPreset = PresetStyle(rawValue: savedPresetString) ?? .abit
        self.magicCustomPrompt = self.defaults.string(forKey: "magicCustomPrompt") ?? ""

        // 迁移旧数据 - 移到最后，所有属性都初始化后执行
        self.migrateOldSettings()

        // Log initial state
        print("[SETTINGS] Launch at login: \(self.launchAtLogin ? "enabled" : "disabled")")
        print(
            "\u{001B}[36m[SETTINGS]\u{001B}[0m UI experiment mode: \(self.uiExperimentMode.rawValue)"
        )
        fflush(stdout)

        self.selectedTheme = UserDefaults.standard.string(forKey: "selectedTheme") ?? "system"
    }

    // 从UserDefaults.standard迁移设置到带域名的UserDefaults
    private func migrateOldSettings() {
        let keys = [
            // 基本设置
            "currentMode", "uiExperimentMode", "launchAtLogin",
            // 设备设置
            "preferredOutputDeviceUID", "preferredInputDeviceUID",
            "defaultOutputDeviceUID", "defaultInputDeviceUID",
            // 智能切换
            "enableSmartSwitching",
            "preferredVideoChatOutputDeviceUID", "preferredVideoChatInputDeviceUID",
            "preferredMusicOutputDeviceUID",
            "preferredGamingOutputDeviceUID", "preferredGamingInputDeviceUID",
            // UI设置
            "showVolumeSliders", "showMicrophoneLevelMeter", "useExperimentalUI",
            // 语音转录
            "dictationFormat", "dictationOutputDirectory", "autoCopyTranscriptionToClipboard",
            // 快捷键
            "enableDictationShortcut", "dictationShortcutKeyCombo",
            "showDictationPageOnShortcut", "enableDictationSoundFeedback",
            // 偏好设置
            "preferredStandardInputDeviceName", "preferredStandardOutputDeviceName",
            "preferredExperimentalInputDeviceName", "preferredExperimentalOutputDeviceName",
            // 新添加的语音转录语言设置
            "transcriptionLanguage",
            // Magic Transform 设置
            "magicEnabled", "magicPreset", "magicCustomPrompt",
            // 新添加的Transcription Output卡片状态
            "isTranscriptionOutputOpen",
        ]

        var migrated = false

        for key in keys {
            if self.standardDefaults.object(forKey: key) != nil {
                if let value = standardDefaults.object(forKey: key) {
                    self.defaults.set(value, forKey: key)
                    self.standardDefaults.removeObject(forKey: key)
                    self.logger.debug("Migrated setting: \(key)")
                    migrated = true
                }
            }
        }

        if migrated {
            self.standardDefaults.synchronize()
            self.defaults.synchronize()
            self.logger.notice("Settings migrated from standard UserDefaults to ai.tuna.app domain")
        }
    }

    // Method to load default values
    func loadDefaults() {
        // Set default values
        UserDefaults.standard.set("system", forKey: "theme")
        UserDefaults.standard.set(0.7, forKey: "glassStrength")
        UserDefaults.standard.set("system", forKey: "fontScale")
        UserDefaults.standard.set(false, forKey: "reduceMotion")
        UserDefaults.standard.set(false, forKey: "enableBeta")
        UserDefaults.standard.set("", forKey: "whisperAPIKey")

        // Set default values for card expansion states
        UserDefaults.standard.set(true, forKey: "isShortcutOpen")
        UserDefaults.standard.set(true, forKey: "isMagicTransformOpen")
        UserDefaults.standard.set(true, forKey: "isEngineOpen")
        UserDefaults.standard.set(true, forKey: "isTranscriptionOutputOpen")
        UserDefaults.standard.set(true, forKey: "isLaunchOpen")
        UserDefaults.standard.set(true, forKey: "isUpdatesOpen")
        UserDefaults.standard.set(true, forKey: "isSmartSwapsOpen")
        UserDefaults.standard.set(true, forKey: "isAudioDevicesOpen")
        UserDefaults.standard.set(true, forKey: "isThemeOpen")
        UserDefaults.standard.set(true, forKey: "isAppearanceOpen")
        UserDefaults.standard.set(true, forKey: "isBetaOpen")
        UserDefaults.standard.set(true, forKey: "isDebugOpen")
        UserDefaults.standard.set(true, forKey: "isAboutOpen")

        // Reinitialize the instance
        self.isShortcutOpen = true
        self.isMagicTransformOpen = true
        self.isEngineOpen = true
        self.isTranscriptionOutputOpen = true
        self.isLaunchOpen = true
        self.isUpdatesOpen = true
        self.isSmartSwapsOpen = true
        self.isAudioDevicesOpen = true
        self.isThemeOpen = true
        self.isAppearanceOpen = true
        self.isBetaOpen = true
        self.isDebugOpen = true
        self.isAboutOpen = true

        UserDefaults.standard.set("system", forKey: "selectedTheme")
    }
}

// MARK: - UI Settings Extension
// 添加UI设置扩展 - 计算属性而不是存储属性

// @module: SettingsUI
// @created_by_cursor: yes
// @summary: Properties extension for TunaSettings
// @depends_on: TunaSettings.swift

extension TunaSettings {
    // Theme settings
    var theme: String {
        get { UserDefaults.standard.string(forKey: "theme") ?? "system" }
        set { UserDefaults.standard.set(newValue, forKey: "theme") }
    }

    var glassStrength: Double {
        get { UserDefaults.standard.double(forKey: "glassStrength") }
        set { UserDefaults.standard.set(newValue, forKey: "glassStrength") }
    }

    var fontScale: String {
        get { UserDefaults.standard.string(forKey: "fontScale") ?? "system" }
        set { UserDefaults.standard.set(newValue, forKey: "fontScale") }
    }

    var reduceMotion: Bool {
        get { UserDefaults.standard.bool(forKey: "reduceMotion") }
        set { UserDefaults.standard.set(newValue, forKey: "reduceMotion") }
    }

    // Beta features
    var enableBeta: Bool {
        get { UserDefaults.standard.bool(forKey: "enableBeta") }
        set { UserDefaults.standard.set(newValue, forKey: "enableBeta") }
    }

    // Magic Transform settings (already exists but renaming for consistency)
    var magicTransformEnabled: Bool {
        get { self.magicEnabled }
        set { self.magicEnabled = newValue }
    }

    var magicTransformStyle: PresetStyle {
        get { self.magicPreset }
        set { self.magicPreset = newValue }
    }

    // Shortcut settings (aliases to existing properties)
    var shortcutEnabled: Bool {
        get { self.enableDictationShortcut }
        set { self.enableDictationShortcut = newValue }
    }

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
    var whisperAPIKey: String {
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
