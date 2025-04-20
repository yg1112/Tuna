import Cocoa
import os.log
import SwiftUI

// 管理快捷键触发的QuickDictation窗口
class QuickDictationWindow {
    static let shared = QuickDictationWindow()

    private var windowController: NSWindowController?
    private let logger = Logger(subsystem: "ai.tuna", category: "QuickDictation")

    // 显示快速听写窗口
    func show() {
        // 如果窗口已存在，确保其可见并处于前台
        if let controller = windowController, let window = controller.window {
            window.orderFrontRegardless()
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        // 创建新窗口
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 220),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        // 设置窗口属性
        window.title = "Quick Dictation"
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.center()
        window.setFrameAutosaveName("QuickDictationWindow")

        // 创建内容视图
        let contentView = QuickDictationView()
        let hostingView = NSHostingView(rootView: contentView)
        window.contentView = hostingView

        // 创建窗口控制器
        self.windowController = NSWindowController(window: window)

        // 显示窗口
        self.windowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)

        self.logger.notice("QuickDictation窗口已显示")
    }

    // 关闭窗口
    func close() {
        self.windowController?.close()
        self.windowController = nil
        self.logger.notice("QuickDictation窗口已关闭")
    }

    // 检查窗口是否可见
    var isVisible: Bool {
        guard let window = windowController?.window else { return false }
        return window.isVisible
    }

    // 切换窗口的可见性
    func toggle() {
        if self.isVisible {
            self.close()
        } else {
            self.show()
        }
    }
}

// 扩展通知名称
extension Notification.Name {
    static let showQuickDictation = Notification.Name("showQuickDictation")
    static let closeQuickDictation = Notification.Name("closeQuickDictation")
}
