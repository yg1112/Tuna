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
        // 调整窗口尺寸以适应精简后的设置选项
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 480),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Tuna Settings"
        window.center()
        
        // Set window behavior
        window.isReleasedWhenClosed = false
        
        // Set window level to normal, not floating
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
        
        logger.debug("Settings window closed")
    }
    
    func windowDidBecomeKey(_ notification: Notification) {
        logger.debug("Settings window became active")
    }
} 