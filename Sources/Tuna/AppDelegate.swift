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
    var detachedWindow: NSWindow? // 添加属性来存储独立窗口引用
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
        
        // 添加 togglePinned 通知的观察者，处理窗口固定/取消固定状态
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePinToggle(_:)),
            name: NSNotification.Name("togglePinned"),
            object: nil
        )
        
        // 检查是否需要在启动时恢复固定状态
        if UserDefaults.standard.bool(forKey: "popoverPinned") {
            // 触发 pin 状态恢复（延迟执行，确保界面已加载）
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                NotificationCenter.default.post(
                    name: NSNotification.Name("togglePinned"),
                    object: nil,
                    userInfo: ["isPinned": true]
                )
                print("\u{001B}[36m[UI]\u{001B}[0m Auto-restored pinned state on startup")
                fflush(stdout)
            }
        }
        
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
        
        // 预先创建内容视图，提高首次显示速度
        let contentView = MenuBarView(audioManager: AudioManager.shared, settings: TunaSettings.shared)
        popover.contentViewController = NSHostingController(rootView: contentView)
        
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
            // 如果有独立窗口在显示中，则关闭它
            if let detachedWindow = self.detachedWindow, detachedWindow.isVisible {
                // 如果点击图标时存在独立窗口，则关闭它并将状态设置为未固定
                detachedWindow.close()
                self.detachedWindow = nil
                
                // 更新 pin 状态
                UserDefaults.standard.set(false, forKey: "popoverPinned")
                
                // 发送通知以更新 UI 状态
                NotificationCenter.default.post(
                    name: NSNotification.Name("togglePinned"),
                    object: nil,
                    userInfo: ["isPinned": false]
                )
                
                print("\u{001B}[36m[UI]\u{001B}[0m Closed detached window from status icon click")
                return
            }
            
            // 正常 popover 逻辑
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
                    
                    // 应用视觉效果设置
                    if let contentView = self.popover.contentViewController?.view {
                        // 基本样式设置
                        contentView.wantsLayer = true
                        contentView.layer?.masksToBounds = true
                        contentView.layer?.cornerRadius = 8
                        
                        // 处理视觉效果视图
                        contentView.superview?.subviews.forEach { subview in
                            if let effectView = subview as? NSVisualEffectView {
                                effectView.material = .hudWindow
                                effectView.state = .active
                                effectView.wantsLayer = true
                                effectView.layer?.cornerRadius = 8
                                effectView.layer?.masksToBounds = true
                            }
                        }
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
    
    @objc func handlePinToggle(_ notification: Notification) {
        guard let isPinned = notification.userInfo?["isPinned"] as? Bool else {
            return
        }
        
        print("\u{001B}[36m[UI]\u{001B}[0m Pin state changed to: \(isPinned)")
        fflush(stdout)
        
        if isPinned {
            // 如果 popover 是显示状态，转换为独立窗口
            if popover.isShown {
                // 首先获取 popover 的内容视图和位置
                guard let popoverView = popover.contentViewController?.view,
                      let popoverWindow = popoverView.window else {
                    return
                }
                
                // 获取 popover 当前位置和大小
                let popoverFrame = popoverWindow.frame
                
                // 创建一个新的独立窗口
                let detachedWindow = NSWindow(
                    contentRect: popoverFrame,
                    styleMask: [.borderless, .fullSizeContentView],
                    backing: .buffered,
                    defer: false
                )
                
                // 配置窗口属性
                detachedWindow.isOpaque = false
                detachedWindow.hasShadow = true
                detachedWindow.backgroundColor = .clear
                detachedWindow.level = .floating // 设置窗口级别为浮动
                detachedWindow.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
                
                // 将现有的 popover 内容复制到新窗口
                // 注意：这里我们需要在原 popover 关闭前保存其内容视图的副本
                let contentView = MenuBarView(audioManager: AudioManager.shared, settings: TunaSettings.shared)
                let hostingView = NSHostingController(rootView: contentView)
                detachedWindow.contentViewController = hostingView
                
                // 关闭 popover 并显示新窗口
                popover.close()
                
                // 保存窗口引用以便后续使用
                UserDefaults.standard.set(true, forKey: "isUsingDetachedWindow")
                UserDefaults.standard.synchronize()
                
                // 显示独立窗口
                detachedWindow.setFrame(popoverFrame, display: true)
                detachedWindow.makeKeyAndOrderFront(nil)
                
                // 存储窗口的引用
                if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
                    appDelegate.detachedWindow = detachedWindow
                }
                
                print("\u{001B}[36m[UI]\u{001B}[0m Converted popover to detached window")
            }
            
            // 停止监听事件
            eventMonitor?.stop()
        } else {
            // 恢复标准行为
            if let appDelegate = NSApplication.shared.delegate as? AppDelegate,
               let detachedWindow = appDelegate.detachedWindow {
                // 关闭独立窗口
                detachedWindow.close()
                appDelegate.detachedWindow = nil
                
                // 重新显示 popover
                if let button = statusItem.button {
                    if let buttonWindow = button.window {
                        let buttonRect = button.bounds
                        let windowPoint = button.convert(NSPoint(x: buttonRect.midX, y: 0), to: nil)
                        let screenPoint = buttonWindow.convertPoint(toScreen: windowPoint)
                        
                        // 创建新的定位点，确保菜单紧贴任务栏
                        let adjustedRect = NSRect(
                            x: screenPoint.x - (buttonRect.width / 2),
                            y: screenPoint.y - 2,
                            width: buttonRect.width,
                            height: 0
                        )
                        
                        // 使用NSView中的convertRect来转换坐标系
                        let convertedRect = button.window?.contentView?.convert(adjustedRect, from: nil) ?? buttonRect
                        
                        // 使用精确位置显示popover
                        popover.show(relativeTo: convertedRect, of: button.window!.contentView!, preferredEdge: .minY)
                    } else {
                        // 退回到标准方法
                        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                    }
                }
                
                UserDefaults.standard.set(false, forKey: "isUsingDetachedWindow")
                UserDefaults.standard.synchronize()
                
                print("\u{001B}[36m[UI]\u{001B}[0m Closed detached window and restored popover")
            }
            
            // 重新启动点击监听
            eventMonitor?.startGlobal()
        }
        fflush(stdout)
    }
} 