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
    @ObservedObject private var audioManager = AudioManager.shared
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
        HStack(spacing: 0) {
            // Sidebar
            VStack(spacing: 12) {
                ForEach(SettingsTab.allCases) { tab in
                    SidebarTab(
                        icon: tab.icon,
                        label: tab.label,
                        isSelected: self.selectedTab == tab,
                        action: { self.selectedTab = tab }
                    )
                }

                Spacer()
            }
            .frame(width: 120)
            .padding(.top, 16)
            .background(Color(.windowBackgroundColor).opacity(0.9))

            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: Metrics.cardPad * 1.5) {
                    switch self.selectedTab {
                        case .general:
                            self.generalTabView
                        case .dictation:
                            self.dictationTabView
                        case .audio:
                            self.audioTabView
                        case .appearance:
                            self.appearanceTabView
                        case .advanced:
                            self.advancedTabView
                        case .support:
                            self.supportTabView
                    }
                }
                .padding(Metrics.cardPad * 2)
            }
        }
        .frame(minWidth: 630, minHeight: 300)
    }

    // MARK: - Tab Views

    private var generalTabView: some View {
        VStack(alignment: .leading, spacing: 20) {
            CollapsibleCard(
                title: "Launch on Startup",
                isExpanded: self.$settings.isLaunchOpen,
                collapsible: false
            ) {
                Toggle("Start Tuna when you login", isOn: self.$settings.launchAtLogin)
                    .font(Typography.body)
            }

            CollapsibleCard(
                title: "Check for Updates",
                isExpanded: self.$settings.isUpdatesOpen,
                collapsible: false
            ) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current version: 1.0.0")
                        .font(Typography.body)
                    Button("Check for Updates") {
                        // Update check logic
                    }
                }
            }
        }
        .padding(self.padding)
        .id("generalTab")
    }

    private var dictationTabView: some View {
        VStack(alignment: .leading, spacing: 20) {
            CollapsibleCard(
                title: "Shortcut",
                isExpanded: self.$settings.isShortcutOpen,
                collapsible: false
            ) {
                VStack(alignment: .leading, spacing: 8) {
                    Toggle(
                        "Enable global shortcut",
                        isOn: self.$settings.enableDictationShortcut
                    )
                    .font(Typography.body)
                }
            }
            .id("ShortcutCard")

            CollapsibleCard(
                title: "Magic Transform",
                isExpanded: self.$settings.isMagicTransformOpen
            ) {
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Enable text transformation", isOn: self.$settings.magicEnabled)
                        .font(Typography.body)
                }
            }
            .id("MagicTransformCard")

            CollapsibleCard(
                title: "Engine",
                isExpanded: self.$settings.isEngineOpen,
                collapsible: false
            ) {
                VStack(alignment: .leading, spacing: 8) {
                    SecureField("OpenAI API Key", text: self.$settings.whisperAPIKey)
                        .font(Typography.body)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .accessibilityIdentifier("API Key")

                    Text("Enter your OpenAI API key to enable transcription.")
                        .font(Typography.caption)
                        .foregroundColor(.secondary)
                }
            }
            .id("EngineCard")

            CollapsibleCard(
                title: "Transcription Output",
                isExpanded: self.$settings.isTranscriptionOutputOpen,
                collapsible: false
            ) {
                VStack(alignment: .leading, spacing: 12) {
                    // Format picker
                    Picker("Export Format:", selection: self.$settings.transcriptionFormat) {
                        ForEach(TranscriptionExportFormat.allCases) { format in
                            Text(format.displayName).tag(format.rawValue)
                        }
                    }
                    .font(Typography.body)

                    // Auto-copy toggle
                    Toggle(
                        "Auto-copy to clipboard",
                        isOn: self.$settings.autoCopyTranscriptionToClipboard
                    )
                    .font(Typography.body)

                    // Output directory picker
                    HStack {
                        Text("Save to:")
                            .font(Typography.body)
                        Spacer()
                        Text(self.settings.transcriptionOutputDirectoryDisplay)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Button("Browse…") {
                            self.showingDirectoryPicker = true
                        }
                    }
                }
            }
            .id("TranscriptionOutputCard")
            .fileImporter(
                isPresented: self.$showingDirectoryPicker,
                allowedContentTypes: [.folder],
                allowsMultipleSelection: false
            ) { result in
                if case let .success(urls) = result {
                    guard let url = urls.first else { return }
                    self.settings.transcriptionOutputDirectory = url
                }
            }
        }
        .padding(self.padding)
        .id("dictationTab")
    }

    private var audioTabView: some View {
        VStack(alignment: .leading, spacing: 20) {
            CollapsibleCard(
                title: "Smart Swaps",
                isExpanded: self.$settings.isSmartSwapsOpen,
                collapsible: false
            ) {
                Toggle(
                    "Automatically change audio devices based on context",
                    isOn: self.$settings.enableSmartSwitching
                )
                .font(Typography.body)
            }

            CollapsibleCard(
                title: "Audio Devices",
                isExpanded: self.$settings.isAudioDevicesOpen,
                collapsible: false
            ) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Input Device:")
                            .font(Typography.body)
                        Spacer()
                        Picker("", selection: .constant("default")) {
                            Text("Default").tag("default")
                            Text("Built-in").tag("builtin")
                        }
                        .labelsHidden()
                    }
                }
            }
        }
        .padding(self.padding)
        .id("audioTab")
    }

    private var appearanceTabView: some View {
        VStack(alignment: .leading, spacing: 20) {
            CollapsibleCard(
                title: "Theme",
                isExpanded: self.$settings.isThemeOpen,
                collapsible: false
            ) {
                Picker("Application theme:", selection: .constant("system")) {
                    Text("System").tag("system")
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                }
                .font(Typography.body)
            }

            CollapsibleCard(
                title: "Appearance",
                isExpanded: self.$settings.isAppearanceOpen,
                collapsible: false
            ) {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Menu Bar Icon")
                            .font(Typography.body)
                        Picker("", selection: .constant("default")) {
                            Text("Default").tag("default")
                            Text("Monochrome").tag("monochrome")
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                }
            }
        }
        .padding(self.padding)
        .id("appearanceTab")
    }

    private var advancedTabView: some View {
        VStack(alignment: .leading, spacing: 20) {
            CollapsibleCard(
                title: "Beta Features",
                isExpanded: self.$settings.isBetaOpen,
                collapsible: false
            ) {
                Toggle("Enable beta features", isOn: .constant(false))
                    .font(Typography.body)
            }

            CollapsibleCard(
                title: "Debug",
                isExpanded: self.$settings.isDebugOpen,
                collapsible: false
            ) {
                VStack(alignment: .leading, spacing: 12) {
                    Button("Export Debug Log") {
                        // Export logic
                    }
                    .font(Typography.body)
                }
            }
        }
        .padding(self.padding)
        .id("advancedTab")
    }

    private var supportTabView: some View {
        VStack(alignment: .leading, spacing: 20) {
            CollapsibleCard(
                title: "About Tuna",
                isExpanded: self.$settings.isAboutOpen,
                collapsible: false
            ) {
                VStack(alignment: .center, spacing: 12) {
                    Image(systemName: "waveform")
                        .font(.system(size: 48))
                        .foregroundColor(.accentColor)
                    Text("Tuna")
                        .font(.title)
                    Text("Version 1.0.0")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(self.padding)
        .id("supportTab")
    }
}

struct TunaSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        TunaSettingsView()
    }
}
