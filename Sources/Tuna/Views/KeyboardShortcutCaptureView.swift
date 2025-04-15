import SwiftUI
import Cocoa
import os.log

// 键盘快捷键捕获视图
struct KeyboardShortcutCaptureView: NSViewRepresentable {
    @Binding var shortcutString: String
    var onCaptureComplete: (() -> Void)?
    
    private let logger = Logger(subsystem: "ai.tuna", category: "Shortcut")
    
    func makeNSView(context: Context) -> NSView {
        let view = KeyboardCaptureView()
        view.delegate = context.coordinator
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        // 当视图更新时不需要特殊处理
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: KeyboardShortcutCaptureView
        
        init(_ parent: KeyboardShortcutCaptureView) {
            self.parent = parent
        }
        
        func keyboardEventCaptured(event: NSEvent) {
            let comboString = canonicalize(event)
            parent.logger.notice("canonicalized \(comboString, privacy: .public)")
            
            DispatchQueue.main.async {
                self.parent.shortcutString = comboString
                self.parent.onCaptureComplete?()
            }
        }
        
        // canonicalize 统一输出：cmd opt ctrl shift <mainKey>
        private func canonicalize(_ e: NSEvent) -> String {
            var parts:[String]=[]
            if e.modifierFlags.contains(.command)  { parts.append("cmd") }
            if e.modifierFlags.contains(.option)   { parts.append("opt") }
            if e.modifierFlags.contains(.control)  { parts.append("ctrl") }
            if e.modifierFlags.contains(.shift)    { parts.append("shift") }
            let main = keyNameFrom(keyCode: Int(e.keyCode)) ?? (e.charactersIgnoringModifiers ?? "").lowercased()
            parts.append(main)
            let combo = parts.joined(separator: "+")
            parent.logger.debug("canonicalized \(combo)")
            return combo
        }
        
        private func keyNameFrom(keyCode: Int) -> String? {
            switch keyCode {
            case 0: return "a"
            case 1: return "s"
            case 2: return "d"
            case 3: return "f"
            case 4: return "h"
            case 5: return "g"
            case 6: return "z"
            case 7: return "x"
            case 8: return "c"
            case 9: return "v"
            case 11: return "b"
            case 12: return "q"
            case 13: return "w"
            case 14: return "e"
            case 15: return "r"
            case 16: return "y"
            case 17: return "t"
            case 18: return "1"
            case 19: return "2"
            case 20: return "3"
            case 21: return "4"
            case 22: return "6"
            case 23: return "5"
            case 24: return "="
            case 25: return "9"
            case 26: return "7"
            case 27: return "-"
            case 28: return "8"
            case 29: return "0"
            case 30: return "]"
            case 31: return "o"
            case 32: return "u"
            case 33: return "["
            case 34: return "i"
            case 35: return "p"
            case 37: return "l"
            case 38: return "j"
            case 39: return "'"
            case 40: return "k"
            case 41: return ";"
            case 42: return "\\"
            case 43: return ","
            case 44: return "/"
            case 45: return "n"
            case 46: return "m"
            case 47: return "."
            case 49: return "space"
            case 50: return "`"
            case 36: return "return"
            case 48: return "tab"
            case 53: return "esc"
            case 122: return "f1"
            case 120: return "f2"
            case 99: return "f3"
            case 118: return "f4"
            case 96: return "f5"
            case 97: return "f6"
            case 98: return "f7"
            case 100: return "f8"
            case 101: return "f9"
            case 109: return "f10"
            case 103: return "f11"
            case 111: return "f12"
            default: return nil
            }
        }
    }
}

// NSView实现，用于捕获键盘事件
class KeyboardCaptureView: NSView {
    var delegate: KeyboardShortcutCaptureView.Coordinator?
    
    override var acceptsFirstResponder: Bool {
        return true
    }
    
    override func keyDown(with event: NSEvent) {
        delegate?.keyboardEventCaptured(event: event)
    }
} 