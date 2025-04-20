import SwiftUI

@MainActor
final class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    // Tab collapse states
    @Published var isLaunchOpen: Bool = false
    @Published var isShortcutOpen: Bool = false
    @Published var isSmartSwapsOpen: Bool = false
    @Published var isThemeOpen: Bool = false
    @Published var isBetaOpen: Bool = false
    @Published var isAboutOpen: Bool = false
    
    // Feature flags
    @Published var isThemeChangeEnabled: Bool = false
    @Published var enableDictationShortcut: Bool = false
    @Published var enableSmartSwitching: Bool = false
    
    // Settings state
    @Published var launchAtLogin: Bool = false
    
    private init() {
        // Load any persisted settings here
        self.launchAtLogin = LaunchAtLogin.shared.isEnabled()
    }
} 