import Foundation

public struct KeyboardShortcutState: Equatable {
    public var enableDictationShortcut: Bool
    public var dictationShortcutKeyCombo: String
    public var showDictationPageOnShortcut: Bool

    public init(
        enableDictationShortcut: Bool = true,
        dictationShortcutKeyCombo: String = "⌘⌥D",
        showDictationPageOnShortcut: Bool = true
    ) {
        self.enableDictationShortcut = enableDictationShortcut
        self.dictationShortcutKeyCombo = dictationShortcutKeyCombo
        self.showDictationPageOnShortcut = showDictationPageOnShortcut
    }
}
