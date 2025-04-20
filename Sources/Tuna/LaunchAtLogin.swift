import Foundation
import os.log
import ServiceManagement

/// Helper for managing app launch at login
enum LaunchAtLogin {
    private static let logger = Logger(subsystem: "com.tuna.app", category: "LaunchAtLogin")
    private static let queue = DispatchQueue(label: "com.tuna.app.loginItem", qos: .userInitiated)

    /// Enable launch at login
    static func enable() {
        self.queue.async {
            do {
                print("\u{001B}[36m[STARTUP]\u{001B}[0m Adding app to login items")
                try SMAppService.mainApp.register()
                print("\u{001B}[32m[SUCCESS]\u{001B}[0m App added to login items")
            } catch {
                print("\u{001B}[31m[ERROR]\u{001B}[0m Cannot add to login items: \(error)")
                self.logger.error("Failed to enable launch at login: \(error.localizedDescription)")
            }
            fflush(stdout)
        }
    }

    /// Disable launch at login
    static func disable() {
        self.queue.async {
            do {
                print("\u{001B}[36m[STARTUP]\u{001B}[0m Removing app from login items")
                try SMAppService.mainApp.unregister()
                print("\u{001B}[32m[SUCCESS]\u{001B}[0m App removed from login items")
            } catch {
                print("\u{001B}[31m[ERROR]\u{001B}[0m Cannot remove from login items: \(error)")
                self.logger
                    .error("Failed to disable launch at login: \(error.localizedDescription)")
            }
            fflush(stdout)
        }
    }

    /// Check if launch at login is enabled
    static var isEnabled: Bool {
        queue.sync {
            SMAppService.mainApp.status == .enabled
        }
    }
}
