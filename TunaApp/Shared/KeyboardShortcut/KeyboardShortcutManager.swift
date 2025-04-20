// @module: KeyboardShortcutManager
// @created_by_cursor: yes
// @summary: 管理Tuna应用的全局键盘快捷键
// @depends_on: TunaSettings, DictationManager

import Carbon
import Cocoa
import Foundation
import os.log

struct KeyCombo {
    let keyCode: UInt16
    let modifiers: UInt32
}

class KeyboardShortcutManager {
    static let shared = KeyboardShortcutManager()

    private let logger = Logger(subsystem: "com.tuna.app", category: "KeyboardShortcutManager")
    private let settings = TunaSettings.shared
    private let dictationManager = DictationManager.shared

    private var dictationEventHandler: EventHandlerRef?
    private var currentDictationKeyCombo: KeyCombo?

    private init() {
        logger.debug("KeyboardShortcutManager initialized")

        // 监听设置变更
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDictationShortcutSettingsChanged),
            name: NSNotification.Name("dictationShortcutSettingsChanged"),
            object: nil
        )

        // 初始化快捷键
        setupDictationShortcut()
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
        } else {
            logger.error("Failed to parse key combo: \(settings.dictationShortcutKeyCombo)")
        }
    }

    // MARK: - Private Methods

    private func parseKeyCombo(_ comboString: String) -> KeyCombo? {
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
                case "alt", "option", "⌥":
                    modifiers |= UInt32(1 << 11) // optionKey
                case "ctrl", "control", "⌃":
                    modifiers |= UInt32(1 << 12) // controlKey
                default:
                    logger.warning("Unknown modifier: \(component)")
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
                    logger.warning("Unsupported key: \(char)")
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
                    logger.warning("Unsupported key: \(lastComponent)")
                    return nil
            }
        }

        return KeyCombo(keyCode: keyCode, modifiers: modifiers)
    }

    private func registerDictationShortcut(_ keyCombo: KeyCombo) {
        logger
            .debug(
                "Registering dictation shortcut: keyCode=\(keyCombo.keyCode), modifiers=\(keyCombo.modifiers)"
            )

        // 创建事件处理器
        var eventHotKeyRef: EventHotKeyRef?
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        // 安装事件处理器
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { nextHandler, theEvent, userData -> OSStatus in
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
        var hotkeyID = EventHotKeyID(
            signature: OSType(0x5455_4E41), // 'TUNA'
            id: UInt32(1)
        ) // Dictation快捷键的ID

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
        logger.debug("Successfully registered dictation shortcut")
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

        logger.debug("Dictation shortcut pressed, activating app and starting transcription")

        // 激活应用
        NSApp.activate(ignoringOtherApps: true)

        // 显示主窗口/弹出窗口
        if let appDelegate = NSApp.delegate as? AppDelegate {
            // 检查popover是否已打开
            if !appDelegate.popover.isShown {
                // 如果未打开，则触发状态栏图标点击显示popover
                appDelegate.togglePopover()
            }

            // 切换到Dictation选项卡
            NotificationCenter.default.post(
                name: NSNotification.Name("switchToTab"),
                object: nil,
                userInfo: ["tab": "dictation"]
            )

            // 延迟一小段时间后开始录音，确保UI已完全加载
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                // 开始语音转写
                DictationManager.shared.startRecording()
            }
        }
    }

    @objc private func handleDictationShortcutSettingsChanged() {
        logger.debug("Dictation shortcut settings changed, updating...")
        setupDictationShortcut()
    }

    deinit {
        unregisterDictationShortcut()

        NotificationCenter.default.removeObserver(self)
    }
}
