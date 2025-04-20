import AppKit
import SwiftUI

/// 单例设置窗口，用于在应用中统一管理设置窗口的显示和隐藏
class TunaSettingsWindow: NSWindow {
    // 单例实例
    static let shared = TunaSettingsWindow()

    // 窗口引用
    var windowController: NSWindowController?
    private var rootHostingView: NSHostingView<TunaSettingsView>?
    private var settingsView: TunaSettingsView?
    
    // UI State
    private let uiState = UIState()

    // 侧边栏宽度
    var sidebarWidth: CGFloat {
        120
    }

    // 获取当前窗口的 frame
    var frame: NSRect {
        self.windowController?.window?.frame ?? NSRect(x: 0, y: 0, width: 600, height: 300)
    }

    // 获取内容视图
    var contentView: NSView? {
        self.windowController?.window?.contentView
    }

    // 初始化方法改为内部可见，以便测试可以创建实例
    init() {
        // Initialize with default frame
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 630, height: 400),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        
        self.title = "Tuna Settings"
        self.center()
        
        // Set minimum size to accommodate sidebar and content
        self.minSize = NSSize(width: 630, height: 300)
        
        // Set maximum height based on tallest tab content + padding
        self.maxSize = NSSize(width: 1000, height: 600)
        
        // Enable autosaving of window position and size
        self.setFrameAutosaveName("TunaSettingsWindow")
        
        // Create and set content view
        let settingsView = TunaSettingsView()
        let hostingView = NSHostingView(
            rootView: settingsView
                .environmentObject(TunaSettings.shared)
                .environmentObject(AudioManager.shared)
                .environmentObject(uiState)
        )
        
        self.contentView = hostingView
        self.settingsView = settingsView
        self.rootHostingView = hostingView
    }

    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return true
    }

    /// 显示设置窗口
    func show() {
        NSApp.activate(ignoringOtherApps: true)
        self.makeKeyAndOrderFront(nil)
    }

    /// 隐藏设置窗口
    func hide() {
        self.orderOut(nil)
    }

    /// 切换到指定的标签页
    func show(tab: SettingsTab) {
        // 实现标签切换的辅助方法，用于测试
        if let hostingView = rootHostingView {
            // 使用反射机制更新视图状态
            // 注意：这是为测试而实现的简化方法
            let mirror = Mirror(reflecting: hostingView.rootView)
            for child in mirror.children {
                if child.label == "_selectedTab" {
                    if let binding = child.value as? Binding<SettingsTab> {
                        binding.wrappedValue = tab
                        break
                    }
                }
            }

            // 标签切换后调整窗口高度
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.adjustWindowHeight()
            }
        }

        // 确保窗口显示
        self.show()
    }

    /// 调整窗口高度以适应内容
    private func adjustWindowHeight() {
        guard let hostingView = rootHostingView, let window = windowController?.window else {
            return
        }

        // 获取内容的理想尺寸
        let idealSize = hostingView.intrinsicContentSize

        // 计算理想高度，降低约 40%，但确保能显示全部内容
        // 对于内容较多的标签页（如 Audio），不缩减高度以确保内容可见
        let contentSize = hostingView.fittingSize.height
        let reducedHeight = idealSize.height * 0.6

        // 确保高度不小于内容高度，但不超过最大高度
        let idealHeight = min(max(contentSize + 40, reducedHeight), 800)

        // 设置窗口大小
        var frame = window.frame
        let oldHeight = frame.size.height
        let newHeight = idealHeight

        frame.origin.y += (oldHeight - newHeight)
        frame.size.height = newHeight

        window.setFrame(frame, display: true, animate: true)
    }
}
