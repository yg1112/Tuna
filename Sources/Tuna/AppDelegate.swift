import Cocoa
import SwiftUI
import os.log

// 事件监视器 - 监听鼠标点击事件
class EventMonitor {
    private var monitor: Any?
    private let mask: NSEvent.EventTypeMask
    private let handler: (NSEvent?) -> Void
    
    init(mask: NSEvent.EventTypeMask, handler: @escaping (NSEvent?) -> Void) {
        self.mask = mask
        self.handler = handler
    }
    
    deinit {
        stop()
    }
    
    // 监控应用外部事件
    func startGlobal() {
        monitor = NSEvent.addGlobalMonitorForEvents(matching: mask, handler: handler)
    }
    
    // 监控应用内部事件
    func startLocal() {
        monitor = NSEvent.addLocalMonitorForEvents(matching: mask) { [weak self] event in
            self?.handler(event)
            return event
        }
    }
    
    func stop() {
        if monitor != nil {
            NSEvent.removeMonitor(monitor!)
            monitor = nil
        }
    }
}

// 添加 NSImage 扩展以支持着色
extension NSImage {
    func tinted(with color: NSColor) -> NSImage {
        let image = self.copy() as! NSImage
        image.lockFocus()
        
        color.set()
        
        let imageRect = NSRect(origin: .zero, size: image.size)
        imageRect.fill(using: .sourceAtop)
        
        image.unlockFocus()
        return image
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    private var settingsWindowController: SettingsWindowController?
    private let logger = Logger(subsystem: "com.tuna.app", category: "AppDelegate")
    
    // 添加事件监视器
    private var eventMonitor: EventMonitor?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("\u{001B}[34m[APP]\u{001B}[0m Application finished launching")
        fflush(stdout)
        
        setupStatusItem()
        setupEventMonitor()
        
        // Register notification observer for settings window
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(showSettingsWindow(_:)),
            name: NSNotification.Name("showSettings"),
            object: nil
        )
        
        logger.info("Application initialization completed")
        print("\u{001B}[32m[APP]\u{001B}[0m Initialization complete")
        fflush(stdout)
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // 停止事件监视器
        eventMonitor?.stop()
        
        print("\u{001B}[34m[APP]\u{001B}[0m Application will terminate")
        logger.info("Application will terminate")
        fflush(stdout)
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            // Use fish icon to match app name "Tuna"
            if let fishImage = NSImage(systemSymbolName: "fish.fill", accessibilityDescription: "Tuna Audio Controls") {
                // 设置图标为白色，保持一致性
                let coloredImage = fishImage.tinted(with: NSColor.white)
                button.image = coloredImage
            }
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        popover = NSPopover()
        popover.contentSize = NSSize(width: 300, height: 480)
        popover.behavior = .transient
        
        // 移除弹出窗口的背景和阴影，解决灰色阴影问题
        popover.setValue(true, forKeyPath: "shouldHideAnchor")
        
        // 使用系统风格的外观
        if let appearance = NSAppearance(named: .darkAqua) {
            popover.appearance = appearance
        }
        
        // 创建自定义视图控制器，完全控制背景
        let contentView = MenuBarView()
        let hostingController = CustomHostingController(rootView: contentView)
        popover.contentViewController = hostingController
        
