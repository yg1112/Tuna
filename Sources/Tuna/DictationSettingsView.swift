import AppKit
import SwiftUI
import TunaCore
import TunaSpeech
import TunaTypes
import TunaUI

// import Views -- 已移至 Tuna 模块

// 添加临时枚举定义
// TODO: replace with shared enum when available
enum TranscriptionExportFormat: String, CaseIterable, Identifiable {
    case txt, srt, vtt
    var id: Self { self }
    var displayName: String { rawValue.uppercased() }
}

// DictationManager已在自身文件中实现了DictationManagerProtocol，这里不需要重复声明

@available(macOS 14.0, *)
struct DictationSettingsView: View {
    @ObservedObject private var dictationManager = DictationManager.shared
    @ObservedObject private var settings = TunaSettings.shared

    // 使用 @State 只持有卡片展开状态，其他值使用 settings
    @State private var isTranscriptionOutputExpanded = false
    @State private var isApiKeyValid = false

    private let accentColor = Color.green

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Launch at Login 部分
                self.launchAtLoginSection

                Divider()

                // Engine 部分
                self.engineSection

                // Transcription Output 部分
                self.transcriptionOutputSection

                // Magic Transform 部分
                self.magicTransformSection

                Spacer()
            }
            .padding(20)
            .accentColor(self.accentColor) // 设置整个视图的强调色
        }
    }

    // 启动登录部分
    private var launchAtLoginSection: some View {
        HStack {
            Text("Launch at Login")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.primary)

            Spacer()

            // 使用CustomToggleStyle确保绿色显示
            Toggle("", isOn: Binding(
                get: { self.settings.launchAtLogin },
                set: { self.settings.launchAtLogin = $0 }
            ))
            .toggleStyle(GreenToggleStyle())
            .labelsHidden()
        }
        .padding(.top, 10)
    }

    // 引擎部分
    private var engineSection: some View {
        Section {
            HStack {
                SecureField("OpenAI API Key", text: Binding(
                    get: { self.settings.whisperAPIKey },
                    set: { self.settings.whisperAPIKey = $0 }
                ))
                .font(.system(size: 14))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onChange(of: self.settings.whisperAPIKey) { _ in
                    self.validateApiKey(self.settings.whisperAPIKey)
                }
                .onAppear {
                    self.validateApiKey(self.settings.whisperAPIKey)
                }
                .accessibilityIdentifier("API Key")

                // API Key 验证状态指示器
                if !self.settings.whisperAPIKey.isEmpty {
                    Image(
                        systemName: self.isApiKeyValid ? "checkmark.circle.fill" :
                            "exclamationmark.circle.fill"
                    )
                    .foregroundColor(self.isApiKeyValid ? .green : .red)
                    .font(.system(size: 16))
                    .help(self.isApiKeyValid ? "API key is valid" : "Invalid API key format")
                }
            }

            // API Key 说明文本
            Text("Enter your OpenAI API key to enable transcription.")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .onAppear { print("▶️ Engine appear") }
        .onDisappear { print("◀️ Engine disappear") }
        .onChange(of: self.settings.isEngineOpen) { _, newValue in
            print("💚 Engine state ->", newValue)
        }
    }

    // 转录输出部分
    private var transcriptionOutputSection: some View {
        Section {
            // 导出格式选择器
            self.formatSelector

            // 输出目录选择器
            self.outputDirectorySelector

            // 自动复制到剪贴板选项
            Toggle("Auto-copy transcription to clipboard", isOn: Binding(
                get: { self.settings.autoCopyTranscriptionToClipboard },
                set: { self.settings.autoCopyTranscriptionToClipboard = $0 }
            ))
            .font(.system(size: 14))
        }
        .onAppear { print("▶️ TranscriptionOutput appear") }
        .onDisappear { print("◀️ TranscriptionOutput disappear") }
        .onChange(of: self.settings.isTranscriptionOutputOpen) { _, newValue in
            print("💚 TranscriptionOutput state ->", newValue)
        }
    }

    // 格式选择器
    private var formatSelector: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Format:")
                .font(.system(size: 14))
                .foregroundColor(.primary)

            Picker("", selection: Binding<TranscriptionExportFormat>(
                get: { .txt }, // 默认使用txt格式，后续可通过settings.exportFormat获取
                set: { _ in } // 设置逻辑，后续可通过settings.exportFormat = $0 设置
            )) {
                ForEach(TranscriptionExportFormat.allCases) { format in
                    Text(format.displayName).tag(format)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .labelsHidden()
            .accessibilityIdentifier("Format")
        }
    }

    // 输出目录选择器
    private var outputDirectorySelector: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Output Directory:")
                .font(.system(size: 14))
                .foregroundColor(.primary)

            HStack {
                Text(self.dictationManager.outputDirectory?.lastPathComponent ?? "Desktop")
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                    )
                    .focusable(false)
                    .id("OutputDirectoryField")

                Button("Select") {
                    Task {
                        await self.selectOutputDirectory()
                    }
                }
                .font(.system(size: 13))
                .buttonStyle(GreenButtonStyle())
                .focusable(false)
                .accessibilityIdentifier("Select Folder")
            }
        }
    }

    private func selectOutputDirectory() async {
        // 在打开面板前发送文件选择开始通知，确保设置窗口不会关闭
        await Task<Void, Never> {
            await Notifier.post(NSNotification.Name.fileSelectionStarted)
        }.value

        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "选择转录文件保存目录"
        panel.prompt = "选择"

        if panel.runModal() == .OK {
            if let url = panel.url {
                self.settings.transcriptionOutputDirectory = url

                // 延迟一段时间再发送结束通知，确保窗口有足够时间显示
                await Task<Void, Never> {
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
                    await Notifier.post(NSNotification.Name.fileSelectionEnded)
                }.value
            }
        }
    }

    // 验证API密钥的格式
    private func validateApiKey(_ key: String) {
        // 简单的格式验证 - OpenAI API密钥通常以"sk-"开头并且较长
        self.isApiKeyValid = key.hasPrefix("sk-") && key.count > 10
    }

    // Magic Transform 部分
    private var magicTransformSection: some View {
        CollapsibleCard(
            title: "Magic Transform",
            isExpanded: .constant(true),
            collapsible: false
        ) {
            VStack(alignment: .leading, spacing: 8) {
                Toggle("Enable text transformation", isOn: self.$settings.magicEnabled)
                    .font(.system(size: 14))
            }
        }
        .id("MagicTransformCard")
    }
}

// 自定义绿色开关样式
struct GreenToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label

            ZStack {
                Capsule()
                    .fill(
                        configuration.isOn ? Color(nsColor: .controlAccentColor) : Color.gray
                            .opacity(0.3)
                    )
                    .frame(width: 50, height: 29)

                Circle()
                    .fill(Color.white)
                    .frame(width: 25, height: 25)
                    .offset(x: configuration.isOn ? 10 : -10)
                    .animation(.spring(response: 0.2), value: configuration.isOn)
            }
            .onTapGesture {
                withAnimation {
                    configuration.isOn.toggle()
                }
            }
        }
    }
}

// 自定义绿色按钮样式
// struct GreenButtonStyle: ButtonStyle {
//    func makeBody(configuration: Configuration) -> some View {
//        configuration.label
//            .padding(.horizontal, 12)
//            .padding(.vertical, 6)
//            .background(Color(nsColor: .controlAccentColor))
//            .foregroundColor(.white)
//            .cornerRadius(6)
//            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
//            .focusable(false) // 禁用焦点环
//    }
// }
