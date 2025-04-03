import Foundation
import ServiceManagement
import CoreAudio
import os.log

class TunaSettings: ObservableObject {
    static let shared = TunaSettings()
    private let logger = Logger(subsystem: "com.tuna.app", category: "TunaSettings")
    private var isUpdating = false // 防止循环更新
    
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
    
    private init() {
        // Initialize with actual launch agent status
        self.launchAtLogin = LaunchAtLogin.isEnabled
        
        // Load saved device UIDs
        self.preferredOutputDeviceUID = UserDefaults.standard.string(forKey: "preferredOutputDeviceUID") ?? ""
        self.preferredInputDeviceUID = UserDefaults.standard.string(forKey: "preferredInputDeviceUID") ?? ""
        
        // 初始化语音转录设置
        self.transcriptionFormat = UserDefaults.standard.string(forKey: "dictationFormat") ?? "txt"
        self.transcriptionOutputDirectory = UserDefaults.standard.url(forKey: "dictationOutputDirectory")
        
        // 初始化默认音频设备设置
        self.defaultOutputDeviceUID = UserDefaults.standard.string(forKey: "defaultOutputDeviceUID") ?? ""
        self.defaultInputDeviceUID = UserDefaults.standard.string(forKey: "defaultInputDeviceUID") ?? ""
        
        // Log initial state
        print("[SETTINGS] Launch at login: \(self.launchAtLogin ? "enabled" : "disabled")")
        fflush(stdout)
    }
} 