import CoreAudio
import Foundation
import os.log
import ServiceManagement
import SwiftUI

// 添加UI实验模式枚举
enum UIExperimentMode: String, CaseIterable, Identifiable {
    case newUI1 = "Tuna UI"

    var id: String { rawValue }

    var description: String {
        switch self {
            case .newUI1:
                "Standard Tuna user interface"
        }
    }
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

    // Engine card expansion state
    @Published var isEngineOpen: Bool = false {
        didSet {
            if oldValue != self.isEngineOpen, !self.isUpdating {
                self.isUpdating = true
                self.defaults.set(self.isEngineOpen, forKey: "isEngineOpen")
                self.logger.debug("Saved engine card state: \(self.isEngineOpen)")
                print(
                    "[SETTINGS] Engine card state: \(self.isEngineOpen ? "expanded" : "collapsed")"
                )
                fflush(stdout)
                self.isUpdating = false
            }
        }
    }

    // Transcription Output card expansion state
    @Published var isTranscriptionOutputOpen: Bool = false {
        didSet {
            if oldValue != self.isTranscriptionOutputOpen, !self.isUpdating {
                self.isUpdating = true
                self.defaults.set(
                    self.isTranscriptionOutputOpen,
                    forKey: "isTranscriptionOutputOpen"
                )
                self.logger
                    .debug(
                        "Saved transcription output card state: \(self.isTranscriptionOutputOpen)"
                    )
                print(
                    "[SETTINGS] Transcription output card state: \(self.isTranscriptionOutputOpen ? "expanded" : "collapsed")"
                )
                fflush(stdout)
                self.isUpdating = false
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
    @Published var transcriptionOutputDirectory: URL? {
        didSet {
            if !self.isUpdating {
                self.isUpdating = true
                if let url = self.transcriptionOutputDirectory {
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

    private init() {
        // 初始化操作模式
        let savedModeString = self.defaults.string(forKey: "currentMode") ?? Mode.standard.rawValue
        if let mode = Mode(rawValue: savedModeString) {
            self.currentMode = mode
        } else {
            self.currentMode = .standard
        }

        // 初始化UI实验模式
        let savedUIString = self.defaults.string(forKey: "uiExperimentMode") ?? UIExperimentMode
            .newUI1
            .rawValue
        self.uiExperimentMode = UIExperimentMode.allCases
            .first { $0.rawValue == savedUIString } ?? .newUI1

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
        self.transcriptionOutputDirectory = self.defaults.url(forKey: "dictationOutputDirectory")
        self.autoCopyTranscriptionToClipboard = self.defaults
            .bool(forKey: "autoCopyTranscriptionToClipboard")

        // 初始化Dictation快捷键设置
        self.enableDictationShortcut = self.defaults.bool(forKey: "enableDictationShortcut")
        self.dictationShortcutKeyCombo = self.defaults
            .string(forKey: "dictationShortcutKeyCombo") ?? "cmd+u"
        self.showDictationPageOnShortcut = self.defaults.bool(forKey: "showDictationPageOnShortcut")

        // 初始化Engine卡片状态
        self.isEngineOpen = self.defaults.bool(forKey: "isEngineOpen")

        // 初始化Transcription Output卡片状态
        self.isTranscriptionOutputOpen = self.defaults.bool(forKey: "isTranscriptionOutputOpen")

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

    // Method to load default values
    func loadDefaults() {
        // Set default values
        UserDefaults.standard.set("system", forKey: "theme")
        UserDefaults.standard.set(0.7, forKey: "glassStrength")
        UserDefaults.standard.set("system", forKey: "fontScale")
        UserDefaults.standard.set(false, forKey: "reduceMotion")
        UserDefaults.standard.set(false, forKey: "enableBeta")
        UserDefaults.standard.set("", forKey: "whisperAPIKey")

        // Other defaults are handled by the original init method
    }
}
