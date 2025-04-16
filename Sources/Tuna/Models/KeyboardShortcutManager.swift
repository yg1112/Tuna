// @module: KeyboardShortcutManager
// @created_by_cursor: yes
// @summary: 管理Tuna应用的全局键盘快捷键
// @depends_on: TunaSettings, DictationManager

import Foundation
import Cocoa
import Carbon
import os.log

struct KeyCombo {
    let keyCode: UInt16
    let modifiers: UInt32
}

class KeyboardShortcutManager {
    static let shared = KeyboardShortcutManager()
    
    private let logger = Logger(subsystem: "ai.tuna", category: "Shortcut")
    private let settings = TunaSettings.shared
    private let dictationManager = DictationManager.shared
    
    // 添加修饰键映射
    private let modifierMap:[String:NSEvent.ModifierFlags] = [
        "cmd":.command,"command":.command,"⌘":.command,
        "opt":.option,"option":.option,"alt":.option,"⌥":.option,
        "ctrl":.control,"control":.control,"⌃":.control,
        "shift":.shift,"⇧":.shift
    ]
    
    private var dictationEventHandler: EventHandlerRef?
    private var currentDictationKeyCombo: KeyCombo?
    
    private init() {
        logger.debug("KeyboardShortcutManager initialized")
        
        // 监听设置变更
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDictationShortcutSettingsChanged),
            name: Notification.Name.dictationShortcutSettingsChanged,
            object: nil
        )
        
        // 初始化快捷键
        setupDictationShortcut()
        
        // 添加全局监听 - 作为辅助快捷键方案
        setupGlobalMonitor()
    }
    
    // MARK: - Public Methods
    
    func setupDictationShortcut() {
        // 卸载现有的快捷键
        unregisterDictationShortcut()
        
        // 如果功能被禁用，不注册新的快捷键
        guard settings.enableDictationShortcut else {
            logger.debug("Dictation shortcut disabled, not registering")
            return
        }
        
        // 解析快捷键组合
        if let keyCombo = parseKeyCombo(settings.dictationShortcutKeyCombo) {
            registerDictationShortcut(keyCombo)
            logger.notice("registered \(self.settings.dictationShortcutKeyCombo, privacy: .public)")
        } else {
            logger.error("Failed to parse key combo: \(self.settings.dictationShortcutKeyCombo, privacy: .public)")
        }
    }
    
    // MARK: - Private Methods
    
    func parseKeyCombo(_ comboString: String) -> KeyCombo? {
        // 将字符串格式的快捷键(如 "option+t")转换为KeyCombo对象
        let components = comboString.lowercased().components(separatedBy: "+")
        guard components.count >= 1 else { return nil }
        
        var modifiers: UInt32 = 0
        let lastComponent = components.last ?? ""
        
        // 处理修饰键
        for component in components.dropLast() {
            switch component.trimmingCharacters(in: .whitespaces) {
            case "cmd", "command", "⌘":
                modifiers |= UInt32(1 << 8) // cmdKey
            case "shift", "⇧":
                modifiers |= UInt32(1 << 9) // shiftKey
            case "alt", "option", "opt", "⌥":
                modifiers |= UInt32(1 << 11) // optionKey
            case "ctrl", "control", "⌃":
                modifiers |= UInt32(1 << 12) // controlKey
            default:
                logger.warning("Unknown modifier: \(component, privacy: .public)")
            }
        }
        
        // 处理主键
        let keyCode: UInt16
        
        if lastComponent.count == 1, let char = lastComponent.first {
            // 处理单个字符的键
            switch char {
            case "a": keyCode = 0
            case "s": keyCode = 1
            case "d": keyCode = 2
            case "f": keyCode = 3
            case "h": keyCode = 4
            case "g": keyCode = 5
            case "z": keyCode = 6
            case "x": keyCode = 7
            case "c": keyCode = 8
            case "v": keyCode = 9
            case "b": keyCode = 11
            case "q": keyCode = 12
            case "w": keyCode = 13
            case "e": keyCode = 14
            case "r": keyCode = 15
            case "y": keyCode = 16
            case "t": keyCode = 17
            case "1", "!": keyCode = 18
            case "2", "@": keyCode = 19
            case "3", "#": keyCode = 20
            case "4", "$": keyCode = 21
            case "6", "^": keyCode = 22
            case "5", "%": keyCode = 23
            case "=", "+": keyCode = 24
            case "9", "(": keyCode = 25
            case "7", "&": keyCode = 26
            case "-", "_": keyCode = 27
            case "8", "*": keyCode = 28
            case "0", ")": keyCode = 29
            case "]", "}": keyCode = 30
            case "o": keyCode = 31
            case "u": keyCode = 32
            case "[", "{": keyCode = 33
            case "i": keyCode = 34
            case "p": keyCode = 35
            case "l": keyCode = 37
            case "j": keyCode = 38
            case "'", "\"": keyCode = 39
            case "k": keyCode = 40
            case ";", ":": keyCode = 41
            case "\\", "|": keyCode = 42
            case ",", "<": keyCode = 43
            case "/", "?": keyCode = 44
            case "n": keyCode = 45
            case "m": keyCode = 46
            case ".", ">": keyCode = 47
            case "`", "~": keyCode = 50
            default:
                logger.warning("Unsupported key: \(char, privacy: .public)")
                return nil
            }
        } else {
            // 处理特殊键
            switch lastComponent.trimmingCharacters(in: .whitespaces) {
            case "space", "spacebar":
                keyCode = 49
            case "return", "enter":
                keyCode = 36
            case "tab":
                keyCode = 48
            case "escape", "esc":
                keyCode = 53
            case "f1":
                keyCode = 122
            case "f2":
                keyCode = 120
            case "f3":
                keyCode = 99
            case "f4":
                keyCode = 118
            case "f5":
                keyCode = 96
            case "f6":
                keyCode = 97
            case "f7":
                keyCode = 98
            case "f8":
                keyCode = 100
            case "f9":
                keyCode = 101
            case "f10":
                keyCode = 109
            case "f11":
                keyCode = 103
            case "f12":
                keyCode = 111
            default:
                logger.warning("Unsupported key: \(lastComponent, privacy: .public)")
                return nil
            }
        }
        
        return KeyCombo(keyCode: keyCode, modifiers: modifiers)
    }
    
    private func registerDictationShortcut(_ keyCombo: KeyCombo) {
        logger.debug("Registering dictation shortcut: keyCode=\(keyCombo.keyCode), modifiers=\(keyCombo.modifiers)")
        
        // 更详细的权限检查和提示 - 强制显示权限对话框
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        if !accessEnabled {
            logger.error("⚠️ 辅助功能权限未授予或被拒绝，快捷键无法正常工作")
            print("🔴 [Shortcut] 辅助功能权限被拒绝，快捷键将无法工作")
            
            // 显示提示窗口，指导用户开启权限
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "需要辅助功能权限"
                alert.informativeText = "Tuna需要辅助功能权限来启用全局快捷键功能。\n\n请执行以下步骤：\n1. 点击\"打开系统偏好设置\"\n2. 前往\"安全与隐私\" > \"隐私\" > \"辅助功能\"\n3. 找到并勾选Tuna应用\n4. 重启Tuna应用"
                alert.alertStyle = .warning
                alert.addButton(withTitle: "打开系统偏好设置")
                alert.addButton(withTitle: "稍后再说")
                
                let response = alert.runModal()
                if response == .alertFirstButtonReturn {
                    // macOS Ventura及以上版本使用新的权限面板路径
                    if #available(macOS 13.0, *) {
                        let prefpaneURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
                        if let url = prefpaneURL {
                            NSWorkspace.shared.open(url)
                        } else {
                            // 回退到旧路径
                            let legacyURL = URL(fileURLWithPath: "/System/Library/PreferencePanes/Security.prefPane")
                            NSWorkspace.shared.open(legacyURL)
                        }
                    } else {
                        // 旧版macOS
                        let prefpaneURL = URL(fileURLWithPath: "/System/Library/PreferencePanes/Security.prefPane")
                        NSWorkspace.shared.open(prefpaneURL)
                    }
                }
            }
            
            return
        }
        
        logger.notice("✅ 辅助功能权限已授予，正在注册快捷键...")
        print("🟢 [Shortcut] 辅助功能权限已授予，开始注册快捷键")
        
        // 创建事件处理器
        var eventHotKeyRef: EventHotKeyRef? = nil
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        
        // 安装事件处理器
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { (nextHandler, theEvent, userData) -> OSStatus in
                // 日志记录快捷键事件
                print("🔶 [Shortcut] 接收到热键事件")
                
                // 获取触发的快捷键ID
                var hotkeyID = EventHotKeyID()
                GetEventParameter(
                    theEvent,
                    UInt32(kEventParamDirectObject),
                    UInt32(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotkeyID
                )
                
                // 检查是否是我们注册的Dictation快捷键
                if hotkeyID.id == 1 {
                    print("🔶 [Shortcut] 确认为Dictation快捷键，调用处理器")
                    KeyboardShortcutManager.shared.handleDictationShortcutPressed()
                }
                
                return noErr
            },
            1,
            &eventType,
            nil,
            &dictationEventHandler
        )
        
        if status != noErr {
            logger.error("Failed to install event handler: \(status)")
            return
        }
        
        // 注册热键
        let hotkeyID = EventHotKeyID(signature: OSType(0x54554E41), // 'TUNA'
                                     id: UInt32(1)) // Dictation快捷键的ID
        
        let registerStatus = RegisterEventHotKey(
            UInt32(keyCombo.keyCode),
            keyCombo.modifiers,
            hotkeyID,
            GetApplicationEventTarget(),
            0,
            &eventHotKeyRef
        )
        
        if registerStatus != noErr {
            logger.error("Failed to register hotkey: \(registerStatus)")
            return
        }
        
        currentDictationKeyCombo = keyCombo
        logger.notice("✅ 成功注册快捷键: \(self.settings.dictationShortcutKeyCombo)")
        print("🔶 [Shortcut] 快捷键\(self.settings.dictationShortcutKeyCombo)注册成功")
    }
    
    private func unregisterDictationShortcut() {
        // 卸载事件处理器
        if let handler = dictationEventHandler {
            RemoveEventHandler(handler)
            dictationEventHandler = nil
            logger.debug("Unregistered dictation shortcut event handler")
        }
        
        currentDictationKeyCombo = nil
    }
    
    func handleDictationShortcutPressed() {
        // 确认功能已启用
        guard settings.enableDictationShortcut else {
            logger.warning("Dictation shortcut triggered but feature is disabled")
            return
        }
        
        logger.notice("🎯 快捷键触发: \(self.settings.dictationShortcutKeyCombo)")
        print("🔶 [Shortcut] 快捷键触发: \(self.settings.dictationShortcutKeyCombo)")
        
        // A. UI 处理 - 根据设置决定是否显示Dictation页面
        if settings.showDictationPageOnShortcut {
            // 确保popover可见
            AppDelegate.shared?.ensurePopoverVisible()
            
            // 使用TabRouter直接切换标签页，不再依赖复杂的延迟和通知机制
            TabRouter.switchTo("dictation")
            
            logger.notice("✅ 已使用TabRouter切换到听写页面")
            print("✅ [Shortcut] 已使用TabRouter切换到听写页面")
        } else {
            // 不显示UI，只记录日志
            logger.notice("👻 静默录音模式 (showDictationPageOnShortcut=false)")
            print("🔷 [Shortcut] 静默录音模式 (不显示Dictation页面)")
        }
        
        // B. 业务逻辑 - 切换录音状态
        DictationManager.shared.toggle()
        logger.notice("🎙 已调用 DictationManager.toggle()")
        print("🎙 [Shortcut] 已调用 DictationManager.toggle()")
    }
    
    @objc private func handleDictationShortcutSettingsChanged() {
        logger.debug("Dictation shortcut settings changed, updating...")
        setupDictationShortcut()
    }
    
    private func setupGlobalMonitor() {
        // 使用NSEvent.addGlobalMonitorForEvents确保在所有情况下都能捕获
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            // 检查是否按下了⌘U组合键
            if event.modifierFlags.contains(.command) && event.keyCode == 32 { // 32是字母U的键码
                print("🔍 [DEBUG] 检测到Command+U快捷键")
                self.logger.notice("🎯 监测到Command+U快捷键（通过NSEvent全局监听）")
                self.handleDictationShortcutPressed()
            }
        }
        
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // 检查是否按下了⌘U组合键
            if event.modifierFlags.contains(.command) && event.keyCode == 32 { // 32是字母U的键码
                print("🔍 [DEBUG] 检测到Command+U快捷键（本地监听）")
                self.logger.notice("🎯 监测到Command+U快捷键（通过NSEvent本地监听）")
                self.handleDictationShortcutPressed()
            }
            return event
        }
        
        print("🟢 [Shortcut] 已添加全局键盘监听，可直接捕获Command+U")
        logger.notice("✅ 已添加全局键盘监听")
    }
    
    deinit {
        unregisterDictationShortcut()
        
        NotificationCenter.default.removeObserver(self)
    }
} 