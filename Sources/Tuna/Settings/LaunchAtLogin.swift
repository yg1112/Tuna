import Foundation
import ServiceManagement

class LaunchAtLogin {
    static let shared = LaunchAtLogin()
    private let launcherBundleIdentifier = "com.yukungao.TunaLauncher"
    
    private init() {}
    
    func setEnabled(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to \(enabled ? "enable" : "disable") launch at login: \(error)")
            }
        } else {
            // Fallback for older macOS versions
            if enabled {
                if let url = Bundle.main.bundleURL.appendingPathComponent("Contents/Library/LoginItems/TunaLauncher.app") {
                    try? SMLoginItemSetEnabled(launcherBundleIdentifier as CFString, true)
                }
            } else {
                try? SMLoginItemSetEnabled(launcherBundleIdentifier as CFString, false)
            }
        }
    }
    
    func isEnabled() -> Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        } else {
            // For older versions, we can only check if the login item exists
            let jobs = SMCopyAllJobDictionaries(kSMDomainUserLaunchd).takeRetainedValue() as? [[String: AnyObject]] ?? []
            return jobs.contains { ($0["Label"] as? String) == launcherBundleIdentifier }
        }
    }
} 