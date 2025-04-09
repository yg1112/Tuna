import SwiftUI
import AppKit
// import Views -- 已移至 Tuna 模块

// DictationManager已在自身文件中实现了DictationManagerProtocol，这里不需要重复声明

struct DictationSettingsView: View {
    @ObservedObject private var dictationManager = DictationManager.shared
    @ObservedObject private var tunaSettings = TunaSettings.shared
    @State private var apiKey: String = UserDefaults.standard.string(forKey: "dictationApiKey") ?? ""
    @State private var selectedFormat: String = UserDefaults.standard.string(forKey: "dictationFormat") ?? "txt"
    @State private var outputDirectory: URL? = UserDefaults.standard.url(forKey: "dictationOutputDirectory")
    
    private let formats = ["txt", "srt", "vtt", "json"]
    private let accentColor = Color.green
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Launch at Login 部分
                HStack {
                    Text("Launch at Login")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // 使用CustomToggleStyle确保绿色显示
                    Toggle("", isOn: Binding(
                        get: { tunaSettings.launchAtLogin },
                        set: { tunaSettings.launchAtLogin = $0 }
                    ))
                    .toggleStyle(GreenToggleStyle())
                    .labelsHidden()
                }
                .padding(.top, 10)
                
                Divider()
                
                // OpenAI API Key
                VStack(alignment: .leading, spacing: 8) {
                    Text("OpenAI API Key")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.primary)
                    
                    SecureField("API Key", text: $apiKey)
                        .font(.system(size: 14))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: apiKey) { newValue in
                            dictationManager.setApiKey(newValue)
                        }
                }
                
                // Output Format
                VStack(alignment: .leading, spacing: 8) {
                    Text("Output Format")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Picker("", selection: $selectedFormat) {
                        ForEach(formats, id: \.self) { format in
                            Text(format.uppercased()).tag(format)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: selectedFormat) { newValue in
                        dictationManager.setOutputFormat(newValue)
                    }
                }
                
                // Output Directory
                VStack(alignment: .leading, spacing: 8) {
                    Text("Output Directory")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.primary)
                    
                    HStack {
                        Text(outputDirectory?.lastPathComponent ?? "Desktop")
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
                            .focusable(false) // 禁用焦点
                        
                        Button("Select") {
                            selectOutputDirectory()
                        }
                        .font(.system(size: 13))
                        .buttonStyle(GreenButtonStyle())
                        .focusable(false) // 禁用Select按钮的焦点
                    }
                }
                
                Spacer()
            }
            .padding(20)
            .accentColor(accentColor) // 设置整个视图的强调色
        }
    }
    
    private func selectOutputDirectory() {
        // 在打开面板前发送文件选择开始通知，确保设置窗口不会关闭
        NotificationCenter.default.post(name: NSNotification.Name("fileSelectionStarted"), object: nil)
        
        // 创建并配置NSOpenPanel
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.prompt = "Select Folder"
        panel.title = "Select Output Directory for Transcriptions"
        
        // 防止窗口被自动关闭
        panel.level = .modalPanel
        panel.isReleasedWhenClosed = false
        
        // 确保文件选择器保持活动状态，不会意外关闭
        panel.treatsFilePackagesAsDirectories = false
        
        // 查找当前活动的窗口
        var parentWindow: NSWindow?
        for window in NSApplication.shared.windows {
            if window.isVisible && !window.isMiniaturized {
                print("\u{001B}[36m[DEBUG]\u{001B}[0m 找到窗口: \(window.title), isKey: \(window.isKeyWindow)")
                if window.isKeyWindow {
                    parentWindow = window
                    break
                }
            }
        }
        
        // 如果没有找到键盘焦点窗口，则使用主窗口或第一个可见窗口
        if parentWindow == nil {
            parentWindow = NSApplication.shared.keyWindow ?? NSApplication.shared.mainWindow
            if parentWindow == nil {
                // 如果仍然找不到，使用第一个可见窗口
                for window in NSApplication.shared.windows {
                    if window.isVisible && !window.isMiniaturized {
                        parentWindow = window
                        break
                    }
                }
            }
            print("\u{001B}[36m[DEBUG]\u{001B}[0m 使用备选窗口: \(parentWindow?.title ?? "nil")")
        }
        
        // 使用父窗口显示选择器，确保设置窗口在选择器显示期间保持活动状态
        if let window = parentWindow {
            print("\u{001B}[32m[UI]\u{001B}[0m 使用父窗口显示文件选择器: \(window.title)")
            
            // 保存当前窗口级别，稍后恢复
            let originalLevel = window.level
            
            // 提高窗口级别，确保在文件选择过程中保持可见
            window.level = .popUpMenu
            window.orderFrontRegardless()
            
            // 使用beginSheetModal确保文件选择器作为附加面板显示，而不会关闭主窗口
            NSApp.activate(ignoringOtherApps: true) // 确保应用程序处于活动状态
            window.makeKeyAndOrderFront(nil) // 确保窗口可见
            
            panel.beginSheetModal(for: window) { response in
                print("\u{001B}[32m[UI]\u{001B}[0m 文件选择器响应: \(response == .OK ? "确定" : "取消")")
                
                // 恢复原来的窗口级别
                window.level = originalLevel
                
                // 选择完成后，确保父窗口重新获得焦点
                NSApp.activate(ignoringOtherApps: true)
                window.makeKeyAndOrderFront(nil)
                
                if response == .OK, let url = panel.url {
                    DispatchQueue.main.async {
                        self.outputDirectory = url
                        self.dictationManager.setOutputDirectory(url)
                        print("\u{001B}[32m[设置]\u{001B}[0m 已选择语音识别输出目录: \(url.path)")
                        
                        // 确保设置窗口在选择完成后仍然保持打开状态
                        window.makeKeyAndOrderFront(nil)
                        
                        // 延迟一段时间再发送结束通知，确保窗口有足够时间显示
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            NotificationCenter.default.post(name: NSNotification.Name("fileSelectionEnded"), object: nil)
                        }
                    }
                } else {
                    // 取消选择时也发送结束通知
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        NotificationCenter.default.post(name: NSNotification.Name("fileSelectionEnded"), object: nil)
                    }
                }
            }
        } else {
            // 如果找不到任何合适的窗口，则使用标准模态显示
            print("\u{001B}[33m[警告]\u{001B}[0m 未找到父窗口，使用runModal显示文件选择器")
            
            let response = panel.runModal()
            
            print("\u{001B}[32m[UI]\u{001B}[0m 文件选择器响应: \(response == .OK ? "确定" : "取消")")
            if response == .OK, let url = panel.url {
                DispatchQueue.main.async {
                    self.outputDirectory = url
                    self.dictationManager.setOutputDirectory(url)
                    print("\u{001B}[32m[设置]\u{001B}[0m 已选择语音识别输出目录: \(url.path)")
                    
                    // 确保设置窗口在模态操作后重新获得焦点
                    if let window = NSApplication.shared.keyWindow {
                        window.makeKeyAndOrderFront(nil)
                    }
                }
            }
            
            // 文件选择结束后发送通知
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NotificationCenter.default.post(name: NSNotification.Name("fileSelectionEnded"), object: nil)
            }
        }
    }
}

// 自定义绿色开关样式
struct GreenToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            
            ZStack {
                Capsule()
                    .fill(configuration.isOn ? Color(nsColor: .controlAccentColor) : Color.gray.opacity(0.3))
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
struct GreenButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(nsColor: .controlAccentColor))
            .foregroundColor(.white)
            .cornerRadius(6)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .focusable(false) // 禁用焦点环
    }
} 