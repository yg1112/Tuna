import Foundation
import ServiceManagement
import CoreAudio
import os.log

// 添加UI实验模式枚举
enum UIExperimentMode: String, CaseIterable, Identifiable {
    case newUI1 = "Tuna UI"
    
    var id: String { self.rawValue }
    
    var description: String {
        switch self {
        case .newUI1:
            return "Standard Tuna user interface"
        }
    }
}

// 添加操作模式枚举
enum Mode: String, CaseIterable, Identifiable {
    case standard = "Standard"
    case experimental = "Experimental"
    
    var id: String { self.rawValue }
    
    var description: String {
        switch self {
        case .standard:
            return "The current stable mode"
        case .experimental:
            return "Experimental mode"
        }
    }
}

class TunaSettings: ObservableObject {
    static let shared = TunaSettings()
    private let logger = Logger(subsystem: "com.tuna.app", category: "TunaSettings")
    private var isUpdating = false // 防止循环更新
    
    // 当前操作模式
    @Published var currentMode: Mode = .standard {
        didSet {
            if oldValue != currentMode && !isUpdating {
                isUpdating = true
                UserDefaults.standard.set(currentMode.rawValue, forKey: "currentMode")
                logger.debug("Saved current mode: \(self.currentMode.rawValue)")
                print("[SETTINGS] Current mode: \(self.currentMode.rawValue)")
                fflush(stdout)
                isUpdating = false
            }
        }
    }
    
    // 添加UI实验模式属性
    @Published var uiExperimentMode: UIExperimentMode {
        didSet {
            // 只在值真的改变时才更新
            if oldValue != uiExperimentMode && !isUpdating {
                isUpdating = true
                UserDefaults.standard.set(uiExperimentMode.rawValue, forKey: "uiExperimentMode")
                logger.debug("Saved UI experiment mode: \(self.uiExperimentMode.rawValue)")
                print("\u{001B}[36m[SETTINGS]\u{001B}[0m UI experiment mode: \(self.uiExperimentMode.rawValue)")
                fflush(stdout)
                isUpdating = false
            }
        }
    }
    
    // 智能设备切换
    @Published var enableSmartSwitching: Bool {
        didSet {
            if oldValue != enableSmartSwitching && !isUpdating {
                isUpdating = true
                UserDefaults.standard.set(enableSmartSwitching, forKey: "enableSmartSwitching")
                logger.debug("Saved smart switching: \(self.enableSmartSwitching)")
                print("[SETTINGS] Smart switching: \(enableSmartSwitching ? "enabled" : "disabled")")
                fflush(stdout)
                isUpdating = false
            }
        }
    }
    
    // 视频会议偏好设备
    @Published var preferredVideoChatOutputDeviceUID: String {
        didSet {
            if oldValue != preferredVideoChatOutputDeviceUID && !isUpdating {
                isUpdating = true
                UserDefaults.standard.set(preferredVideoChatOutputDeviceUID, forKey: "preferredVideoChatOutputDeviceUID")
                logger.debug("Saved video chat output device: \(self.preferredVideoChatOutputDeviceUID)")
                print("[SETTINGS] Video chat output device: \(self.preferredVideoChatOutputDeviceUID)")
                fflush(stdout)
                isUpdating = false
            }
        }
    }
    
    @Published var preferredVideoChatInputDeviceUID: String {
        didSet {
            if oldValue != preferredVideoChatInputDeviceUID && !isUpdating {
                isUpdating = true
                UserDefaults.standard.set(preferredVideoChatInputDeviceUID, forKey: "preferredVideoChatInputDeviceUID")
                logger.debug("Saved video chat input device: \(self.preferredVideoChatInputDeviceUID)")
                print("[SETTINGS] Video chat input device: \(self.preferredVideoChatInputDeviceUID)")
                fflush(stdout)
                isUpdating = false
            }
        }
    }
    
    // 音乐偏好设备
    @Published var preferredMusicOutputDeviceUID: String {
        didSet {
            if oldValue != preferredMusicOutputDeviceUID && !isUpdating {
                isUpdating = true
                UserDefaults.standard.set(preferredMusicOutputDeviceUID, forKey: "preferredMusicOutputDeviceUID")
                logger.debug("Saved music output device: \(self.preferredMusicOutputDeviceUID)")
                print("[SETTINGS] Music output device: \(self.preferredMusicOutputDeviceUID)")
                fflush(stdout)
                isUpdating = false
            }
        }
    }
    
