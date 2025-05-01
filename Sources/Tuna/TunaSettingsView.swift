import AppKit
import os.log
import SwiftUI
import TunaCore
import TunaUI
import UserNotifications

// @module: SettingsUI
// @created_by_cursor: yes
// @summary: Settings view implementation for Tuna application
// @depends_on: DesignTokens.swift, CollapsibleCard.swift, SidebarTab.swift, TunaSettings.swift

// 定义一个统一的强调色 - 使用mint green替代蓝灰色调
extension Color {
    static let tunaAccent = Color(red: 0.3, green: 0.9, blue: 0.7)
}

// URL扩展方法 - 添加tilde路径简化
extension URL {
    func abbreviatingWithTildeInPath() -> String {
        let path = path
        let homeDirectory = NSHomeDirectory()
        if path.hasPrefix(homeDirectory) {
            return "~" + path.dropFirst(homeDirectory.count)
        }
        return path
    }
}

struct ModernToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label

            Spacer()

            ZStack {
                Capsule()
                    .fill(
                        configuration.isOn ? Color(nsColor: .controlAccentColor) : Color.gray
                            .opacity(0.3)
                    )
                    .frame(width: 40, height: 15)
                    .focusable(false)

                Circle()
                    .fill(Color.white)
                    .shadow(radius: 1)
                    .frame(width: 13, height: 13)
                    .offset(x: configuration.isOn ? 13 : -13)
                    .animation(.spring(response: 0.2), value: configuration.isOn)
                    .focusable(false)
            }
            .onTapGesture {
                withAnimation {
                    configuration.isOn.toggle()
                }
            }
            .focusable(false)
        }
    }
}

struct GlassCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 16) // 统一卡片内水平边距为16pt
            .padding(.vertical, 16) // 统一卡片内垂直边距为16pt
            .background(
                ZStack {
                    // 毛玻璃背景 - 稍微提亮
                    Color(red: 0.18, green: 0.18, blue: 0.18)

                    // 微弱光晕效果模拟曲面反光
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.08),
                            Color.clear,
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5) // 微边框稍微提亮
            )
            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 2)
    }
}

extension View {
    func glassCard() -> some View {
        modifier(GlassCard())
    }
}

struct InfoButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(Color.secondary.opacity(configuration.isPressed ? 0.6 : 0.8))
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// Enum for the different tabs in the settings view
enum SettingsTab: String, CaseIterable, Identifiable {
    case general
    case dictation
    case audio
    case appearance
    case advanced
    case support

    var id: String { rawValue }

    var icon: String {
        switch self {
            case .general: "gear"
            case .dictation: "mic"
            case .audio: "speaker.wave.3"
            case .appearance: "paintbrush"
            case .advanced: "wrench.and.screwdriver"
            case .support: "questionmark.circle"
        }
    }

    var label: String {
        rawValue.capitalized
    }
}

struct ContactButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

struct TunaSettingsView: View {
    @ObservedObject private var settings = TunaSettings.shared
    @State private var selectedTab: SettingsTab = .general
    @StateObject private var audioManager = AudioManager.shared
    @State private var showingDirectoryPicker = false
    @State private var isLaunchCardExpanded = false
    @State private var isShortcutCardExpanded = false
    @State private var isSmartSwapsCardExpanded = false
    @State private var isThemeCardExpanded = false
    @State private var isBetaCardExpanded = false
    @State private var isAboutCardExpanded = false
    @State private var isUpdatesCardExpanded = false
    @State private var isAppearanceCardExpanded = false
    @State private var isDebugCardExpanded = false
    @State private var isMagicTransformCardExpanded = false
    @State private var isAudioDevicesCardExpanded = false

    private let padding: CGFloat = 16

    var body: some View {
        TabView(selection: self.$selectedTab) {
            // General Tab
            GeneralTabView(settings: self.settings)
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .tag(SettingsTab.general)
                .accessibilityIdentifier("generalTab")

            // Dictation Tab
            DictationTabView(settings: self.settings)
                .tabItem {
                    Label("Dictation", systemImage: "mic")
                }
                .tag(SettingsTab.dictation)
                .accessibilityIdentifier("dictationTab")

            // Audio Tab
            AudioTabView(settings: self.settings, audioManager: self.audioManager)
                .tabItem {
                    Label("Audio", systemImage: "speaker.wave.2")
                }
                .tag(SettingsTab.audio)
                .accessibilityIdentifier("audioTab")

            // Appearance Tab
            AppearanceTabView(settings: self.settings)
                .tabItem {
                    Label("Appearance", systemImage: "paintbrush")
                }
                .tag(SettingsTab.appearance)
                .accessibilityIdentifier("appearanceTab")

            // Advanced Tab
            AdvancedTabView(settings: self.settings)
                .tabItem {
                    Label("Advanced", systemImage: "gearshape.2")
                }
                .tag(SettingsTab.advanced)
                .accessibilityIdentifier("advancedTab")

            // Support Tab
            SupportTabView(settings: self.settings)
                .tabItem {
                    Label("Support", systemImage: "questionmark.circle")
                }
                .tag(SettingsTab.support)
                .accessibilityIdentifier("supportTab")
        }
        .padding()
    }
}

// MARK: - Tab Views

