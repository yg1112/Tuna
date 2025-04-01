import Foundation
import ServiceManagement
import CoreAudio
import os.log

class TunaSettings: ObservableObject {
    static let shared = TunaSettings()
    private let logger = Logger(subsystem: "com.tuna.app", category: "TunaSettings")
    
    @Published var launchAtLogin: Bool {
        didSet {
            // Save user preference
            UserDefaults.standard.set(launchAtLogin, forKey: "launchAtLogin")
            print("\u{001B}[36m[SETTINGS]\u{001B}[0m Launch at login: \(launchAtLogin ? "enabled" : "disabled")")
            fflush(stdout)
            
            // Apply system settings asynchronously
            if launchAtLogin {
                LaunchAtLogin.enable()
            } else {
                LaunchAtLogin.disable()
            }
        }
    }
    
    @Published var preferredOutputDeviceUID: String {
        didSet {
            UserDefaults.standard.set(preferredOutputDeviceUID, forKey: "preferredOutputDeviceUID")
            logger.debug("Saved preferred output device: \(self.preferredOutputDeviceUID)")
        }
    }
    
    @Published var preferredInputDeviceUID: String {
        didSet {
            UserDefaults.standard.set(preferredInputDeviceUID, forKey: "preferredInputDeviceUID")
            logger.debug("Saved preferred input device: \(self.preferredInputDeviceUID)")
        }
    }
    
    private init() {
        // Initialize with actual launch agent status
        self.launchAtLogin = LaunchAtLogin.isEnabled
        
        // Load saved device UIDs
        self.preferredOutputDeviceUID = UserDefaults.standard.string(forKey: "preferredOutputDeviceUID") ?? ""
        self.preferredInputDeviceUID = UserDefaults.standard.string(forKey: "preferredInputDeviceUID") ?? ""
        
        // Log initial state
        print("\u{001B}[36m[SETTINGS]\u{001B}[0m Launch at login: \(self.launchAtLogin ? "enabled" : "disabled")")
        fflush(stdout)
    }
} 