    // 游戏偏好设备
    @Published var preferredGamingOutputDeviceUID: String {
        didSet {
            if oldValue != preferredGamingOutputDeviceUID && !isUpdating {
                isUpdating = true
                UserDefaults.standard.set(preferredGamingOutputDeviceUID, forKey: "preferredGamingOutputDeviceUID")
                logger.debug("Saved gaming output device: \(self.preferredGamingOutputDeviceUID)")
                print("[SETTINGS] Gaming output device: \(self.preferredGamingOutputDeviceUID)")
                fflush(stdout)
                isUpdating = false
            }
        }
    }
    
    @Published var preferredGamingInputDeviceUID: String {
        didSet {
            if oldValue != preferredGamingInputDeviceUID && !isUpdating {
                isUpdating = true
                UserDefaults.standard.set(preferredGamingInputDeviceUID, forKey: "preferredGamingInputDeviceUID")
                logger.debug("Saved gaming input device: \(self.preferredGamingInputDeviceUID)")
                print("[SETTINGS] Gaming input device: \(self.preferredGamingInputDeviceUID)")
                fflush(stdout)
                isUpdating = false
            }
        }
    }
    
    // UI 设置
    @Published var showVolumeSliders: Bool {
        didSet {
            if oldValue != showVolumeSliders && !isUpdating {
                isUpdating = true
                UserDefaults.standard.set(showVolumeSliders, forKey: "showVolumeSliders")
                logger.debug("Saved show volume sliders: \(self.showVolumeSliders)")
                print("[SETTINGS] Show volume sliders: \(showVolumeSliders ? "enabled" : "disabled")")
                fflush(stdout)
                isUpdating = false
            }
        }
    }
    
    @Published var showMicrophoneLevelMeter: Bool {
        didSet {
            if oldValue != showMicrophoneLevelMeter && !isUpdating {
                isUpdating = true
                UserDefaults.standard.set(showMicrophoneLevelMeter, forKey: "showMicrophoneLevelMeter")
                logger.debug("Saved show microphone level meter: \(self.showMicrophoneLevelMeter)")
                print("[SETTINGS] Show microphone level meter: \(showMicrophoneLevelMeter ? "enabled" : "disabled")")
                fflush(stdout)
                isUpdating = false
            }
        }
    }
    
    @Published var useExperimentalUI: Bool {
        didSet {
            if oldValue != useExperimentalUI && !isUpdating {
                isUpdating = true
                UserDefaults.standard.set(useExperimentalUI, forKey: "useExperimentalUI")
                logger.debug("Saved use experimental UI: \(self.useExperimentalUI)")
                print("[SETTINGS] Use experimental UI: \(useExperimentalUI ? "enabled" : "disabled")")
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
                UserDefaults.standard.set(launchAtLogin, forKey: "launchAtLogin")
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
                UserDefaults.standard.set(preferredOutputDeviceUID, forKey: "preferredOutputDeviceUID")
                logger.debug("Saved preferred output device: \(self.preferredOutputDeviceUID)")
            }
        }
    }
    
    @Published var preferredInputDeviceUID: String {
        didSet {
            // 只在值真的改变时才更新
            if oldValue != preferredInputDeviceUID {
                UserDefaults.standard.set(preferredInputDeviceUID, forKey: "preferredInputDeviceUID")
                logger.debug("Saved preferred input device: \(self.preferredInputDeviceUID)")
            }
        }
    }
    
    // 添加语音转录文件格式配置
    @Published var transcriptionFormat: String {
        didSet {
            // 只在值真的改变时才更新
            if oldValue != transcriptionFormat && !isUpdating {
                isUpdating = true
                UserDefaults.standard.set(transcriptionFormat, forKey: "dictationFormat")
                logger.debug("Saved transcription format: \(self.transcriptionFormat)")
                print("[SETTINGS] Transcription format: \(self.transcriptionFormat)")
                fflush(stdout)
                isUpdating = false
            }
        }
    }
    
    // 自动复制转录内容到剪贴板
    @Published var autoCopyTranscriptionToClipboard: Bool {
        didSet {
            // 只在值真的改变时才更新
            if oldValue != autoCopyTranscriptionToClipboard && !isUpdating {
                isUpdating = true
                UserDefaults.standard.set(autoCopyTranscriptionToClipboard, forKey: "autoCopyTranscriptionToClipboard")
                logger.debug("Saved auto copy transcription: \(self.autoCopyTranscriptionToClipboard)")
                print("[SETTINGS] Auto copy transcription: \(self.autoCopyTranscriptionToClipboard ? "enabled" : "disabled")")
                fflush(stdout)
                isUpdating = false
            }
        }
    }
    
