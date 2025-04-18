import SwiftUI
import AppKit
import os.log
import UserNotifications

// 定义一个统一的强调色 - 使用mint green替代蓝灰色调
extension Color {
    static let tunaAccent = Color(red: 0.3, green: 0.9, blue: 0.7)
}

// URL扩展方法 - 添加tilde路径简化
extension URL {
    func abbreviatingWithTildeInPath() -> String {
        let path = self.path
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
                    .fill(configuration.isOn ? Color(nsColor: .controlAccentColor) : Color.gray.opacity(0.3))
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
            .padding(.vertical, 16)   // 统一卡片内垂直边距为16pt
            .background(
                ZStack {
                    // 毛玻璃背景 - 稍微提亮
                    Color(red: 0.18, green: 0.18, blue: 0.18)
                    
                    // 微弱光晕效果模拟曲面反光
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.08),
                            Color.clear
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
        self.modifier(GlassCard())
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

// 定义设置页面的选项卡
enum SettingsTab: String, CaseIterable, Identifiable {
    case general = "General"
    case whispen = "Whispen"
    case smartSwaps = "Smart Swaps"
    case support = "Support"
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .general:
            return "gear"
        case .whispen:
            return "waveform"
        case .smartSwaps:
            return "arrow.triangle.2.circlepath"
        case .support:
            return "bubble.left.fill" // 更改为聊天气泡图标
        }
    }
}

struct ContactButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

struct TunaSettingsView: View {
    @StateObject private var settings = TunaSettings.shared
    @StateObject private var audioManager = AudioManager.shared
    @State private var isProcessingLoginSetting = false
    @State private var selectedTranscriptionFormat = UserDefaults.standard.string(forKey: "dictationFormat") ?? "txt"
    @State private var selectedOutputDeviceUID = UserDefaults.standard.string(forKey: "defaultOutputDeviceUID") ?? ""
    @State private var selectedInputDeviceUID = UserDefaults.standard.string(forKey: "defaultInputDeviceUID") ?? ""
    @State private var isInitializing = true // 防止初始化过程中触发更新
    @State private var selectedTab: SettingsTab = .general
    @State private var showSmartSwapInfo = false
    @State private var showWhispenInfo = false
    @State private var enableSmartDeviceSwapping = UserDefaults.standard.bool(forKey: "enableSmartDeviceSwapping") // 从UserDefaults初始化
    @State private var backupOutputDeviceUID = UserDefaults.standard.string(forKey: "backupOutputDeviceUID") ?? ""
    @State private var backupInputDeviceUID = UserDefaults.standard.string(forKey: "backupInputDeviceUID") ?? ""
    @State private var hoveredTab: SettingsTab? = nil
    @State private var apiKey = UserDefaults.standard.string(forKey: "dictationApiKey") ?? ""
    @State private var progressMessage = ""
    
    private let logger = Logger(subsystem: "com.tuna.app", category: "SettingsView")
    private let formats = ["txt", "srt", "vtt", "json"]
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部Tab栏
            HStack(spacing: 0) {
                Spacer()
                
                ForEach(SettingsTab.allCases) { tab in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab
                        }
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 15)) // 增加5%: 14 * 1.05 ≈ 15
                                .frame(height: 16) // 固定高度确保一致性
                            
