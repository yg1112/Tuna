import SwiftUI
import AppKit
import os.log

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
            VStack(spacing: 24) { // 保持24pt的部分间距
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
                
                Spacer()
            }
            .padding(.top, 24)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .scrollContentBackground(.hidden)
    }
    
    // Whispen Tab View
    private var whispenTabView: some View {
        ScrollView {
            VStack(spacing: 24) { // 保持24pt的部分间距
                // Whispen Settings
                VStack(alignment: .leading, spacing: 8) { // 使用8pt的标题/副标题间距
                    HStack(alignment: .firstTextBaseline) {
                        Text("Whispen Settings")
                            .font(.title3) // 使用统一的title3字体
                            .fontWeight(.bold) // 只在标题使用粗体
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Info button with tooltip
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
                                
                                Text("Files will be saved in selected format after each transcription. Auto Copy sends the text directly to your clipboard for quick pasting.")
                                    .font(.footnote) // 使用统一的footnote字体
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .frame(width: 280)
                        }
                    }
                    
                    // File Format Selection
                    VStack(alignment: .leading, spacing: 8) { // 使用8pt的标题/副标题间距
                        Text("File Format")
                            .font(.subheadline) // 使用统一的subheadline字体
                            .foregroundColor(.white)
                        
                        Picker("", selection: $selectedTranscriptionFormat) {
                            ForEach(formats, id: \.self) { format in
                                Text(format.uppercased()).tag(format)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .onChange(of: selectedTranscriptionFormat) { newValue in
                            if !isInitializing && newValue != settings.transcriptionFormat {
                                settings.transcriptionFormat = newValue
                            }
                        }
                        .focusable(false)
                        
                        Text("Choose your export format")
                            .font(.footnote) // 使用统一的footnote字体
                            .foregroundColor(.secondary)
                            .padding(.top, 2)
                            .padding(.bottom, 4)
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
                
                // 添加Dictation快捷键设置
                VStack(alignment: .leading, spacing: 8) {
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
                    
                    // 快捷键设置
                    if settings.enableDictationShortcut {
                        Text("Shortcut Key Combination")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.top, 8)
                        
                        HStack {
                            TextField("e.g. option+t", text: $settings.dictationShortcutKeyCombo)
                                .font(.system(size: 14))
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(maxWidth: .infinity)
                            
                            Button("Apply") {
                                // 通过发送通知触发快捷键更新
                                NotificationCenter.default.post(
                                    name: NSNotification.Name("dictationShortcutSettingsChanged"),
                                    object: nil
                                )
                            }
                            .font(.system(size: 13))
                            .buttonStyle(GreenButtonStyle())
                        }
                        
                        Text("Format examples: option+t, cmd+shift+d, ctrl+space")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                }
                .glassCard()
                
                Spacer()
            }
            .padding(.top, 24)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .scrollContentBackground(.hidden)
    }
    
    // Smart Swaps Tab View
    private var smartSwapsTabView: some View {
        ScrollView {
            VStack(spacing: 24) { // 保持24pt的部分间距
                // Smart Swaps
                VStack(alignment: .leading, spacing: 8) { // 使用8pt的标题/副标题间距
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
                
                Spacer()
            }
            .padding(.top, 24)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .scrollContentBackground(.hidden)
    }
    
    // Support Tab View
    private var supportTabView: some View {
        VStack(spacing: 24) { // 保持24pt的部分间距
            // About & Support Card
            VStack(alignment: .leading, spacing: 8) { // 使用8pt的标题/副标题间距
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
            .padding(.bottom, 20)
        }
        .padding(.top, 40)
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
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
} 