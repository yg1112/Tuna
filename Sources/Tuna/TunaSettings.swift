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
            if oldValue != currentMode, !isUpdating {
                isUpdating = true
                defaults.set(currentMode.rawValue, forKey: "currentMode")
                logger.debug("Saved current mode: \(currentMode.rawValue)")
                print("[SETTINGS] Current mode: \(currentMode.rawValue)")
                fflush(stdout)
                isUpdating = false
            }
        }
    }

    // 添加UI实验模式属性
    @Published var uiExperimentMode: UIExperimentMode {
        didSet {
            // 只在值真的改变时才更新
            if oldValue != uiExperimentMode, !isUpdating {
                isUpdating = true
                defaults.set(uiExperimentMode.rawValue, forKey: "uiExperimentMode")
                logger.debug("Saved UI experiment mode: \(uiExperimentMode.rawValue)")
                print(
                    "\u{001B}[36m[SETTINGS]\u{001B}[0m UI experiment mode: \(uiExperimentMode.rawValue)"
                )
                fflush(stdout)
                isUpdating = false
            }
        }
    }

    // 智能设备切换
    @Published var enableSmartSwitching: Bool {
        didSet {
            if oldValue != enableSmartSwitching, !isUpdating {
                isUpdating = true
                defaults.set(enableSmartSwitching, forKey: "enableSmartSwitching")
                logger.debug("Saved smart switching: \(enableSmartSwitching)")
                print(
                    "[SETTINGS] Smart switching: \(enableSmartSwitching ? "enabled" : "disabled")"
                )
                fflush(stdout)
                isUpdating = false
            }
        }
    }

    // 视频会议偏好设备
    @Published var preferredVideoChatOutputDeviceUID: String {
        didSet {
            if oldValue != preferredVideoChatOutputDeviceUID, !isUpdating {
                isUpdating = true
                defaults.set(
                    preferredVideoChatOutputDeviceUID,
                    forKey: "preferredVideoChatOutputDeviceUID"
                )
                logger
                    .debug(
                        "Saved video chat output device: \(preferredVideoChatOutputDeviceUID)"
                    )
                print(
                    "[SETTINGS] Video chat output device: \(preferredVideoChatOutputDeviceUID)"
                )
                fflush(stdout)
                isUpdating = false
            }
        }
    }

    @Published var preferredVideoChatInputDeviceUID: String {
        didSet {
            if oldValue != preferredVideoChatInputDeviceUID, !isUpdating {
                isUpdating = true
                defaults.set(
                    preferredVideoChatInputDeviceUID,
                    forKey: "preferredVideoChatInputDeviceUID"
                )
                logger
                    .debug(
                        "Saved video chat input device: \(preferredVideoChatInputDeviceUID)"
                    )
                print(
                    "[SETTINGS] Video chat input device: \(preferredVideoChatInputDeviceUID)"
                )
                fflush(stdout)
                isUpdating = false
            }
        }
    }

    // 音乐偏好设备
    @Published var preferredMusicOutputDeviceUID: String {
        didSet {
            if oldValue != preferredMusicOutputDeviceUID, !isUpdating {
                isUpdating = true
                defaults.set(
                    preferredMusicOutputDeviceUID,
                    forKey: "preferredMusicOutputDeviceUID"
                )
                logger
                    .debug("Saved music output device: \(preferredMusicOutputDeviceUID)")
                print("[SETTINGS] Music output device: \(preferredMusicOutputDeviceUID)")
                fflush(stdout)
                isUpdating = false
            }
        }
    }

    // 游戏偏好设备
    @Published var preferredGamingOutputDeviceUID: String {
        didSet {
            if oldValue != preferredGamingOutputDeviceUID, !isUpdating {
                isUpdating = true
                defaults.set(
                    preferredGamingOutputDeviceUID,
                    forKey: "preferredGamingOutputDeviceUID"
                )
                logger
                    .debug("Saved gaming output device: \(preferredGamingOutputDeviceUID)")
                print("[SETTINGS] Gaming output device: \(preferredGamingOutputDeviceUID)")
                fflush(stdout)
                isUpdating = false
            }
        }
    }

    @Published var preferredGamingInputDeviceUID: String {
        didSet {
            if oldValue != preferredGamingInputDeviceUID, !isUpdating {
                isUpdating = true
                defaults.set(
                    preferredGamingInputDeviceUID,
                    forKey: "preferredGamingInputDeviceUID"
                )
                logger
                    .debug("Saved gaming input device: \(preferredGamingInputDeviceUID)")
                print("[SETTINGS] Gaming input device: \(preferredGamingInputDeviceUID)")
                fflush(stdout)
                isUpdating = false
            }
        }
    }

    // UI 设置
    @Published var showVolumeSliders: Bool {
        didSet {
            if oldValue != showVolumeSliders, !isUpdating {
                isUpdating = true
                defaults.set(showVolumeSliders, forKey: "showVolumeSliders")
                logger.debug("Saved show volume sliders: \(showVolumeSliders)")
                print(
                    "[SETTINGS] Show volume sliders: \(showVolumeSliders ? "enabled" : "disabled")"
                )
                fflush(stdout)
                isUpdating = false
            }
        }
    }

    @Published var showMicrophoneLevelMeter: Bool {
        didSet {
            if oldValue != showMicrophoneLevelMeter, !isUpdating {
                isUpdating = true
                defaults.set(showMicrophoneLevelMeter, forKey: "showMicrophoneLevelMeter")
                logger
                    .debug("Saved show microphone level meter: \(showMicrophoneLevelMeter)")
                print(
                    "[SETTINGS] Show microphone level meter: \(showMicrophoneLevelMeter ? "enabled" : "disabled")"
                )
                fflush(stdout)
                isUpdating = false
            }
        }
    }

    @Published var useExperimentalUI: Bool {
        didSet {
            if oldValue != useExperimentalUI, !isUpdating {
                isUpdating = true
                defaults.set(useExperimentalUI, forKey: "useExperimentalUI")
                logger.debug("Saved use experimental UI: \(useExperimentalUI)")
                print(
                    "[SETTINGS] Use experimental UI: \(useExperimentalUI ? "enabled" : "disabled")"
                )
                fflush(stdout)
                isUpdating = false
            }
        }
    }

    @Published var launchAtLogin: Bool {
        didSet {
            // 只在值真的改变时才更新
            if oldValue != launchAtLogin {
                // Save user preference
                defaults.set(launchAtLogin, forKey: "launchAtLogin")
                print("[SETTINGS] Launch at login: \(launchAtLogin ? "enabled" : "disabled")")
                fflush(stdout)

                // Apply system settings asynchronously
                if launchAtLogin {
                    LaunchAtLogin.enable()
                } else {
                    LaunchAtLogin.disable()
                }
            }
        }
    }

    @Published var preferredOutputDeviceUID: String {
        didSet {
            // 只在值真的改变时才更新
            if oldValue != preferredOutputDeviceUID {
                defaults.set(preferredOutputDeviceUID, forKey: "preferredOutputDeviceUID")
                logger.debug("Saved preferred output device: \(preferredOutputDeviceUID)")
            }
        }
    }

    @Published var preferredInputDeviceUID: String {
        didSet {
            // 只在值真的改变时才更新
            if oldValue != preferredInputDeviceUID {
                defaults.set(preferredInputDeviceUID, forKey: "preferredInputDeviceUID")
                logger.debug("Saved preferred input device: \(preferredInputDeviceUID)")
            }
        }
    }

    // 添加语音转录文件格式配置
    @Published var transcriptionFormat: String {
        didSet {
            // 只在值真的改变时才更新
            if oldValue != transcriptionFormat, !isUpdating {
                isUpdating = true
                defaults.set(transcriptionFormat, forKey: "dictationFormat")
                logger.debug("Saved transcription format: \(transcriptionFormat)")
                print("[SETTINGS] Transcription format: \(transcriptionFormat)")
                fflush(stdout)
                isUpdating = false
            }
        }
    }

    // 自动复制转录内容到剪贴板
    @Published var autoCopyTranscriptionToClipboard: Bool {
        didSet {
            // 只在值真的改变时才更新
            if oldValue != autoCopyTranscriptionToClipboard, !isUpdating {
                isUpdating = true
                defaults.set(
                    autoCopyTranscriptionToClipboard,
                    forKey: "autoCopyTranscriptionToClipboard"
                )
                logger
                    .debug(
                        "Saved auto copy transcription: \(autoCopyTranscriptionToClipboard)"
                    )
                print(
                    "[SETTINGS] Auto copy transcription: \(autoCopyTranscriptionToClipboard ? "enabled" : "disabled")"
                )
                fflush(stdout)
                isUpdating = false
            }
        }
    }

    // Dictation全局快捷键开关
    @Published var enableDictationShortcut: Bool {
        didSet {
            if oldValue != enableDictationShortcut, !isUpdating {
                isUpdating = true
                defaults.set(enableDictationShortcut, forKey: "enableDictationShortcut")
                logger
                    .debug("Saved dictation shortcut enabled: \(enableDictationShortcut)")
                print(
                    "[SETTINGS] Dictation shortcut: \(enableDictationShortcut ? "enabled" : "disabled")"
                )
                fflush(stdout)
                isUpdating = false

                // 发送通知告知设置已变更
                NotificationCenter.default.post(
                    name: Notification.Name.dictationShortcutSettingsChanged,
                    object: nil
                )
            }
        }
    }

    // Dictation快捷键组合
    @Published var dictationShortcutKeyCombo: String = "cmd+u" {
        didSet {
            if oldValue != dictationShortcutKeyCombo {
                logger
                    .info(
                        "Dictation shortcut key combo changed to \(dictationShortcutKeyCombo, privacy: .public)"
                    )

                // 保存设置到UserDefaults
                defaults.set(
                    dictationShortcutKeyCombo,
                    forKey: "dictationShortcutKeyCombo"
                )
                objectWillChange.send()

                // 通知快捷键管理器 - 使用dictationShortcutSettingsChanged通知名
                NotificationCenter.default.post(
                    name: Notification.Name.dictationShortcutSettingsChanged,
                    object: nil,
                    userInfo: [
                        "setting": "dictationShortcutKeyCombo",
                        "value": dictationShortcutKeyCombo,
                    ]
                )
            }
        }
    }

    // 快捷键触发时显示听写页面
    @Published var showDictationPageOnShortcut: Bool {
        didSet {
            if oldValue != showDictationPageOnShortcut, !isUpdating {
                isUpdating = true
                defaults.set(
                    showDictationPageOnShortcut,
                    forKey: "showDictationPageOnShortcut"
                )
                logger
                    .debug(
                        "Saved show dictation page on shortcut: \(showDictationPageOnShortcut)"
                    )
                print(
                    "[SETTINGS] Show dictation page on shortcut: \(showDictationPageOnShortcut ? "enabled" : "disabled")"
                )
                fflush(stdout)
                isUpdating = false

                // 发送通知告知设置已变更
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
            if oldValue != enableDictationSoundFeedback, !isUpdating {
                isUpdating = true
                defaults.set(
                    enableDictationSoundFeedback,
                    forKey: "enableDictationSoundFeedback"
                )
                logger
                    .debug(
                        "Saved enable dictation sound feedback: \(enableDictationSoundFeedback)"
                    )
                print(
                    "[SETTINGS] Dictation sound feedback: \(enableDictationSoundFeedback ? "enabled" : "disabled")"
                )
                fflush(stdout)
                isUpdating = false
            }
        }
    }

    // Engine card expansion state
    @Published var isEngineOpen: Bool = false {
        didSet {
            if oldValue != isEngineOpen, !isUpdating {
                isUpdating = true
                defaults.set(isEngineOpen, forKey: "isEngineOpen")
                logger.debug("Saved engine card state: \(isEngineOpen)")
                print(
                    "[SETTINGS] Engine card state: \(isEngineOpen ? "expanded" : "collapsed")"
                )
                fflush(stdout)
                isUpdating = false
            }
        }
    }

    // 添加语音转录语言设置
    @Published var transcriptionLanguage: String {
        didSet {
            if oldValue != transcriptionLanguage, !isUpdating {
                isUpdating = true
                defaults.set(transcriptionLanguage, forKey: "transcriptionLanguage")
                logger.debug("Saved transcription language: \(transcriptionLanguage)")
                print(
                    "[SETTINGS] Transcription language: \(transcriptionLanguage.isEmpty ? "Auto Detect" : transcriptionLanguage)"
                )
                fflush(stdout)
                isUpdating = false

                // 发送通知告知设置已变更
                NotificationCenter.default.post(
                    name: Notification.Name("transcriptionLanguageChanged"),
                    object: nil,
                    userInfo: ["language": transcriptionLanguage]
                )
            }
        }
    }

    // 添加语音转录文件保存路径配置
    @Published var transcriptionOutputDirectory: URL? {
        didSet {
            if !isUpdating {
                isUpdating = true
                if let url = transcriptionOutputDirectory {
                    if oldValue?.path != url.path {
                        defaults.set(url, forKey: "dictationOutputDirectory")
                        logger.debug("Saved transcription output directory: \(url.path)")
                        print("[SETTINGS] Transcription output directory: \(url.path)")
                    }
                } else if oldValue != nil {
                    defaults.removeObject(forKey: "dictationOutputDirectory")
                    logger.debug("Removed transcription output directory setting")
                }
                fflush(stdout)
                isUpdating = false
            }
        }
    }

    // 默认音频输出设备
    @Published var defaultOutputDeviceUID: String {
        didSet {
            // 只在值真的改变时才更新
            if oldValue != defaultOutputDeviceUID, !isUpdating {
                isUpdating = true
                defaults.set(defaultOutputDeviceUID, forKey: "defaultOutputDeviceUID")
                logger.debug("Saved default output device: \(defaultOutputDeviceUID)")
                print("[SETTINGS] Default output device: \(defaultOutputDeviceUID)")
                fflush(stdout)
                isUpdating = false
            }
        }
    }

    // 默认音频输入设备
    @Published var defaultInputDeviceUID: String {
        didSet {
            // 只在值真的改变时才更新
            if oldValue != defaultInputDeviceUID, !isUpdating {
                isUpdating = true
                defaults.set(defaultInputDeviceUID, forKey: "defaultInputDeviceUID")
                logger.debug("Saved default input device: \(defaultInputDeviceUID)")
                print("[SETTINGS] Default input device: \(defaultInputDeviceUID)")
                fflush(stdout)
                isUpdating = false
            }
        }
    }

    // 设备偏好属性 - 标准模式
    @Published var preferredStandardInputDeviceName: String? {
        didSet {
            defaults.setValue(
                preferredStandardInputDeviceName,
                forKey: "preferredStandardInputDeviceName"
            )
            print(
                "[SETTINGS] Standard mode preferred input device: \(preferredStandardInputDeviceName ?? "None")"
            )
        }
    }

    @Published var preferredStandardOutputDeviceName: String? {
        didSet {
            defaults.setValue(
                preferredStandardOutputDeviceName,
                forKey: "preferredStandardOutputDeviceName"
            )
            print(
                "[SETTINGS] Standard mode preferred output device: \(preferredStandardOutputDeviceName ?? "None")"
            )
        }
    }

    // 设备偏好属性 - 实验模式
    @Published var preferredExperimentalInputDeviceName: String? {
        didSet {
            defaults.setValue(
                preferredExperimentalInputDeviceName,
                forKey: "preferredExperimentalInputDeviceName"
            )
            print(
                "[SETTINGS] Experimental mode preferred input device: \(preferredExperimentalInputDeviceName ?? "None")"
            )
        }
    }

    @Published var preferredExperimentalOutputDeviceName: String? {
        didSet {
            defaults.setValue(
                preferredExperimentalOutputDeviceName,
                forKey: "preferredExperimentalOutputDeviceName"
            )
            print(
                "[SETTINGS] Experimental mode preferred output device: \(preferredExperimentalOutputDeviceName ?? "None")"
            )
        }
    }

    // Magic Transform 功能设置
    @Published var magicEnabled: Bool {
        didSet {
            if oldValue != magicEnabled, !isUpdating {
                isUpdating = true
                defaults.set(magicEnabled, forKey: "magicEnabled")
                logger.debug("Saved magic enabled: \(magicEnabled)")
                print("[SETTINGS] Magic transform: \(magicEnabled ? "enabled" : "disabled")")
                fflush(stdout)
                isUpdating = false
            }
        }
    }

    @Published var magicPreset: PresetStyle {
        didSet {
            if oldValue != magicPreset, !isUpdating {
                isUpdating = true
                defaults.set(magicPreset.rawValue, forKey: "magicPreset")
                logger.debug("Saved magic preset: \(magicPreset.rawValue)")
                print("[SETTINGS] Magic preset: \(magicPreset.rawValue)")
                fflush(stdout)
                isUpdating = false
            }
        }
    }

    @Published var magicCustomPrompt: String {
        didSet {
            if oldValue != magicCustomPrompt, !isUpdating {
                isUpdating = true
                defaults.set(magicCustomPrompt, forKey: "magicCustomPrompt")
                logger.debug("Saved magic custom prompt: \(magicCustomPrompt)")
                print("[SETTINGS] Magic custom prompt updated")
                fflush(stdout)
                isUpdating = false
            }
        }
    }

    private init() {
        // 初始化操作模式
        let savedModeString = defaults.string(forKey: "currentMode") ?? Mode.standard.rawValue
        if let mode = Mode(rawValue: savedModeString) {
            currentMode = mode
        } else {
            currentMode = .standard
        }

        // 初始化UI实验模式
        let savedUIString = defaults.string(forKey: "uiExperimentMode") ?? UIExperimentMode
            .newUI1
            .rawValue
        uiExperimentMode = UIExperimentMode.allCases
            .first { $0.rawValue == savedUIString } ?? .newUI1

        // Initialize with actual launch agent status
        launchAtLogin = LaunchAtLogin.isEnabled

        // Load saved device UIDs
        preferredOutputDeviceUID = defaults
            .string(forKey: "preferredOutputDeviceUID") ?? ""
        preferredInputDeviceUID = defaults.string(forKey: "preferredInputDeviceUID") ?? ""

        // 初始化智能设备切换设置
        enableSmartSwitching = defaults.bool(forKey: "enableSmartSwitching")
        preferredVideoChatOutputDeviceUID = defaults
            .string(forKey: "preferredVideoChatOutputDeviceUID") ?? ""
        preferredVideoChatInputDeviceUID = defaults
            .string(forKey: "preferredVideoChatInputDeviceUID") ?? ""
        preferredMusicOutputDeviceUID = defaults
            .string(forKey: "preferredMusicOutputDeviceUID") ?? ""
        preferredGamingOutputDeviceUID = defaults
            .string(forKey: "preferredGamingOutputDeviceUID") ?? ""
        preferredGamingInputDeviceUID = defaults
            .string(forKey: "preferredGamingInputDeviceUID") ?? ""

        // 初始化UI设置
        showVolumeSliders = defaults.bool(forKey: "showVolumeSliders")
        showMicrophoneLevelMeter = defaults.bool(forKey: "showMicrophoneLevelMeter")
        useExperimentalUI = defaults.bool(forKey: "useExperimentalUI")

        // 初始化语音转录设置
        transcriptionFormat = defaults.string(forKey: "dictationFormat") ?? "txt"
        transcriptionOutputDirectory = defaults.url(forKey: "dictationOutputDirectory")
        autoCopyTranscriptionToClipboard = defaults
            .bool(forKey: "autoCopyTranscriptionToClipboard")

        // 初始化Dictation快捷键设置
        enableDictationShortcut = defaults.bool(forKey: "enableDictationShortcut")
        dictationShortcutKeyCombo = defaults
            .string(forKey: "dictationShortcutKeyCombo") ?? "cmd+u"
        showDictationPageOnShortcut = defaults.bool(forKey: "showDictationPageOnShortcut")

        // 初始化Engine卡片状态
        isEngineOpen = defaults.bool(forKey: "isEngineOpen")

        // 初始化默认音频设备设置
        defaultOutputDeviceUID = defaults.string(forKey: "defaultOutputDeviceUID") ?? ""
        defaultInputDeviceUID = defaults.string(forKey: "defaultInputDeviceUID") ?? ""

        // 初始化声音反馈设置
        enableDictationSoundFeedback = defaults
            .object(forKey: "enableDictationSoundFeedback") != nil ?
            defaults.bool(forKey: "enableDictationSoundFeedback") : true // 默认启用声音反馈

        // 初始化语音转录语言设置
        transcriptionLanguage = defaults
            .string(forKey: "transcriptionLanguage") ?? "" // 默认为空字符串，表示自动检测

        // 初始化设备偏好属性
        preferredStandardInputDeviceName = defaults
            .string(forKey: "preferredStandardInputDeviceName")
        preferredStandardOutputDeviceName = defaults
            .string(forKey: "preferredStandardOutputDeviceName")
        preferredExperimentalInputDeviceName = defaults
            .string(forKey: "preferredExperimentalInputDeviceName")
        preferredExperimentalOutputDeviceName = defaults
            .string(forKey: "preferredExperimentalOutputDeviceName")

        // 初始化Magic Transform设置
        magicEnabled = defaults.bool(forKey: "magicEnabled")
        let savedPresetString = defaults.string(forKey: "magicPreset") ?? PresetStyle.abit
            .rawValue
        magicPreset = PresetStyle(rawValue: savedPresetString) ?? .abit
        magicCustomPrompt = defaults.string(forKey: "magicCustomPrompt") ?? ""

        // 迁移旧数据 - 移到最后，所有属性都初始化后执行
        migrateOldSettings()

        // Log initial state
        print("[SETTINGS] Launch at login: \(launchAtLogin ? "enabled" : "disabled")")
        print(
            "\u{001B}[36m[SETTINGS]\u{001B}[0m UI experiment mode: \(uiExperimentMode.rawValue)"
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
        ]

        var migrated = false

        for key in keys {
            if standardDefaults.object(forKey: key) != nil {
                if let value = standardDefaults.object(forKey: key) {
                    defaults.set(value, forKey: key)
                    standardDefaults.removeObject(forKey: key)
                    logger.debug("Migrated setting: \(key)")
                    migrated = true
                }
            }
        }

        if migrated {
            standardDefaults.synchronize()
            defaults.synchronize()
            logger.notice("Settings migrated from standard UserDefaults to ai.tuna.app domain")
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
        get { magicEnabled }
        set { magicEnabled = newValue }
    }

    var magicTransformStyle: PresetStyle {
        get { magicPreset }
        set { magicPreset = newValue }
    }

    // Shortcut settings (aliases to existing properties)
    var shortcutEnabled: Bool {
        get { enableDictationShortcut }
        set { enableDictationShortcut = newValue }
    }

    var shortcutKey: String {
        get { dictationShortcutKeyCombo }
        set { dictationShortcutKeyCombo = newValue }
    }

    // Smart Swaps alias
    var smartSwaps: Bool {
        get { enableSmartSwitching }
        set { enableSmartSwitching = newValue }
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