                            Text(tab.rawValue)
                                .font(.system(size: 13)) // 增加5%: 12 * 1.05 ≈ 13
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false) // 确保文本不会被截断
                        }
                        .frame(minWidth: 80, minHeight: 44)  // 增加最小宽度和高度，确保有足够的点击面积
                        .padding(.vertical, 6)
                        .padding(.horizontal, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    selectedTab == tab ? Color.white.opacity(0.1) : 
                                    (hoveredTab == tab ? Color.white.opacity(0.05) : Color.clear)
                                )
                        )
                        .cornerRadius(6)
                        .contentShape(Rectangle()) // 确保整个背景区域都可点击
                        .onHover { hovering in
                            withAnimation(.easeInOut(duration: 0.15)) {
                                if hovering {
                                    hoveredTab = tab
                                    NSCursor.pointingHand.push()
                                } else {
                                    if hoveredTab == tab {
                                        hoveredTab = nil
                                    }
                                    if NSCursor.current == NSCursor.pointingHand {
                                        NSCursor.pop()
                                    }
                                }
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .foregroundColor(selectedTab == tab ? .white : .secondary)
                    .focusable(false)
                    
                    if tab != SettingsTab.allCases.last {
                        Spacer()
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(red: 0.12, green: 0.12, blue: 0.12))
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // 内容区域
            ZStack {
                // General Tab
                if selectedTab == .general {
                    generalTabView
                        .transition(.opacity)
                }
                
                // Whispen Tab
                if selectedTab == .whispen {
                    whispenTabView
                        .transition(.opacity)
                }
                
                // Smart Swaps Tab
                if selectedTab == .smartSwaps {
                    smartSwapsTabView
                        .transition(.opacity)
                }
                
                // Support Tab
                if selectedTab == .support {
                    supportTabView
                        .transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(red: 0.08, green: 0.08, blue: 0.08))
        }
        .onAppear {
            print("[VIEW] Settings view appeared")
            fflush(stdout)
            
            // 防止初始化触发循环更新
            isInitializing = true
            
            // Initialize picker values to match settings
            selectedTranscriptionFormat = settings.transcriptionFormat
            selectedOutputDeviceUID = settings.defaultOutputDeviceUID
            selectedInputDeviceUID = settings.defaultInputDeviceUID
            
            // 初始化完成后延迟将标志设为false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isInitializing = false
            }
        }
    }
    
    // MARK: - Tab Views
    
    // General Tab View
    private var generalTabView: some View {
        ScrollView {
            VStack(spacing: 30) { // 增加间距
                // Launch at Login Setting with Toggle
                VStack(alignment: .leading, spacing: 8) { // 使用8pt的标题/副标题间距
                    HStack(alignment: .firstTextBaseline) {
                        Text("Launch on Startup")
                            .font(.title3) // 使用统一的title3字体
                            .fontWeight(.bold) // 只在标题使用粗体
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Info button with tooltip - 调整对齐
                        Button(action: {}) {
                            Image(systemName: "info.circle")
                                .font(.footnote) // 使用统一的footnote字体
                        }
                        .buttonStyle(InfoButtonStyle())
                        .focusable(false)
                        .help("Controls whether Tuna starts automatically when you log in to your Mac")
                        
                        // Toggle button
                        Button(action: {
                            if !isProcessingLoginSetting {
                                toggleLoginItem()
                            }
                        }) {
                            HStack {
                                if isProcessingLoginSetting {
                                    ProgressView()
                                        .scaleEffect(0.5)
                                        .padding(.trailing, 2)
                                } else {
                                    ZStack {
                                        Capsule()
                                            .fill(settings.launchAtLogin ? Color(nsColor: .controlAccentColor) : Color.gray.opacity(0.3))
                                            .frame(width: 40, height: 15)
                                            .focusable(false)
                                        
                                        Circle()
                                            .fill(Color.white)
                                            .shadow(radius: 1)
                                            .frame(width: 13, height: 13)
                                            .offset(x: settings.launchAtLogin ? 13 : -13)
                                            .animation(.spring(response: 0.2), value: settings.launchAtLogin)
                                            .focusable(false)
                                    }
                                    .focusable(false)
                                }
                            }
                        }
                        .disabled(isProcessingLoginSetting)
                        .buttonStyle(PlainButtonStyle())
                        .focusable(false)
                    }
                    
                    // Add description text for launch at login setting
                    Text("Automatically start Tuna when you log in to your Mac.")
                        .font(.subheadline) // 使用统一的subheadline字体
                        .foregroundColor(.secondary) // 使用系统级次要文本颜色
                        .padding(.top, 2)
                }
                .glassCard()
                
                // Default Audio Devices Setting已移到Smart Swaps选项卡
                
                Spacer(minLength: 20) // 提供一些最小间距
            }
            .padding(.top, 30) // 增加顶部内边距
            .padding(.horizontal, 24) // 稍微增加水平内边距
            .padding(.bottom, 30) // 增加底部内边距
        }
        .scrollContentBackground(.hidden)
    }
    
    // Whispen Tab View
    private var whispenTabView: some View {
        ScrollView {
            VStack(spacing: 30) { // 增加间距从20pt到30pt，使布局更宽松
                // Whispen Settings
                VStack(alignment: .leading, spacing: 12) { // 增加内部间距
                    HStack(alignment: .firstTextBaseline) {
                        Text("Whispen (Voice Recognition)")
                            .font(.title3) // 使用统一的title3字体
                            .fontWeight(.bold) // 只在标题使用粗体
                            .foregroundColor(.white)
                        
                        // 添加Whispen信息按钮
                        Button(action: {
                            showWhispenInfo.toggle()
                        }) {
                            Image(systemName: "info.circle")
                                .font(.footnote) // 使用统一的footnote字体
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        .focusable(false)
                        .popover(isPresented: $showWhispenInfo, arrowEdge: .top) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("About Whispen")
                                    .font(.subheadline) // 使用统一的subheadline字体
                                    .fontWeight(.bold) // 只在标题使用粗体
                                
                                Text("Whispen uses OpenAI's Whisper model to transcribe your speech into text with high accuracy. The model automatically detects the spoken language.")
                                    .font(.footnote) // 使用统一的footnote字体
                                    .foregroundColor(Color(NSColor.secondaryLabelColor))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding()
                            .frame(width: 280)
                        }
                    }
                    .padding(.bottom, 8)
                    
                    Text("Configure your voice recognition settings for dictation.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 16)
                    
                    // API Key配置
                    VStack(alignment: .leading, spacing: 4) {
                        Text("API Key")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        
                        HStack {
                            if apiKey.isEmpty {
                                SecureField("OpenAI API Key", text: $apiKey)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .onSubmit {
                                        saveDictationSettings()
                                    }
                            } else {
                                SecureField("••••••••••••••••••••••••", text: $apiKey)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .onSubmit {
                                        saveDictationSettings()
                                    }
                            }
                            
                            Button("Save") {
                                saveDictationSettings()
                            }
                            .buttonStyle(GreenButtonStyle())
                        }
                    }
                    .padding(.bottom, 16)
                    
                    // 添加语言选择
                    VStack(alignment: .leading, spacing: 4) {
                        Text("语言设置")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        
                        Text("默认情况下，Whisper会自动检测语言。您也可以指定要使用的语言。")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 8)
                        
                        HStack {
                            Picker("转录语言", selection: $settings.transcriptionLanguage) {
                                Text("自动检测").tag("")
                                Text("中文").tag("zh")
                                Text("英语").tag("en")
                                Text("日语").tag("ja")
                                Text("韩语").tag("ko")
                                Text("法语").tag("fr")
                                Text("德语").tag("de")
                                Text("西班牙语").tag("es")
                                Text("俄语").tag("ru")
                                Text("意大利语").tag("it")
                            }
                            .pickerStyle(MenuPickerStyle())
                            .frame(width: 150)
                            
                            Spacer()
                            
                            Button("重置为自动") {
                                settings.transcriptionLanguage = ""
                            }
                            .buttonStyle(PlainButtonStyle())
                            .foregroundColor(.blue)
                            .disabled(settings.transcriptionLanguage.isEmpty)
                            .opacity(settings.transcriptionLanguage.isEmpty ? 0.5 : 1.0)
                        }
                    }
                    .padding(.bottom, 16)
                    
                    // 格式选择
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Transcription Format")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        
                        HStack {
                            Picker("Format", selection: $selectedTranscriptionFormat) {
                                ForEach(formats, id: \.self) { format in
                                    Text(format.uppercased()).tag(format)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .onChange(of: selectedTranscriptionFormat) { newValue in
                                updateFormatSetting()
                            }
                        }
                        
                        Text("Select how transcriptions will be saved.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 16)
                    
                    Divider()
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.clear, Color.white.opacity(0.1), Color.clear]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .padding(.vertical, 8)
                    
                    // Output Directory Selection
                    VStack(alignment: .leading, spacing: 8) { // 使用8pt的标题/副标题间距
                        Text("Output Directory")
                            .font(.subheadline) // 使用统一的subheadline字体
                            .foregroundColor(.white)
                        
                        HStack {
                            Text(settings.transcriptionOutputDirectory?.abbreviatingWithTildeInPath() ?? "Not set")
                                .font(.footnote) // 使用统一的footnote字体
                                .foregroundColor(.secondary)
                                .truncationMode(.middle)
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                                .background(Color.black.opacity(0.2))
                                .cornerRadius(4)
                            
                            Button(action: {
                                let panel = NSOpenPanel()
                                panel.canChooseFiles = false
                                panel.canChooseDirectories = true
                                panel.allowsMultipleSelection = false
                                panel.canCreateDirectories = true
                                panel.prompt = "Select Output Directory"
                                
                                if panel.runModal() == .OK {
                                    if let url = panel.url {
                                        settings.transcriptionOutputDirectory = url
                                    }
                                }
                            }) {
                                Text("Browse")
                                    .font(.footnote) // 使用统一的footnote字体
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                            .focusable(false)
                        }
                        
                        Text("Choose where to save transcriptions")
                            .font(.footnote) // 使用统一的footnote字体
                            .foregroundColor(.secondary)
                            .padding(.top, 2)
                    }
                    
                    Divider()
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.clear, Color.white.opacity(0.1), Color.clear]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .padding(.vertical, 8)
                    
                    // Auto Copy Toggle
                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Auto Copy")
                                    .font(.subheadline) // 使用统一的subheadline字体
                                    .foregroundColor(.white)
                                
                                Text("Copied instantly after each recording.")
                                    .font(.footnote) // 使用统一的footnote字体
                                    .foregroundColor(.secondary)
                                    .padding(.bottom, 8)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                settings.autoCopyTranscriptionToClipboard.toggle()
                            }) {
                                ZStack {
                                    Capsule()
                                        .fill(settings.autoCopyTranscriptionToClipboard ? Color(nsColor: .controlAccentColor) : Color.gray.opacity(0.3))
                                        .frame(width: 40, height: 15)
                                        .focusable(false)
                                    
                                    Circle()
                                        .fill(Color.white)
                                        .shadow(radius: 1)
                                        .frame(width: 13, height: 13)
                                        .offset(x: settings.autoCopyTranscriptionToClipboard ? 13 : -13)
                                        .animation(.spring(response: 0.2), value: settings.autoCopyTranscriptionToClipboard)
                                        .focusable(false)
                                }
                                .focusable(false)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .focusable(false)
                        }
                    }
                }
                .glassCard()
                
                // 添加Magic Transform设置
                VStack(alignment: .leading, spacing: 12) {
                    Text("Magic Transform")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Configure settings for the Magic Transform feature")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 8)
                    
                    TranscriptSettingsView(settings: settings)
                }
                .glassCard()
                
                // 添加Dictation快捷键设置
                VStack(alignment: .leading, spacing: 12) {
                    Text("Dictation Shortcut")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Configure a global shortcut to quickly start dictation from anywhere")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 8)
                    
                    // 启用/禁用快捷键开关
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Enable Global Shortcut")
                                .font(.subheadline)
                                .foregroundColor(.white)
                            
                            Text("When enabled, press the shortcut to start dictation instantly")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            settings.enableDictationShortcut.toggle()
                        }) {
                            ZStack {
                                Capsule()
                                    .fill(settings.enableDictationShortcut ? Color(nsColor: .controlAccentColor) : Color.gray.opacity(0.3))
                                    .frame(width: 40, height: 15)
                                    .focusable(false)
                                
                                Circle()
                                    .fill(Color.white)
                                    .shadow(radius: 1)
                                    .frame(width: 13, height: 13)
                                    .offset(x: settings.enableDictationShortcut ? 13 : -13)
                                    .animation(.spring(response: 0.2), value: settings.enableDictationShortcut)
                                    .focusable(false)
                            }
                            .focusable(false)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .focusable(false)
                    }
                    .padding(.bottom, 8)
                    
                    // 快捷键设置 - 不再包裹在if条件中，确保始终显示
                    Text("Shortcut Key Combination")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.top, 8)
                    
                    HStack {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(nsColor: .textBackgroundColor))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                                )
                            
                            ShortcutTextField(
                                value: $settings.dictationShortcutKeyCombo,
                                onCommit: saveShortcut
                            )
                                .frame(height: 24)
                                .padding(.horizontal, 6)
                        }
                        .frame(height: 28)
                        .frame(maxWidth: .infinity)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color(nsColor: .controlAccentColor), lineWidth: 1.5)
                                .opacity(settings.enableDictationShortcut ? 0.7 : 0)
                        )
                        .animation(.easeInOut(duration: 0.2), value: settings.enableDictationShortcut)
                        
                        Button("Reset to Default") {
                            settings.dictationShortcutKeyCombo = "cmd+u"
                            saveShortcut()
                        }
                        .font(.system(size: 13))
                        .buttonStyle(GreenButtonStyle())
                        .disabled(!settings.enableDictationShortcut)
                        .opacity(settings.enableDictationShortcut ? 1.0 : 0.5)
                    }
                    
                    Text("Format examples: cmd+u, cmd+shift+d, ctrl+space")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                    
                    Divider()
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.clear, Color.white.opacity(0.1), Color.clear]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .padding(.vertical, 8)
                    
                    // 显示模式设置 - 移出条件判断，但添加禁用效果
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Show Dictation Page on Shortcut")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                
                                Text("When disabled, dictation runs silently in the background (shows menubar icon only)")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                settings.showDictationPageOnShortcut.toggle()
                            }) {
                                ZStack {
                                    Capsule()
                                        .fill(settings.showDictationPageOnShortcut ? Color(nsColor: .controlAccentColor) : Color.gray.opacity(0.3))
                                        .frame(width: 40, height: 15)
                                        .focusable(false)
                                    
                                    Circle()
                                        .fill(Color.white)
                                        .shadow(radius: 1)
                                        .frame(width: 13, height: 13)
                                        .offset(x: settings.showDictationPageOnShortcut ? 13 : -13)
                                        .animation(.spring(response: 0.2), value: settings.showDictationPageOnShortcut)
                                        .focusable(false)
                                }
                                .focusable(false)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .focusable(false)
                            .disabled(!settings.enableDictationShortcut) // 禁用状态取决于开关
                            .opacity(settings.enableDictationShortcut ? 1.0 : 0.5) // 设置透明度以指示状态
                        }
                    }
                    
                    Divider()
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.clear, Color.white.opacity(0.1), Color.clear]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .padding(.vertical, 8)
                    
                    // 添加说明文字，解释单击模式
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Shortcut Behavior")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        
                        Text("Press once to start recording, press again to stop. When paused, press to resume.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 4)
                    }
                    .opacity(settings.enableDictationShortcut ? 1.0 : 0.5) // 设置透明度以指示状态
                    
                    Divider()
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.clear, Color.white.opacity(0.1), Color.clear]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .padding(.vertical, 8)
                    
                    // 声音反馈设置
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Sound Feedback")
                                .font(.subheadline)
                                .foregroundColor(.white)
                            
                            Text("Play system sounds when dictation starts/stops")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            settings.enableDictationSoundFeedback.toggle()
                        }) {
                            ZStack {
                                Capsule()
                                    .fill(settings.enableDictationSoundFeedback ? Color(nsColor: .controlAccentColor) : Color.gray.opacity(0.3))
                                    .frame(width: 40, height: 15)
                                    .focusable(false)
                                
                                Circle()
                                    .fill(Color.white)
                                    .shadow(radius: 1)
                                    .frame(width: 13, height: 13)
                                    .offset(x: settings.enableDictationSoundFeedback ? 13 : -13)
                                    .animation(.spring(response: 0.2), value: settings.enableDictationSoundFeedback)
                                    .focusable(false)
                            }
                            .focusable(false)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .focusable(false)
                        .disabled(!settings.enableDictationShortcut) // 禁用状态取决于开关
                        .opacity(settings.enableDictationShortcut ? 1.0 : 0.5) // 设置透明度以指示状态
                    }
                }
                .glassCard()
                
                Spacer(minLength: 20) // 提供一些最小间距，确保底部有足够空间
            }
            .padding(.top, 30) // 增加顶部内边距，使布局更加均衡
            .padding(.horizontal, 24) // 稍微增加水平内边距
            .padding(.bottom, 30) // 增加底部内边距，确保有足够空间
        }
        .scrollContentBackground(.hidden)
    }
    
    // Smart Swaps Tab View
    private var smartSwapsTabView: some View {
        ScrollView {
            VStack(spacing: 30) { // 增加间距
                // Smart Swaps
                VStack(alignment: .leading, spacing: 12) { // 增加内部间距
                    HStack(alignment: .firstTextBaseline) {
                        Text("Smart Swaps (Auto-Routing)")
                            .font(.title3) // 使用统一的title3字体
                            .fontWeight(.bold) // 只在标题使用粗体
                            .foregroundColor(.white)
                        
                        // 添加智能交换信息按钮
                        Button(action: {
                            showSmartSwapInfo.toggle()
                        }) {
                            Image(systemName: "info.circle")
                                .font(.footnote) // 使用统一的footnote字体
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        .focusable(false)
                        .popover(isPresented: $showSmartSwapInfo, arrowEdge: .top) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("What are Smart Swaps?")
                                    .font(.subheadline) // 使用统一的subheadline字体
                                    .fontWeight(.bold) // 只在标题使用粗体
                                
                                Text("Tuna will always try to use your preferred devices whenever they are available. If a device becomes unavailable, Tuna will automatically route audio to another available device.")
                                    .font(.footnote) // 使用统一的footnote字体
                                    .foregroundColor(Color(NSColor.secondaryLabelColor))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding()
                            .frame(width: 280)
                        }
                        
                        Spacer()
                    }
                    .padding(.bottom, 8) // 标题与描述之间的间距
                    
                    // 更新描述，说明与默认设备的关系
                    Text("Tuna will always try to use your preferred devices whenever they are available. Smart Swaps ensures a seamless audio experience without disruptions.")
                        .font(.subheadline) // 使用统一的subheadline字体
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, 16)
                    
                    // 启用智能交换功能的开关
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Enable Smart Swaps")
                                .font(.subheadline) // 使用统一的subheadline字体
                                .foregroundColor(.white)
                                
                            Text("Automatically route audio between available devices")
                                .font(.footnote) // 使用统一的footnote字体
                                .foregroundColor(.secondary)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            enableSmartDeviceSwapping.toggle()
                            // 保存开关状态到UserDefaults
                            UserDefaults.standard.set(enableSmartDeviceSwapping, forKey: "enableSmartDeviceSwapping")
                            
                            // 发送通知以实时更新其他UI组件中的状态显示
                            NotificationCenter.default.post(
                                name: NSNotification.Name("smartSwapsStatusChanged"),
                                object: nil,
                                userInfo: ["enabled": enableSmartDeviceSwapping]
                            )
                            
                            // 如果开启了Smart Swaps，立即应用首选设备设置
                            if enableSmartDeviceSwapping {
                                DispatchQueue.main.async {
                                    print("\u{001B}[32m[设置]\u{001B}[0m 用户启用Smart Swaps，立即应用首选设备设置")
                                    AudioManager.shared.forceApplySmartDeviceSwapping()
                                }
                            }
                        }) {
                            ZStack {
                                Capsule()
                                    .fill(enableSmartDeviceSwapping ? Color(nsColor: .controlAccentColor) : Color.gray.opacity(0.3))
                                    .frame(width: 40, height: 15)
                                    .focusable(false)
                                
                                Circle()
                                    .fill(Color.white)
                                    .shadow(radius: 1)
                                    .frame(width: 13, height: 13)
                                    .offset(x: enableSmartDeviceSwapping ? 13 : -13)
                                    .animation(.spring(response: 0.2), value: enableSmartDeviceSwapping)
                                    .focusable(false)
                            }
                            .focusable(false)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .focusable(false)
                    }
                    .padding(.bottom, 16)
                    
                    if enableSmartDeviceSwapping {
                        // 更新为Preferred Output Device标签
                        Text("Preferred Output Device (when available)")
                            .font(.subheadline) // 使用统一的subheadline字体
                            .foregroundColor(.white)
                            .padding(.top, 8)
                        
                        devicePicker(
                            title: "",
                            devices: audioManager.outputDevices,
                            selectedDeviceUID: $backupOutputDeviceUID,
                            onDeviceSelected: { device in
                                backupOutputDeviceUID = device.uid
                                // 保存备用输出设备UID
                                UserDefaults.standard.set(device.uid, forKey: "backupOutputDeviceUID")
                                
                                // 如果Smart Swaps已启用，立即应用新选择的首选设备
                                DispatchQueue.main.async {
                                    let smartSwapsEnabled = UserDefaults.standard.bool(forKey: "enableSmartDeviceSwapping")
                                    if smartSwapsEnabled {
                                        // 调用AudioManager的方法强制应用Smart Swaps设置
                                        print("\u{001B}[32m[设置]\u{001B}[0m 用户更改首选输出设备，立即应用")
                                        AudioManager.shared.forceApplySmartDeviceSwapping()
                                    }
                                }
                            }
                        )
                        .padding(.bottom, 8)
                        
                        // 更新为Preferred Input Device标签
                        Text("Preferred Input Device (when available)")
                            .font(.subheadline) // 使用统一的subheadline字体
                            .foregroundColor(.white)
                            .padding(.top, 8)
                        
                        devicePicker(
                            title: "",
                            devices: audioManager.inputDevices,
                            selectedDeviceUID: $backupInputDeviceUID,
                            onDeviceSelected: { device in
                                backupInputDeviceUID = device.uid
                                // 保存备用输入设备UID
                                UserDefaults.standard.set(device.uid, forKey: "backupInputDeviceUID")
                                
                                // 如果Smart Swaps已启用，立即应用新选择的首选设备
                                DispatchQueue.main.async {
                                    let smartSwapsEnabled = UserDefaults.standard.bool(forKey: "enableSmartDeviceSwapping")
                                    if smartSwapsEnabled {
                                        // 调用AudioManager的方法强制应用Smart Swaps设置
                                        print("\u{001B}[32m[设置]\u{001B}[0m 用户更改首选输入设备，立即应用")
                                        AudioManager.shared.forceApplySmartDeviceSwapping()
                                    }
                                }
                            }
                        )
                    }
                }
                .glassCard()
                
                Spacer(minLength: 20) // 提供一些最小间距
            }
            .padding(.top, 30) // 增加顶部内边距
            .padding(.horizontal, 24) // 稍微增加水平内边距
            .padding(.bottom, 30) // 增加底部内边距
        }
        .scrollContentBackground(.hidden)
    }
    
    // Support Tab View
    private var supportTabView: some View {
        VStack(spacing: 40) { // 增加间距，支持页面可以更宽松
            // About & Support Card
            VStack(alignment: .leading, spacing: 12) { // 增加内部间距
                Text("About & Support")
                    .font(.title3) // 使用统一的title3字体
                    .fontWeight(.bold) // 只在标题使用粗体
                    .foregroundColor(.white)
                
                VStack(alignment: .center, spacing: 12) {
                    Image(systemName: "fish") // 使用小鱼图标，与主卡片保持一致
                        .font(.system(size: 20)) // 限制图标最大尺寸为20pt
                        .foregroundColor(Color(nsColor: .controlAccentColor)) // 使用系统控制中心绿色
                        .padding(.bottom, 8)
                    
                    Text("Built with love. For makers like you.")
                        .font(.subheadline) // 使用统一的subheadline字体
                        .foregroundColor(.secondary) // 改为次要文本颜色，而不是绿色强调色
                        .padding(.top, 4)
                    
                    // Contact Button
                    Button(action: {
                        if let url = URL(string: "mailto:support@example.com") {
                            NSWorkspace.shared.open(url)
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "envelope") // 简化图标，移除.fill
                                .font(.footnote) // 使用统一的footnote字体
                            
                            Text("Contact Us")
                                .font(.subheadline) // 使用统一的subheadline字体
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(nsColor: .controlAccentColor)) // 使用系统控制中心绿色替代 tunaAccent
                    .controlSize(.regular)
                    .focusable(false)
                    .padding(.top, 16)
                    
                    Text("Something not working? Drop us a note.\nWe'd love to hear from you.")
                        .font(.footnote) // 使用统一的footnote字体
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
            .glassCard()
            
            Spacer()
            
            // 底部版权信息 - 居中排布，更新文案
            VStack(spacing: 4) {
                HStack(spacing: 2) {
                    Text("© 2025 DZG Studio LLC")
                        .font(.footnote) // 使用统一的footnote字体
                        .foregroundColor(.secondary) // 使用系统级次要文本颜色
                    
                    Text("·")
                        .font(.footnote) // 使用统一的footnote字体
                        .foregroundColor(.secondary.opacity(0.4))
                        .padding(.horizontal, 4)
                    
                    Text("Designing with Zeal & Grace")
                        .font(.footnote) // 使用统一的footnote字体
                        .foregroundColor(.secondary) // 使用系统级次要文本颜色（与前面保持一致）
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 30) // 增加底部内边距
        }
        .padding(.top, 30) // 增加顶部内边距
        .padding(.horizontal, 24) // 稍微增加水平内边距
        .padding(.bottom, 30) // 增加底部内边距
    }
    
    // MARK: - Helper Methods
    
    private func toggleLoginItem() {
        // Prevent multiple clicks
        isProcessingLoginSetting = true
        
        print("[DEBUG] Toggling login item setting")
        
        // Set new state
        let newValue = !settings.launchAtLogin
        settings.launchAtLogin = newValue
        
        // Short delay to check result and update UI
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // Processing complete
            self.isProcessingLoginSetting = false
            
            print("[RESULT] Launch at login " + (newValue ? "enabled" : "disabled"))
            fflush(stdout)
        }
    }
    
    // Select transcription file save directory
    private func selectOutputDirectory() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.prompt = "Select"
        panel.title = "Select Output Directory for Transcriptions"
        
        // Find current active window
        if let window = NSApplication.shared.keyWindow ?? NSApplication.shared.mainWindow {
            panel.beginSheetModal(for: window) { response in
                if response == .OK, let url = panel.url {
                    DispatchQueue.main.async {
                        // Update settings
                        settings.transcriptionOutputDirectory = url
                        print("[SETTINGS] Transcription output directory set: \(url.path)")
                        fflush(stdout)
                    }
                }
            }
        } else {
            // If no current window found, use standard modal
            let response = panel.runModal()
            if response == .OK, let url = panel.url {
                DispatchQueue.main.async {
                    // Update settings
                    settings.transcriptionOutputDirectory = url
                    print("[SETTINGS] Transcription output directory set: \(url.path)")
                    fflush(stdout)
                }
            }
        }
    }
    
    // 设备选择函数
    private func devicePicker(
        title: String,
        devices: [AudioDevice],
        selectedDeviceUID: Binding<String>,
        onDeviceSelected: @escaping (AudioDevice) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if !title.isEmpty {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
            
            Menu {
                ForEach(devices) { device in
                    Button(action: {
                        onDeviceSelected(device)
                    }) {
                        HStack {
                            Text(device.name)
                            Spacer()
                            if device.uid == selectedDeviceUID.wrappedValue {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    let selectedDevice = devices.first(where: { $0.uid == selectedDeviceUID.wrappedValue })
                    Text(selectedDevice?.name ?? "Select a device")
                        .font(.footnote)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .padding(8)
                .background(Color.black.opacity(0.2))
                .cornerRadius(6)
            }
        }
    }
    
    // 在TunaSettingsView中添加saveShortcut方法
    private func saveShortcut() {
        let v = settings.dictationShortcutKeyCombo
        UserDefaults.standard.set(v, forKey:"dictationShortcutKeyCombo")
        NotificationCenter.default.post(name:.dictationShortcutSettingsChanged, object:nil)
    }
    
    private func saveDictationSettings() {
        // 保存API密钥
        UserDefaults.standard.set(apiKey, forKey: "dictationApiKey")
        logger.debug("Saved dictation API key")
        
        // 保存其他Whispen设置
        updateFormatSetting()
        
        // 显示保存成功信息
        progressMessage = "API key saved successfully"
        
        // 请求通知权限
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    // 创建通知反馈
                    let notification = UNMutableNotificationContent()
                    notification.title = "Tuna"
                    notification.body = "Dictation settings updated"
                    notification.sound = UNNotificationSound.default
                    
                    let request = UNNotificationRequest(identifier: UUID().uuidString, content: notification, trigger: nil)
                    UNUserNotificationCenter.current().add(request)
                }
            }
        }
    }
    
    private func updateFormatSetting() {
        if !isInitializing && selectedTranscriptionFormat != settings.transcriptionFormat {
            settings.transcriptionFormat = selectedTranscriptionFormat
            logger.debug("Updated transcription format to: \(selectedTranscriptionFormat)")
        }
    }
} 