    // Dictation全局快捷键开关
    @Published var enableDictationShortcut: Bool {
        didSet {
            if oldValue != enableDictationShortcut && !isUpdating {
                isUpdating = true
                UserDefaults.standard.set(enableDictationShortcut, forKey: "enableDictationShortcut")
                logger.debug("Saved dictation shortcut enabled: \(self.enableDictationShortcut)")
                print("[SETTINGS] Dictation shortcut: \(self.enableDictationShortcut ? "enabled" : "disabled")")
                fflush(stdout)
                isUpdating = false
                
                // 发送通知告知设置已变更
                NotificationCenter.default.post(
                    name: NSNotification.Name("dictationShortcutSettingsChanged"),
                    object: nil
                )
            }
        }
    }
    
    // Dictation快捷键组合
    @Published var dictationShortcutKeyCombo: String {
        didSet {
            if oldValue != dictationShortcutKeyCombo && !isUpdating {
                isUpdating = true
                UserDefaults.standard.set(dictationShortcutKeyCombo, forKey: "dictationShortcutKeyCombo")
                logger.debug("Saved dictation shortcut key combo: \(self.dictationShortcutKeyCombo)")
                print("[SETTINGS] Dictation shortcut key combo: \(self.dictationShortcutKeyCombo)")
                fflush(stdout)
                isUpdating = false
                
                // 发送通知告知设置已变更
                NotificationCenter.default.post(
                    name: NSNotification.Name("dictationShortcutSettingsChanged"),
                    object: nil
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
                        UserDefaults.standard.set(url, forKey: "dictationOutputDirectory")
                        logger.debug("Saved transcription output directory: \(url.path)")
                        print("[SETTINGS] Transcription output directory: \(url.path)")
                    }
                } else if oldValue != nil {
                    UserDefaults.standard.removeObject(forKey: "dictationOutputDirectory")
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
            if oldValue != defaultOutputDeviceUID && !isUpdating {
                isUpdating = true
                UserDefaults.standard.set(defaultOutputDeviceUID, forKey: "defaultOutputDeviceUID")
                logger.debug("Saved default output device: \(self.defaultOutputDeviceUID)")
                print("[SETTINGS] Default output device: \(self.defaultOutputDeviceUID)")
                fflush(stdout)
                isUpdating = false
            }
        }
    }
    
    // 默认音频输入设备
    @Published var defaultInputDeviceUID: String {
        didSet {
            // 只在值真的改变时才更新
            if oldValue != defaultInputDeviceUID && !isUpdating {
                isUpdating = true
                UserDefaults.standard.set(defaultInputDeviceUID, forKey: "defaultInputDeviceUID")
                logger.debug("Saved default input device: \(self.defaultInputDeviceUID)")
                print("[SETTINGS] Default input device: \(self.defaultInputDeviceUID)")
                fflush(stdout)
                isUpdating = false
            }
        }
    }
    
    // 设备偏好属性 - 标准模式
    @Published var preferredStandardInputDeviceName: String? {
        didSet {
            UserDefaults.standard.setValue(preferredStandardInputDeviceName, forKey: "preferredStandardInputDeviceName")
            print("[SETTINGS] Standard mode preferred input device: \(preferredStandardInputDeviceName ?? "None")")
        }
    }
    
    @Published var preferredStandardOutputDeviceName: String? {
        didSet {
            UserDefaults.standard.setValue(preferredStandardOutputDeviceName, forKey: "preferredStandardOutputDeviceName")
            print("[SETTINGS] Standard mode preferred output device: \(preferredStandardOutputDeviceName ?? "None")")
        }
    }
    
    // 设备偏好属性 - 实验模式
    @Published var preferredExperimentalInputDeviceName: String? {
        didSet {
            UserDefaults.standard.setValue(preferredExperimentalInputDeviceName, forKey: "preferredExperimentalInputDeviceName")
            print("[SETTINGS] Experimental mode preferred input device: \(preferredExperimentalInputDeviceName ?? "None")")
        }
    }
    
    @Published var preferredExperimentalOutputDeviceName: String? {
        didSet {
            UserDefaults.standard.setValue(preferredExperimentalOutputDeviceName, forKey: "preferredExperimentalOutputDeviceName")
            print("[SETTINGS] Experimental mode preferred output device: \(preferredExperimentalOutputDeviceName ?? "None")")
        }
    }
    
    private init() {
        // 初始化操作模式
        let savedModeString = UserDefaults.standard.string(forKey: "currentMode") ?? Mode.standard.rawValue
        if let mode = Mode(rawValue: savedModeString) {
            self.currentMode = mode
        } else {
            self.currentMode = .standard
        }
        
        // 初始化UI实验模式
        let savedUIString = UserDefaults.standard.string(forKey: "uiExperimentMode") ?? UIExperimentMode.newUI1.rawValue
        self.uiExperimentMode = UIExperimentMode.allCases.first { $0.rawValue == savedUIString } ?? .newUI1
        
        // Initialize with actual launch agent status
        self.launchAtLogin = LaunchAtLogin.isEnabled
        
        // Load saved device UIDs
        self.preferredOutputDeviceUID = UserDefaults.standard.string(forKey: "preferredOutputDeviceUID") ?? ""
        self.preferredInputDeviceUID = UserDefaults.standard.string(forKey: "preferredInputDeviceUID") ?? ""
        
        // 初始化智能设备切换设置
        self.enableSmartSwitching = UserDefaults.standard.bool(forKey: "enableSmartSwitching")
        self.preferredVideoChatOutputDeviceUID = UserDefaults.standard.string(forKey: "preferredVideoChatOutputDeviceUID") ?? ""
        self.preferredVideoChatInputDeviceUID = UserDefaults.standard.string(forKey: "preferredVideoChatInputDeviceUID") ?? ""
        self.preferredMusicOutputDeviceUID = UserDefaults.standard.string(forKey: "preferredMusicOutputDeviceUID") ?? ""
        self.preferredGamingOutputDeviceUID = UserDefaults.standard.string(forKey: "preferredGamingOutputDeviceUID") ?? ""
        self.preferredGamingInputDeviceUID = UserDefaults.standard.string(forKey: "preferredGamingInputDeviceUID") ?? ""
        
        // 初始化UI设置
        self.showVolumeSliders = UserDefaults.standard.bool(forKey: "showVolumeSliders")
        self.showMicrophoneLevelMeter = UserDefaults.standard.bool(forKey: "showMicrophoneLevelMeter")
        self.useExperimentalUI = UserDefaults.standard.bool(forKey: "useExperimentalUI")
        
        // 初始化语音转录设置
        self.transcriptionFormat = UserDefaults.standard.string(forKey: "dictationFormat") ?? "txt"
        self.transcriptionOutputDirectory = UserDefaults.standard.url(forKey: "dictationOutputDirectory")
        self.autoCopyTranscriptionToClipboard = UserDefaults.standard.bool(forKey: "autoCopyTranscriptionToClipboard")
        
        // 初始化Dictation快捷键设置
        self.enableDictationShortcut = UserDefaults.standard.bool(forKey: "enableDictationShortcut")
        self.dictationShortcutKeyCombo = UserDefaults.standard.string(forKey: "dictationShortcutKeyCombo") ?? "option+t"
        
        // 初始化默认音频设备设置
        self.defaultOutputDeviceUID = UserDefaults.standard.string(forKey: "defaultOutputDeviceUID") ?? ""
        self.defaultInputDeviceUID = UserDefaults.standard.string(forKey: "defaultInputDeviceUID") ?? ""
        
        // 初始化设备偏好属性
        self.preferredStandardInputDeviceName = UserDefaults.standard.string(forKey: "preferredStandardInputDeviceName")
        self.preferredStandardOutputDeviceName = UserDefaults.standard.string(forKey: "preferredStandardOutputDeviceName")
        self.preferredExperimentalInputDeviceName = UserDefaults.standard.string(forKey: "preferredExperimentalInputDeviceName")
        self.preferredExperimentalOutputDeviceName = UserDefaults.standard.string(forKey: "preferredExperimentalOutputDeviceName")
        
        // Log initial state
        print("[SETTINGS] Launch at login: \(self.launchAtLogin ? "enabled" : "disabled")")
        print("\u{001B}[36m[SETTINGS]\u{001B}[0m UI experiment mode: \(self.uiExperimentMode.rawValue)")
        fflush(stdout)
    }
} 