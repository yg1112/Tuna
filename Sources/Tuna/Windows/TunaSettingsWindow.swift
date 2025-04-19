import SwiftUI
import AppKit

/// 单例设置窗口，用于在应用中统一管理设置窗口的显示和隐藏
class TunaSettingsWindow {
    // 单例实例
    static let shared = TunaSettingsWindow()
    
    // 窗口引用
    internal var windowController: NSWindowController?
    private var rootHostingView: NSHostingView<TunaSettingsView>?
    
    // 侧边栏宽度
    var sidebarWidth: CGFloat {
        return 120
    }
    
    // 获取当前窗口的 frame
    var frame: NSRect {
        return windowController?.window?.frame ?? NSRect(x: 0, y: 0, width: 600, height: 300)
    }
    
    // 获取内容视图
    var contentView: NSView? {
        return windowController?.window?.contentView
    }
    
    // 初始化方法改为内部可见，以便测试可以创建实例
    internal init() {}
    
    /// 显示设置窗口
    func show() {
        // 如果窗口控制器已存在，则显示窗口
        if let windowController = self.windowController, let window = windowController.window {
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
            return
        }
        
        // 创建窗口 - 初始高度设置为较低值，加载后会自动调整
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 300),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        // 设置窗口标题和其他属性
        window.title = "Tuna Settings"
        window.center()
        window.isReleasedWhenClosed = false
        window.identifier = NSUserInterfaceItemIdentifier("TunaSettingsWindow")
        window.minSize = NSSize(width: 600, height: 300)
        window.maxSize = NSSize(width: 800, height: 800)
        
        // 创建设置视图并设置为窗口内容
        let settingsView = TunaSettingsView()
        let hostingView = NSHostingView(rootView: settingsView)
        window.contentView = hostingView
        self.rootHostingView = hostingView
        
        // 创建窗口控制器并存储引用
        self.windowController = NSWindowController(window: window)
        
        // 显示窗口
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        
        // 窗口显示后，计算并设置最佳高度
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.adjustWindowHeight()
        }
    }
    
    /// 隐藏设置窗口
    func hide() {
        windowController?.window?.orderOut(nil)
    }
    
    /// 切换到指定的标签页
    func show(tab: SettingsTab) {
        // 实现标签切换的辅助方法，用于测试
        if let hostingView = self.rootHostingView {
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
        show()
    }
    
    /// 调整窗口高度以适应内容
    private func adjustWindowHeight() {
        guard let hostingView = self.rootHostingView, let window = windowController?.window else {
            return
        }
        
        // 获取内容的理想尺寸
        let idealSize = hostingView.intrinsicContentSize
        
        // 计算理想高度，降低约 40%，并限制在最大高度范围内
        let calculatedHeight = idealSize.height * 0.6
        let idealHeight = min(calculatedHeight + 40, 800)
        
        // 设置窗口大小
        var frame = window.frame
        let oldHeight = frame.size.height
        let newHeight = idealHeight
        
        frame.origin.y += (oldHeight - newHeight)
        frame.size.height = newHeight
        
        window.setFrame(frame, display: true, animate: true)
    }
} 