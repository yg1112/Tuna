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
    // 添加shared静态属性
    static var shared: AppDelegate? {
        return NSApp.delegate as? AppDelegate
    }
    
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    private var settingsWindowController: SettingsWindowController?
    private let logger = Logger(subsystem: "ai.tuna", category: "AppDelegate")
    
    // 添加事件监视器
    private var eventMonitor: EventMonitor?
    
    // 添加快捷键管理器
    private var keyboardShortcutManager: KeyboardShortcutManager!
    
    // 使用标准UserDefaults
    private let defaults = UserDefaults.standard
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("\u{001B}[34m[APP]\u{001B}[0m Application finished launching")
        fflush(stdout)
        
        setupStatusItem()
        setupEventMonitor()
        
        // 检查并更新旧的快捷键设置
        if let currentShortcut = defaults.string(forKey: "dictationShortcutKeyCombo"), currentShortcut == "opt+t" {
            defaults.set("cmd+u", forKey: "dictationShortcutKeyCombo")
            logger.info("Updated legacy shortcut from opt+t to cmd+u")
        }
        
        // 初始化键盘快捷键管理器
        keyboardShortcutManager = KeyboardShortcutManager.shared
        
        // 检查辅助功能权限
        checkAccessibilityOnLaunchIfNeeded()
        
        // Register notification observer for settings window
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(showSettingsWindow(_:)),
            name: Notification.Name.showSettings,
            object: nil
        )
        
        // 添加 togglePinned 通知的观察者，处理窗口固定/取消固定状态
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePinToggle(_:)),
            name: Notification.Name.togglePinned,
            object: nil
        )
        
        // 检查上次使用时是否为固定状态，如果是，则在第一次点击图标时自动固定
        let wasPinned = defaults.bool(forKey: "popoverPinned")
        if wasPinned {
            print("\u{001B}[36m[UI]\u{001B}[0m Will restore pin state on first click")
            // 但不立即执行固定操作，避免在启动时的问题
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
            // 确保同时设置target和action
            button.target = self
            button.action = #selector(togglePopover(_:))
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
        .environmentObject(DictationManager.shared)
        .environmentObject(TabRouter.shared)
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
    
    @objc func togglePopover(_ sender: Any?) {
        if let button = statusItem.button {
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
                    DispatchQueue.main.async { [self] in
                        if let popoverWindow = self.popover.contentViewController?.view.window {
                            // 获取当前位置
                            var frame = popoverWindow.frame
                            // 调整Y坐标使菜单紧贴任务栏
                            frame.origin.y += 6 // 向上移动
                            // 设置新位置
                            popoverWindow.setFrame(frame, display: true)
                            
                            // 检查是否需要应用固定状态
                            let shouldPin = self.defaults.bool(forKey: "popoverPinned")
                            if shouldPin {
                                // 直接应用固定状态
                                NotificationCenter.default.post(
                                    name: Notification.Name.togglePinned,
                                    object: nil,
                                    userInfo: ["isPinned": true]
                                )
                                print("\u{001B}[36m[UI]\u{001B}[0m Applied saved pin state")
                            }
                        }
                    }
                } else {
                    // 退回到标准方法
                    popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                    
                    // 检查是否需要应用固定状态
                    DispatchQueue.main.async { [self] in
                        let shouldPin = self.defaults.bool(forKey: "popoverPinned")
                        if shouldPin {
                            NotificationCenter.default.post(
                                name: Notification.Name.togglePinned,
                                object: nil,
                                userInfo: ["isPinned": true]
                            )
                        }
                    }
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
                
                // 如果不是固定状态，才重启事件监视器
                if !defaults.bool(forKey: "popoverPinned") {
                    eventMonitor?.startGlobal()
                }
            }
        }
    }
    
    /// 显示菜单栏弹窗；若已显示则什么都不做
    func ensurePopoverVisible() {
        if !popover.isShown {
            Logger(subsystem:"ai.tuna",category:"Shortcut").notice("[P] showPopover")
            rebuildPopover()  // 确保每次显示前重建Popover
            showPopover()
        }
    }
    
    // 重建Popover以确保它使用最新的视图树
    private func rebuildPopover() {
        Logger(subsystem:"ai.tuna",category:"Shortcut").notice("[P] rebuildPopover")
        print("🔄 [DEBUG] 重建Popover，确保视图树更新")
        
        let contentView = MenuBarView(
            audioManager: AudioManager.shared,
            settings: TunaSettings.shared
        )
        .environmentObject(DictationManager.shared)
        .environmentObject(TabRouter.shared)
        
        print("👁 [DEBUG] 新Popover的router id: \(ObjectIdentifier(TabRouter.shared))")
        print("ROUTER-DBG [2]", ObjectIdentifier(TabRouter.shared), TabRouter.shared.current)
        
        popover.contentViewController = NSHostingController(rootView: contentView)
    }
    
    // 显示弹出窗口的方法
    private func showPopover() {
        if let button = statusItem.button {
            // 暂时停止监听以避免立即触发关闭
            eventMonitor?.stop() 
            
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
                DispatchQueue.main.async { [self] in
                    if let popoverWindow = self.popover.contentViewController?.view.window {
                        // 获取当前位置
                        var frame = popoverWindow.frame
                        // 调整Y坐标使菜单紧贴任务栏
                        frame.origin.y += 6 // 向上移动
                        // 设置新位置
                        popoverWindow.setFrame(frame, display: true)
                        
                        // 检查是否需要应用固定状态
                        let shouldPin = self.defaults.bool(forKey: "popoverPinned")
                        if shouldPin {
                            // 直接应用固定状态
                            NotificationCenter.default.post(
                                name: Notification.Name.togglePinned,
                                object: nil,
                                userInfo: ["isPinned": true]
                            )
                            print("\u{001B}[36m[UI]\u{001B}[0m Applied saved pin state")
                        }
                    }
                }
            } else {
                // 退回到标准方法
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                
                // 检查是否需要应用固定状态
                DispatchQueue.main.async { [self] in
                    let shouldPin = self.defaults.bool(forKey: "popoverPinned")
                    if shouldPin {
                        NotificationCenter.default.post(
                            name: Notification.Name.togglePinned,
                            object: nil,
                            userInfo: ["isPinned": true]
                        )
                    }
                }
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
            
            // 如果不是固定状态，才重启事件监视器
            if !defaults.bool(forKey: "popoverPinned") {
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
            // 停止事件监听器，防止点击外部区域关闭 popover
            eventMonitor?.stop()
            
            // 修改 popover 行为，防止自动关闭
            popover.behavior = .applicationDefined
            
            // 如果 popover 已显示，调整窗口级别使其保持在最前
            if popover.isShown, let popoverWindow = popover.contentViewController?.view.window {
                // 设置窗口级别为浮动（保持在大多数窗口之上）
                popoverWindow.level = .floating
                popoverWindow.orderFrontRegardless()
                
                print("\u{001B}[36m[UI]\u{001B}[0m Popover set to floating level")
            } else {
                print("\u{001B}[33m[WARN]\u{001B}[0m Popover not shown, pin setting will apply when shown")
            }
        } else {
            // 恢复 popover 的默认行为
            popover.behavior = .transient
            
            // 如果 popover 正在显示，恢复其窗口级别
            if popover.isShown, let popoverWindow = popover.contentViewController?.view.window {
                popoverWindow.level = .normal
                print("\u{001B}[36m[UI]\u{001B}[0m Popover restored to normal level")
            }
            
            // 重新启动事件监听器，使点击外部区域时关闭 popover
            eventMonitor?.startGlobal()
        }
        
        // 保存状态到 UserDefaults
        defaults.set(isPinned, forKey: "popoverPinned")
        defaults.synchronize()
        
        fflush(stdout)
    }
    
    // 应用启动时检查辅助功能权限
    private func checkAccessibilityOnLaunchIfNeeded() {
        // 检查用户是否已经看过权限提示
        let hasSeenAccessibilityPrompt = defaults.bool(forKey: "hasSeenAccessibilityPrompt")
        if hasSeenAccessibilityPrompt {
            return // 只提示一次
        }
        
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): false] // 不立即显示系统对话框
        let accessGranted = AXIsProcessTrustedWithOptions(options as CFDictionary)

        if !accessGranted {
            // 延迟1.5秒显示提示，确保UI已完全加载
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.logger.notice("显示辅助功能权限提示")
                let alert = NSAlert()
                alert.messageText = "请为 Tuna 启用辅助功能权限"
                alert.informativeText = "用于启用快捷键功能（如 Cmd+U 启动听写）。\n\n前往系统设置 > 隐私与安全 > 辅助功能，勾选 Tuna。\n\n启用后需要重启应用才能生效。"
                alert.alertStyle = .warning
                alert.addButton(withTitle: "打开设置")
                alert.addButton(withTitle: "稍后再说")

                if alert.runModal() == .alertFirstButtonReturn {
                    if #available(macOS 13.0, *) {
                        // 现代macOS路径
                        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
                        if let url = url {
                            NSWorkspace.shared.open(url)
                        } else {
                            // 回退到传统路径
                            let legacyURL = URL(fileURLWithPath: "/System/Library/PreferencePanes/Security.prefPane")
                            NSWorkspace.shared.open(legacyURL)
                        }
                    } else {
                        // 传统路径
                        let prefpaneURL = URL(fileURLWithPath: "/System/Library/PreferencePanes/Security.prefPane")
                        NSWorkspace.shared.open(prefpaneURL)
                    }
                }
                
                // 标记用户已看过提示
                self.defaults.set(true, forKey: "hasSeenAccessibilityPrompt")
                self.defaults.synchronize()
            }
        }
    }
    
    @objc func showMainWindow() {
        // 使用MainWindowManager显示主窗口
        MainWindowManager.shared.show()
        logger.notice("通过AppDelegate显示主窗口")
        print("\u{001B}[34m[WINDOW]\u{001B}[0m 通过AppDelegate显示主窗口")
        fflush(stdout)
    }
    
    /// For unit tests: sets up statusItem without relying on NSApplication run‑loop.
    @objc func setupStatusItemForTesting() {
        if statusItem == nil {
            setupStatusItem()   // 使用正确的方法名
        }
    }
} 