        print("\u{001B}[36m[UI]\u{001B}[0m Status bar icon configured")
        fflush(stdout)
    }
    
    private func setupEventMonitor() {
        // 创建事件监视器，监听鼠标点击事件 - 使用全局监视器
        eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            guard let self = self, self.popover.isShown else { return }
            
            // 当点击发生在应用窗口外时，关闭弹出窗口
            print("\u{001B}[36m[UI]\u{001B}[0m User clicked outside popover, closing")
            fflush(stdout)
            self.popover.performClose(nil)
        }
        
        // 在应用程序启动时开始监听
        eventMonitor?.startGlobal()
        
        print("\u{001B}[36m[UI]\u{001B}[0m Event monitor configured")
        fflush(stdout)
    }
    
    @objc private func togglePopover() {
        if let button = statusItem.button {
            if popover.isShown {
                closePopover()
            } else {
                // 显示弹出窗口
                eventMonitor?.stop() // 暂时停止监听以避免立即触发关闭
                
                print("\u{001B}[36m[UI]\u{001B}[0m Showing popover")
                fflush(stdout)
                
                // 计算让菜单紧贴任务栏的位置
                if let buttonWindow = button.window {
                    let buttonRect = button.bounds
                    let windowPoint = button.convert(NSPoint(x: buttonRect.midX, y: 0), to: nil)
                    let screenPoint = buttonWindow.convertPoint(toScreen: windowPoint)
                    
                    // 创建新的定位点，确保菜单紧贴任务栏
                    let adjustedRect = NSRect(
                        x: screenPoint.x - (buttonRect.width / 2),
                        y: screenPoint.y - 2, // 向上移动菜单，紧贴任务栏
                        width: buttonRect.width,
                        height: 0
                    )
                    
                    // 使用NSView中的convertRect来转换坐标系
                    let convertedRect = button.window?.contentView?.convert(adjustedRect, from: nil) ?? buttonRect
                    
                    // 使用精确位置显示popover
                    popover.show(relativeTo: convertedRect, of: button.window!.contentView!, preferredEdge: .minY)
                    
                    // 直接修改popover窗口的位置
                    DispatchQueue.main.async {
                        if let popoverWindow = self.popover.contentViewController?.view.window {
                            // 获取当前位置
                            var frame = popoverWindow.frame
                            // 调整Y坐标使菜单紧贴任务栏
                            frame.origin.y += 6 // 向上移动
                            // 设置新位置
                            popoverWindow.setFrame(frame, display: true)
                        }
                    }
                } else {
                    // 退回到标准方法
                    popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                }
                
                // 在显示popover后处理视觉效果
                DispatchQueue.main.async {
                    // 移除箭头和阴影
                    self.popover.setValue(true, forKeyPath: "shouldHideAnchor")
                    
                    // 应用视觉效果时保持简单，CustomHostingController已经处理大部分样式
                    if let contentView = self.popover.contentViewController?.view {
                        // 强制更新视图
                        contentView.needsDisplay = true
                        contentView.needsLayout = true
                    }
                }
                
                // 重启事件监视器
                eventMonitor?.startGlobal()
            }
        }
    }
    
    // 添加关闭popover的方法
    private func closePopover() {
        popover.performClose(nil)
    }
    
    @objc func showSettingsWindow(_ notification: Notification) {
        print("\u{001B}[36m[SETTINGS]\u{001B}[0m User requested settings window")
        fflush(stdout)
        
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController()
        }
        
        if let window = settingsWindowController?.window {
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
            
            print("\u{001B}[36m[SETTINGS]\u{001B}[0m Settings window displayed")
            fflush(stdout)
        }
    }
    
    @objc func handleDeviceSelection(_ sender: NSMenuItem) {
        guard let info = sender.representedObject as? DeviceSelectionInfo else { return }
        
        print("Switching device: \(info.device.name), is input: \(info.isInput)")
        
        // Use AudioManager to switch device
        AudioManager.shared.setDefaultDevice(info.device, forInput: info.isInput)
        
        // Close menu
        if let menu = sender.menu {
            menu.cancelTracking()
        }
    }
    
    // 自定义HostingController
    class CustomHostingController<Content>: NSHostingController<Content> where Content: View {
        override func loadView() {
            super.loadView()
            
            // 设置视图背景为纯黑色，移除所有默认背景
            view.wantsLayer = true
            view.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.9).cgColor
            view.layer?.cornerRadius = 10
            view.layer?.masksToBounds = true
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            // 确保任何子视图也应用了圆角
            DispatchQueue.main.async {
                // 应用到所有子视图
                self.applyCornerRadiusToSubviews(self.view, radius: 10)
            }
        }
        
        private func applyCornerRadiusToSubviews(_ view: NSView, radius: CGFloat) {
            // 设置当前视图
            view.wantsLayer = true
            view.layer?.cornerRadius = radius
            view.layer?.masksToBounds = true
            
            // 递归处理所有子视图
            for subview in view.subviews {
                applyCornerRadiusToSubviews(subview, radius: radius)
                
                // 特殊处理视觉效果视图
                if let effectView = subview as? NSVisualEffectView {
                    effectView.material = .hudWindow
                    effectView.state = .active
                    effectView.wantsLayer = true
                    effectView.layer?.cornerRadius = radius
                    effectView.layer?.masksToBounds = true
                }
            }
        }
    }
} 