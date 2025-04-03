import SwiftUI
import AppKit
import os.log

class SettingsWindowController: NSWindowController {
    private let logger = Logger(subsystem: "com.tuna.app", category: "SettingsWindowController")
    
    // 添加日志刷新函数
    private func flushLogs() {
        print("")  // 添加一个空行确保刷新
        fflush(stdout)
    }
    
    // 添加静态创建方法
    static func createSettingsWindow() -> SettingsWindowController {
        return SettingsWindowController()
    }
    
    convenience init() {
        // Use smaller window size for simplified settings
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Tuna Settings"
        window.center()
        
        // Set window behavior
        window.isReleasedWhenClosed = false
        
        // Key change: Set window level to normal, not floating
        window.level = .normal
        
        // Display settings view
        let settingsView = TunaSettingsView()
        let hostingView = NSHostingView(rootView: settingsView)
        window.contentView = hostingView
        
        self.init(window: window)
        
        // Set window delegate
        window.delegate = self
        
        print("\u{001B}[34m[WINDOW]\u{001B}[0m Settings window created")
        fflush(stdout)
    }
}

// Implement window delegate methods
extension SettingsWindowController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        print("\u{001B}[34m[WINDOW]\u{001B}[0m Settings window closing")
        fflush(stdout)
        
        // Key change: Not using modal window approach
        // NSApp.stopModal()
        
        logger.debug("Settings window closed")
    }
    
    func windowDidBecomeKey(_ notification: Notification) {
        logger.debug("Settings window became active")
    }
} 