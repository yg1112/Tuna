import AppKit
import SwiftUI

// @module: SettingsUI
// @created_by_cursor: yes
// @summary: Updated shortcut text field component for capturing keyboard shortcuts
// @depends_on: DesignTokens.swift

// ---------- Field‑Editor ----------
final class ShortcutFieldEditor: NSTextView {
    weak var owner: ShortcutField?

    override func keyDown(with e: NSEvent) {
        print("🖊 keyDown", e.keyCode)
        switch e.keyCode {
            case 51: owner?.update("") // ⌫
            case 53: window?.makeFirstResponder(nil) // ESC
            default: super.keyDown(with: e)
        }
    }

    override func performKeyEquivalent(with e: NSEvent) -> Bool {
        let m = e.modifierFlags.intersection(.deviceIndependentFlagsMask)
        guard !m.isEmpty else { return false }
        print("🖊 combo", e.characters ?? "")
        owner?.update(Self.fmt(e))
        return true
    }

    private static func fmt(_ e: NSEvent) -> String {
        var p: [String] = []; let f = e.modifierFlags
        if f.contains(.command) { p.append("cmd") }
        if f.contains(.option) { p.append("opt") }
        if f.contains(.control) { p.append("ctrl") }
        if f.contains(.shift) { p.append("shift") }
        if let c = e.charactersIgnoringModifiers?.lowercased(), !c.isEmpty { p.append(c) }
        return p.joined(separator: "+")
    }
}

// ---------- NSTextField ----------
final class ShortcutField: NSTextField {
    var onChange: (String) -> Void = { _ in }

    private lazy var fe: ShortcutFieldEditor = {
        let v = ShortcutFieldEditor()
        v.isFieldEditor = true
        v.owner = self
        v.backgroundColor = .clear
        v.font = font
        return v
    }()

    func update(_ s: String) {
        stringValue = s
        onChange(s)
        print("🔄 value ->", s)
    }

    override func becomeFirstResponder() -> Bool {
        guard let win = window else { return super.becomeFirstResponder() }
        print("👑 firstResponder before =", win.firstResponder as Any)
        // Use temporary field editor
        window?.fieldEditor(true, for: self)
        return super.becomeFirstResponder()
    }

    // Provide our own field editor
    func fieldEditor(for object: Any?) -> NSText? {
        print("🔧 fieldEditor requested for object:", object as Any)
        return fe
    }
}

// ---------- SwiftUI wrapper ----------
struct ShortcutTextField: NSViewRepresentable {
    @Binding var keyCombo: String
    var placeholder: String

    init(keyCombo: Binding<String>, placeholder: String = "Click to set shortcut") {
        _keyCombo = keyCombo
        self.placeholder = placeholder
    }

    func makeNSView(context: Context) -> ShortcutField {
        let field = ShortcutField()
        field.isBordered = true
        field.backgroundColor = NSColor.textBackgroundColor
        field.focusRingType = .none
        field.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        field.placeholderString = placeholder
        field.stringValue = keyCombo
        field.onChange = { value in
            keyCombo = value
        }

        field.wantsLayer = true
        field.layer?.cornerRadius = 4
        field.layer?.borderWidth = 1
        field.layer?.borderColor = NSColor.separatorColor.cgColor

        return field
    }

    func updateNSView(_ field: ShortcutField, context: Context) {
        if field.stringValue != keyCombo {
            field.stringValue = keyCombo
        }
    }
}

// Extension for NSWindow to support ShortcutField's custom fieldEditor
extension NSWindow {
    @objc func windowWillReturnFieldEditor(_ sender: NSWindow, to client: Any?) -> Any? {
        if let textField = client as? ShortcutField {
            return textField.fieldEditor(for: client)
        }
        return nil
    }
}

struct ShortcutTextField_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ShortcutTextField(keyCombo: .constant("cmd+u"))
                .frame(width: 200)

            ShortcutTextField(keyCombo: .constant(""), placeholder: "Enter shortcut...")
                .frame(width: 200)
        }
        .padding()
    }
}
