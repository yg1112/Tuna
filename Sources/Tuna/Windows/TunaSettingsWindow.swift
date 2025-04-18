import SwiftUI
import AppKit

/// 单例设置窗口，用于在应用中统一管理设置窗口的显示和隐藏
class TunaSettingsWindow {
    // 单例实例
    static let shared = TunaSettingsWindow()
    
    // 窗口引用
    private var windowController: NSWindowController?
    
    // 私有初始化方法，防止外部创建实例
    private init() {}
    
    /// 显示设置窗口
    func show() {
        // 如果窗口控制器已存在，则显示窗口
        if let windowController = self.windowController, let window = windowController.window {
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
            return
        }
        
        // 创建窗口
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 500),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        
        // 设置窗口标题和其他属性
        window.title = "Tuna Settings"
        window.center()
        window.isReleasedWhenClosed = false
        window.identifier = NSUserInterfaceItemIdentifier("TunaSettingsWindow")
        
        // 创建设置视图并设置为窗口内容
        let settingsView = TunaSettingsView()
        let hostingView = NSHostingView(rootView: settingsView)
        window.contentView = hostingView
        
        // 创建窗口控制器并存储引用
        self.windowController = NSWindowController(window: window)
        
        // 显示窗口
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }
    
    /// 隐藏设置窗口
    func hide() {
        windowController?.window?.orderOut(nil)
    }
} 