struct GeneralTabView: View {
    @ObservedObject var settings: TunaSettings

    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: 16) {
                    CollapsibleCard(
                        title: "Launch on Startup",
                        isExpanded: self.$settings.isLaunchOpen,
                        collapsible: false
                    ) {
                        Toggle("Launch on startup", isOn: self.$settings.launchAtLogin)
                            .font(Typography.body)
                            .accessibilityIdentifier("launchToggle")
                    }
                    .accessibilityIdentifier("launchCard")

                    CollapsibleCard(
                        title: "Check for Updates",
                        isExpanded: self.$settings.isUpdatesOpen,
                        collapsible: false
                    ) {
                        Toggle("Check for updates", isOn: self.$settings.checkForUpdates)
                            .font(Typography.body)
                            .accessibilityIdentifier("updatesToggle")
                    }
                    .accessibilityIdentifier("updatesCard")
                }
                .padding()
            }
        }
    }
}

struct DictationTabView: View {
    @ObservedObject var settings: TunaSettings

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                CollapsibleCard(
                    title: "Engine",
                    isExpanded: self.$settings.isEngineOpen,
                    collapsible: false
                ) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Engine Settings")
                            .font(Typography.body)
                            .accessibilityIdentifier("EngineSettings")

                        // Add any additional engine settings here
                    }
                    .accessibilityIdentifier("EngineContent")
                }
                .accessibilityIdentifier("EngineCard")

                CollapsibleCard(
                    title: "Transcription Output",
                    isExpanded: self.$settings.isTranscriptionOutputOpen,
                    collapsible: false
                ) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Transcription Output Settings")
                            .font(Typography.body)
                            .accessibilityIdentifier("TranscriptionOutputSettings")

                        // Add any additional transcription settings here
                    }
                    .accessibilityIdentifier("TranscriptionOutputContent")
                }
                .accessibilityIdentifier("TranscriptionOutputCard")
            }
            .padding()
        }
        .accessibilityIdentifier("DictationTab")
    }
}

struct AudioTabView: View {
    @ObservedObject var settings: TunaSettings
    @ObservedObject var audioManager: AudioManager

    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: 16) {
                    CollapsibleCard(
                        title: "Audio Devices",
                        isExpanded: self.$settings.isAudioDevicesOpen,
                        collapsible: false
                    ) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Input Device")
                                .font(Typography.body)
                                .accessibilityIdentifier("inputDeviceLabel")
                            Text(self.audioManager.selectedInputDevice?.name ?? "No input device")
                                .font(Typography.caption)
                                .foregroundColor(.secondary)
                                .accessibilityIdentifier("inputDeviceName")
                        }
                    }
                    .accessibilityIdentifier("audioDevicesCard")
                }
                .padding()
            }
        }
    }
}

struct AppearanceTabView: View {
    @ObservedObject var settings: TunaSettings

    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: 16) {
                    CollapsibleCard(
                        title: "Theme",
                        isExpanded: self.$settings.isThemeOpen,
                        collapsible: false
                    ) {
                        Toggle("Use system appearance", isOn: self.$settings.useSystemAppearance)
                            .font(Typography.body)
                            .accessibilityIdentifier("systemAppearanceToggle")

                        if !self.settings.useSystemAppearance {
                            Toggle("Dark mode", isOn: self.$settings.isDarkMode)
                                .font(Typography.body)
                                .accessibilityIdentifier("darkModeToggle")
                        }
                    }
                    .accessibilityIdentifier("themeCard")

                    CollapsibleCard(
                        title: "Appearance",
                        isExpanded: self.$settings.isAppearanceOpen,
                        collapsible: false
                    ) {
                        Toggle("Reduce motion", isOn: self.$settings.reduceMotion)
                            .font(Typography.body)
                            .accessibilityIdentifier("reduceMotionToggle")
                    }
                    .accessibilityIdentifier("appearanceCard")
                }
                .padding()
            }
        }
    }
}

struct AdvancedTabView: View {
    @ObservedObject var settings: TunaSettings

    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: 16) {
                    CollapsibleCard(
                        title: "Beta Features",
                        isExpanded: self.$settings.isBetaOpen,
                        collapsible: false
                    ) {
                        Toggle("Enable beta features", isOn: self.$settings.betaEnabled)
                            .font(Typography.body)
                            .accessibilityIdentifier("betaToggle")
                    }
                    .accessibilityIdentifier("betaCard")

                    CollapsibleCard(
                        title: "Debug",
                        isExpanded: self.$settings.isDebugOpen,
                        collapsible: false
                    ) {
                        Toggle("Enable debug mode", isOn: self.$settings.debugEnabled)
                            .font(Typography.body)
                            .accessibilityIdentifier("debugToggle")
                    }
                    .accessibilityIdentifier("debugCard")
                }
                .padding()
            }
        }
    }
}

struct SupportTabView: View {
    @ObservedObject var settings: TunaSettings

    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: 16) {
                    CollapsibleCard(
                        title: "About",
                        isExpanded: self.$settings.isAboutOpen,
                        collapsible: false
                    ) {
                        AboutCardView()
                            .accessibilityIdentifier("aboutContent")
                    }
                    .accessibilityIdentifier("aboutCard")
                }
                .padding()
            }
        }
    }
}

struct TunaSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        TunaSettingsView()
    }
}
