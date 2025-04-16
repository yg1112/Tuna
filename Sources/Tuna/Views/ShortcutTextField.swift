import SwiftUI
import AppKit

// ---------- Field‑Editor ----------
final class ShortcutFieldEditor: NSTextView {
    weak var owner: ShortcutField?
    override func keyDown(with e: NSEvent) {
        print("🖊 keyDown", e.keyCode)
        switch e.keyCode {
        case 51: owner?.update("")               // ⌫
        case 53: window?.makeFirstResponder(nil) // ESC
        default: super.keyDown(with: e)
        }
    }
    override func performKeyEquivalent(with e: NSEvent) -> Bool {
        let m = e.modifierFlags.intersection(.deviceIndependentFlagsMask)
        guard !m.isEmpty else { return false }
        print("🖊 combo", e.characters ?? "")
        owner?.update(Self.fmt(e)); return true
    }
    private static func fmt(_ e:NSEvent)->String {
        var p:[String] = []; let f = e.modifierFlags
        if f.contains(.command)  { p.append("cmd")  }
        if f.contains(.option)   { p.append("opt")  }
        if f.contains(.control)  { p.append("ctrl") }
        if f.contains(.shift)    { p.append("shift")}
        if let c = e.charactersIgnoringModifiers?.lowercased(), !c.isEmpty { p.append(c) }
        return p.joined(separator:"+")
    }
}

// ---------- NSTextField ----------
final class ShortcutField: NSTextField {
    var onChange:(String)->Void = { _ in }
    private lazy var fe:ShortcutFieldEditor = {
        let v = ShortcutFieldEditor(); v.isFieldEditor = true
        v.owner = self; v.backgroundColor = .clear; v.font = font; return v
    }()
    func update(_ s:String){ 
        stringValue = s; 
        onChange(s);
        print("🔄 value ->", s)
    }
    override func becomeFirstResponder()->Bool {
        guard let win = window else { return super.becomeFirstResponder() }
        print("👑 firstResponder before =", win.firstResponder as Any)
        // 使用临时字段编辑器
        window?.fieldEditor(true, for: self)
        return super.becomeFirstResponder()
    }
    
    // 提供我们自己的字段编辑器
    func fieldEditor(for object: Any?) -> NSText? {
        print("🔧 fieldEditor requested for object:", object as Any)
        return fe
    }
}

// ---------- SwiftUI wrapper ----------
struct ShortcutTextField:NSViewRepresentable{
    @Binding var value:String; var onCommit:()->Void
    func makeNSView(context:Context)->ShortcutField{
        let f = ShortcutField(); f.isBordered = false; f.backgroundColor = .clear
        f.focusRingType = .none; f.font = .monospacedSystemFont(ofSize:12,weight:.regular)
        f.stringValue = value; f.onChange = { v in value = v; onCommit() }; return f
    }
    func updateNSView(_ v:ShortcutField,context:Context){
        if v.stringValue != value { v.stringValue = value }
    }
}

// 扩展NSWindow以支持ShortcutField的自定义fieldEditor
extension NSWindow {
    @objc func windowWillReturnFieldEditor(_ sender: NSWindow, to client: Any?) -> Any? {
        if let textField = client as? ShortcutField {
            return textField.fieldEditor(for: client)
        }
        return nil
    }
} 