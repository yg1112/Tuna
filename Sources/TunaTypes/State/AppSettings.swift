import Foundation

public struct AppSettings: Equatable {
    public var mode: Mode
    public var isMagicEnabled: Bool
    public var magicPreset: PresetStyle
    public var transcriptionLanguage: String
    public var launchAtLogin: Bool
    public var showDictationPageOnShortcut: Bool
    public var useSystemAppearance: Bool
    public var isDarkMode: Bool
    public var checkForUpdates: Bool
    public var debugEnabled: Bool

    public init(
        mode: Mode = .quickDictation,
        isMagicEnabled: Bool = false,
        magicPreset: PresetStyle = .none,
        transcriptionLanguage: String = "en",
        launchAtLogin: Bool = false,
        showDictationPageOnShortcut: Bool = true,
        useSystemAppearance: Bool = true,
        isDarkMode: Bool = false,
        checkForUpdates: Bool = true,
        debugEnabled: Bool = false
    ) {
        self.mode = mode
        self.isMagicEnabled = isMagicEnabled
        self.magicPreset = magicPreset
        self.transcriptionLanguage = transcriptionLanguage
        self.launchAtLogin = launchAtLogin
        self.showDictationPageOnShortcut = showDictationPageOnShortcut
        self.useSystemAppearance = useSystemAppearance
        self.isDarkMode = isDarkMode
        self.checkForUpdates = checkForUpdates
        self.debugEnabled = debugEnabled
    }

    public static func == (lhs: AppSettings, rhs: AppSettings) -> Bool {
        lhs.mode == rhs.mode &&
            lhs.isMagicEnabled == rhs.isMagicEnabled &&
            lhs.magicPreset == rhs.magicPreset &&
            lhs.transcriptionLanguage == rhs.transcriptionLanguage &&
            lhs.launchAtLogin == rhs.launchAtLogin &&
            lhs.showDictationPageOnShortcut == rhs.showDictationPageOnShortcut &&
            lhs.useSystemAppearance == rhs.useSystemAppearance &&
            lhs.isDarkMode == rhs.isDarkMode &&
            lhs.checkForUpdates == rhs.checkForUpdates &&
            lhs.debugEnabled == rhs.debugEnabled
    }
}
