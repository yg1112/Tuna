import AppKit
import os.log
import SwiftUI
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

    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            VStack(spacing: 12) {
                ForEach(SettingsTab.allCases) { tab in
                    SidebarTab(
                        icon: tab.icon,
                        label: tab.label,
                        isSelected: selectedTab == tab,
                        action: { selectedTab = tab }
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
                    switch selectedTab {
                        case .general:
                            generalTabView
                        case .dictation:
                            dictationTabView
                        case .audio:
                            audioTabView
                        case .appearance:
                            appearanceTabView
                        case .advanced:
                            advancedTabView
                        case .support:
                            supportTabView
                    }
                }
                .padding(Metrics.cardPad * 2)
            }
        }
        .frame(minWidth: 630, minHeight: 300)
    }

    // MARK: - Tab Views

    private var generalTabView: some View {
        VStack(alignment: .leading, spacing: Metrics.cardPad * 1.5) {
            CollapsibleCard(title: "Launch on Startup") {
                Toggle("Start Tuna when you login", isOn: $settings.launchAtLogin)
                    .font(Typography.body)
                    .padding(.top, 4)
            }

            CollapsibleCard(title: "Check for Updates") {
                VStack(alignment: .leading, spacing: 8) {
                    Text(
                        "Current version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")"
                    )
                    .font(Typography.body)

                    Button("Check Now") {
                        // Call update manager
                        // UpdateManager.checkNow()
                    }
                    .padding(.top, 4)
                }
            }
        }
    }

    private var dictationTabView: some View {
        VStack(alignment: .leading, spacing: Metrics.cardPad * 1.5) {
            CollapsibleCard(title: "Shortcut (PRO)") {
                VStack(alignment: .leading, spacing: 8) {
                    Toggle(
                        "Enable global dictation shortcut",
                        isOn: $settings.enableDictationShortcut
                    )
                    .font(Typography.body)

                    HStack {
                        Text("Key combination:")
                            .font(Typography.body)

                        ShortcutTextField(
                            keyCombo: $settings.dictationShortcutKeyCombo,
                            placeholder: "Click to set shortcut"
                        )
                    }
                    .padding(.top, 4)
                    .disabled(!settings.enableDictationShortcut)
                }
            }

            CollapsibleCard(title: "Magic Transform (PRO)") {
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Enable text transformation", isOn: $settings.magicEnabled)
                        .font(Typography.body)

                    Picker("Transformation style:", selection: $settings.magicPreset) {
                        ForEach(PresetStyle.allCases) { style in
                            Text(style.rawValue).tag(style)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .disabled(!settings.magicEnabled)
                    .padding(.top, 4)
                }
            }

            CollapsibleCard(title: "Engine", isExpanded: false) {
                VStack(alignment: .leading, spacing: 8) {
                    SecureField("Whisper API Key", text: .constant(""))
                        .font(Typography.body)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(maxWidth: 280)
                }
                .padding(.top, 4)
            }

            CollapsibleCard(title: "Transcription Output", isExpanded: false) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Format:")
                            .font(Typography.body)

                        Picker("", selection: $settings.transcriptionFormat) {
                            Text("Text (TXT)").tag("txt")
                            Text("Subtitles (SRT)").tag("srt")
                            Text("WebVTT (VTT)").tag("vtt")
                            Text("JSON").tag("json")
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .labelsHidden()
                        .frame(width: 280)
                    }

                    HStack {
                        Text("Save directory:")
                            .font(Typography.body)

                        Button(
                            settings.transcriptionOutputDirectory?
                                .lastPathComponent ?? "Choose..."
                        ) {
                            // Open directory picker
                            // let panel = NSOpenPanel()
                            // panel.canChooseDirectories = true
                            // panel.canChooseFiles = false
                            // if panel.runModal() == .OK {
                            //     settings.transcriptionOutputDirectory = panel.url
                            // }
                        }
                        .frame(width: 180, alignment: .leading)
                    }

                    Toggle(
                        "Auto-copy transcription to clipboard",
                        isOn: $settings.autoCopyTranscriptionToClipboard
                    )
                    .font(Typography.body)
                }
                .padding(.top, 4)
            }
        }
    }

    private var audioTabView: some View {
        VStack(alignment: .leading, spacing: Metrics.cardPad * 1.5) {
            CollapsibleCard(title: "Smart Swaps") {
                Toggle(
                    "Automatically change audio devices based on context",
                    isOn: $settings.enableSmartSwitching
                )
                .font(Typography.body)
                .padding(.top, 4)
            }

            CollapsibleCard(title: "Audio Devices") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Output:")
                            .font(Typography.body)
                            .frame(width: 60, alignment: .leading)

                        Picker(
                            "Output device",
                            selection: $settings.preferredOutputDeviceUID
                        ) {
                            ForEach(audioManager.outputDevices, id: \.uid) { device in
                                Text(device.name).tag(device.uid)
                            }
                        }
                        .labelsHidden()
                    }

                    HStack {
                        Text("Input:")
                            .font(Typography.body)
                            .frame(width: 60, alignment: .leading)

                        Picker("Input device", selection: $settings.preferredInputDeviceUID) {
                            ForEach(audioManager.inputDevices, id: \.uid) { device in
                                Text(device.name).tag(device.uid)
                            }
                        }
                        .labelsHidden()
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Volume:")
                            .font(Typography.body)

                        Slider(value: .constant(0.8), in: 0 ... 1)
                            .frame(maxWidth: 280)
                    }
                    .padding(.top, 4)
                }
                .padding(.top, 4)
            }
        }
    }

    private var appearanceTabView: some View {
        VStack(alignment: .leading, spacing: Metrics.cardPad * 1.5) {
            CollapsibleCard(title: "Theme") {
                Picker("Application theme:", selection: .constant("system")) {
                    Text("System").tag("system")
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.top, 4)
            }

            CollapsibleCard(title: "Appearance") {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Glass strength:")
                            .font(Typography.body)

                        Slider(value: .constant(0.7), in: 0 ... 1)
                            .frame(maxWidth: 280)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Font size:")
                            .font(Typography.body)

                        Picker("", selection: .constant("system")) {
                            Text("Small").tag("small")
                            Text("System").tag("system")
                            Text("Large").tag("large")
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(maxWidth: 280)
                        .labelsHidden()
                    }

                    Toggle("Reduce motion", isOn: .constant(false))
                        .font(Typography.body)
                }
                .padding(.top, 4)
            }
        }
    }

    private var advancedTabView: some View {
        VStack(alignment: .leading, spacing: Metrics.cardPad * 1.5) {
            CollapsibleCard(title: "Beta Features") {
                Toggle("Enable beta features", isOn: .constant(false))
                    .font(Typography.body)
                    .padding(.top, 4)
            }

            CollapsibleCard(title: "Debug") {
                VStack(alignment: .leading, spacing: 12) {
                    Button("Export Debug Log") {
                        // DebugLog.export()
                    }

                    Button("Reset All Settings") {
                        // Add confirmation alert
                        // Settings.resetAll()
                    }
                    .foregroundColor(.red)
                }
                .padding(.top, 4)
            }
        }
    }

    private var supportTabView: some View {
        VStack(alignment: .leading, spacing: Metrics.cardPad * 1.5) {
            CollapsibleCard(title: "About Tuna") {
                VStack(alignment: .center, spacing: 12) {
                    Image(systemName: "waveform")
                        .font(.system(size: 32))
                        .foregroundColor(Colors.accent)

                    Text("Tuna - Your audio assistant")
                        .font(Typography.title)

                    Text(
                        "Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")"
                    )
                    .font(Typography.caption)
                    .foregroundColor(.secondary)

                    Button("Contact Us") {
                        if let url = URL(string: "mailto:support@tuna.app") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                    .padding(.top, 8)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
        }
    }
}

struct TunaSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        TunaSettingsView()
    }
}
