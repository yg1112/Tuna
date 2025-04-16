import SwiftUI
import AppKit
import CoreAudio
import CoreAudio.AudioHardware
import os

// 存储 About 窗口的全局变量
var aboutWindowReference: NSWindowController?

// 添加静态方法用于激活dictation标签页
extension MenuBarView {
    static func activateDictationTab() {
        print("🔍 [DEBUG] MenuBarView.activateDictationTab() 被调用")
        Logger(subsystem:"ai.tuna",category:"Shortcut").notice("[DIRECT] activateDictationTab 被调用")
        
        // 找到当前 popover 里的 MenuBarView
        if let window = AppDelegate.shared?.popover.contentViewController?.view.window,
           let host = window.contentView?.subviews.first(where: { $0 is NSHostingView<MenuBarView> })
                as? NSHostingView<MenuBarView> {

            print("🔍 [DEBUG] 找到了MenuBarView实例，当前tab是: \(host.rootView.currentTab)")
            Logger(subsystem:"ai.tuna",category:"Shortcut").notice("[DIRECT] 找到了MenuBarView实例，当前tab是: \(host.rootView.currentTab)")
            
            // 直接设置为dictation标签
            host.rootView.currentTab = "dictation"
            
            print("🔍 [DEBUG] MenuBarView.currentTab已设置为: \(host.rootView.currentTab)")
            Logger(subsystem:"ai.tuna",category:"Shortcut").notice("[DIRECT] MenuBarView.currentTab已设置为: \(host.rootView.currentTab)")
        } else {
            print("⚠️ [WARNING] 找不到MenuBarView实例，回退到通知机制")
            Logger(subsystem:"ai.tuna",category:"Shortcut").warning("[DIRECT] 找不到MenuBarView实例，回退到通知机制")
            
            // 回退到通知机制
            NotificationCenter.default.post(
                name: Notification.Name.switchToTab,
                object: nil,
                userInfo: ["tab": "dictation"]
            )
        }
        
        // 给UI一些时间来切换，然后开始录音 (可选，因为DictationManager.toggle()已在handleDictationShortcutPressed中调用)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            Logger(subsystem:"ai.tuna",category:"Shortcut").notice("[R] call startRecording() from static method")
            // DictationManager.shared.startRecording() // 由于toggle()已经在KeyboardShortcutManager中调用，这里不需要再调用
        }
    }
}

// 标准Tuna界面，使用现代的布局和组件
struct MenuBarView: View {
    @ObservedObject var audioManager: AudioManager
    @ObservedObject var settings: TunaSettings
    @State private var outputButtonHovered = false
    @State private var inputButtonHovered = false
    @State private var statusAppeared = false
    @State private var showVolumeControls = true
    @State private var isPinned = false
    @State private var currentTab = "devices" // 默认显示设备选项卡
    @State private var isExpanded = true
    let cardWidth: CGFloat = 300
    
    private let logger = Logger(subsystem: "ai.tuna", category: "UI")
    
    var body: some View {
        TunaMenuBarView(
            audioManager: audioManager,
            settings: settings,
            isOutputHovered: outputButtonHovered,
            isInputHovered: inputButtonHovered,
            cardWidth: cardWidth
        )
        .onAppear {
            print("[DEBUG] MenuBarView appeared – observer added")
            Logger(subsystem:"ai.tuna",category:"Shortcut").notice("MenuBarView appeared – observer added")
            // 确保Smart Swaps在UI加载后被应用
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                let smartSwapsEnabled = UserDefaults.standard.bool(forKey: "enableSmartDeviceSwapping")
                if smartSwapsEnabled {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("smartSwapsStatusChanged"),
                        object: nil, 
                        userInfo: ["enabled": true]
                    )
                }
            }
            
            // 检查系统设置
            showVolumeControls = settings.showVolumeSliders
            
            // 检查固定状态
            isPinned = UserDefaults.standard.bool(forKey: "popoverPinned")
            
            // 添加调试信息
            print("🔍 [DEBUG] MenuBarView.onAppear - 开始监听switchToTab通知")
            Logger(subsystem:"ai.tuna",category:"Shortcut").notice("🔍 MenuBarView.onAppear - 开始监听switchToTab通知")
            
            // 添加切换选项卡通知监听
            NotificationCenter.default.addObserver(
                forName: Notification.Name.switchToTab,
                object: nil,
                queue: .main) { notification in
                if let tab = notification.userInfo?["tab"] as? String {
                    print("🔍 [DEBUG] MenuBarView 收到切换选项卡通知: \(tab)")
                    Logger(subsystem:"ai.tuna",category:"Shortcut").notice("🔍 MenuBarView 收到切换选项卡通知: \(tab)")
                    
                    withAnimation {
                        self.currentTab = tab
                        print("switchToTab -> \(tab)")
                        Logger(subsystem:"ai.tuna",category:"Shortcut").notice("[T] switchToTab -> \(tab)")
                        
                        // 如果切换到dictation选项卡，自动启动录音
                        if tab == "dictation" {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                Logger(subsystem:"ai.tuna",category:"Shortcut").notice("[R] call startRecording() from MenuBarView")
                                DictationManager.shared.startRecording()
                            }
                        }
                    }
                } else {
                    print("❌ [ERROR] MenuBarView 收到切换选项卡通知，但tab参数为nil")
                    Logger(subsystem:"ai.tuna",category:"Shortcut").error("❌ MenuBarView 收到切换选项卡通知，但tab参数为nil")
                }
            }
        }
        .onDisappear {
            // 移除通知监听
            NotificationCenter.default.removeObserver(self)
        }
    }
}

// 设备偏好行组件
struct DevicePreferenceRow: View {
    let title: String
    let iconName: String
    let deviceName: String
    let onSelect: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onSelect) {
        HStack {
                // 图标
                Image(systemName: iconName)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 20)
                
                // 标题
                Text(title)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                // 设备名称
                Text(deviceName)
                            .font(.system(size: 13))
                            .foregroundColor(.white)
                            .lineLimit(1)
                
                // 下拉图标
                Image(systemName: "chevron.down")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
            .background(isHovered ? Color.white.opacity(0.1) : Color.clear)
            .cornerRadius(6)
                }
                .buttonStyle(PlainButtonStyle())
        .focusable(false)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// 主菜单栏视图
struct TunaMenuBarView: View {
    @ObservedObject var audioManager: AudioManager
    @ObservedObject var settings: TunaSettings
    let isOutputHovered: Bool
    let isInputHovered: Bool
    let cardWidth: CGFloat
    
    // 固定尺寸
    private let fixedWidth: CGFloat = 400  // 使用固定宽度400
    private let fixedHeight: CGFloat = 439  // 从462缩小5%到439
    
    @State private var currentTab = "devices" // "devices", "dictation", "stats"
    @State private var showingAboutWindow = false
    @State private var isPinned = false // 添加固定状态
    
    var body: some View {
        VStack(spacing: 0) {
            // 1. 顶部区域 - 标题和标签选择
            VStack(spacing: 0) {
                // 标题栏
            HStack {
                Text("Tuna")
                        .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
                
                    // 添加固定/取消固定按钮
                    Button(action: {
                        isPinned.toggle()
                        // 保存固定状态到UserDefaults
                        UserDefaults.standard.set(isPinned, forKey: "popoverPinned")
                        // 发送通知到AppDelegate更新popover行为
                        NotificationCenter.default.post(
                            name: NSNotification.Name("togglePinned"),
                            object: nil,
                            userInfo: ["isPinned": isPinned]
                        )
                    }) {
                        Image(systemName: isPinned ? "pin.fill" : "pin")
                            .font(.system(size: 12))
                            .foregroundColor(isPinned ? .white : .white.opacity(0.7))
                            .frame(width: 20, height: 20)
        .background(
                Circle()
                                    .fill(isPinned ? Color.white.opacity(0.15) : Color.clear)
                                    .frame(width: 24, height: 24)
                            )
                            .animation(.easeInOut(duration: 0.2), value: isPinned)
        }
        .buttonStyle(PlainButtonStyle())
        .focusable(false)
                    .help(isPinned ? "取消固定 (点击其他位置会关闭窗口)" : "固定 (点击其他位置不会关闭窗口)")
            }
            .padding(.horizontal, 16)
        .padding(.vertical, 8)
                
                // Tab 切换栏
                HStack(spacing: 0) {
                Spacer()
                
                    TabButton(
                        title: "Devices",
                        iconName: "speaker.wave.2.fill",
                        isSelected: currentTab == "devices"
                    ) {
                        currentTab = "devices"
                    }
                    
                    TabButton(
                        title: "Whispen",
                        iconName: "waveform",
                        isSelected: currentTab == "dictation"
                    ) {
                        currentTab = "dictation"
                    }
                    
                    TabButton(
                        title: "Stats",
                        iconName: "chart.bar.fill",
                        isSelected: currentTab == "stats"
                    ) {
                        currentTab = "stats"
                }
            }
            .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            
            // 2. 中间内容区域 - 固定高度的可滚动区域
            ScrollView {
                VStack(spacing: 0) {
                    switch currentTab {
                    case "devices":
                        // 设备卡片区域
                        VStack(spacing: 12) {
                            // 添加Smart Swaps状态指示器
                            SmartSwapsStatusIndicator()
                                .padding(.bottom, 4)
                            
                            OutputDeviceCard(
                    audioManager: audioManager,
                    settings: settings
                )
                            
                            InputDeviceCard(
                audioManager: audioManager,
                settings: settings
            )
            }
            .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        
                    case "dictation":
                        DictationView()
                .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        
                    case "stats":
                        StatsView(audioManager: audioManager)
            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        
                    default:
                        EmptyView()
                    }
                    
                    // 添加一个空间占位符，确保所有标签页内容至少占据相同的高度
                    // 这样可以保证底部按钮位置一致
                    Spacer(minLength: 50)
                }
                .padding(.bottom, 8)
            }
            .frame(height: 319) // 从336缩小5%到319
            .scrollIndicators(.hidden) // 隐藏所有滚动指示器
            .scrollDisabled(currentTab == "devices") // 当在Devices标签页时禁用滚动
            
            Divider() // 添加分隔线，视觉上区分内容区和底部按钮区
                .background(Color.white.opacity(0.1))
            
            // 3. 底部按钮栏 - 固定位置
            HStack(spacing: 21) {
                Spacer()
                
                // 退出按钮
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    Image(systemName: "power")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(width: 20, height: 20) // 固定按钮大小
                }
                .buttonStyle(PlainButtonStyle())
                .focusable(false)
                .help("退出应用")
                
                // 关于按钮
                    Button(action: {
                    showAboutWindow()
                }) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(width: 20, height: 20) // 固定按钮大小
                    }
                    .buttonStyle(PlainButtonStyle())
                    .focusable(false)
                .help("关于")
                        
                // 设置按钮
                Button(action: {
                    showSettingsWindow()
                }) {
                    Image(systemName: "gear")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(width: 20, height: 20) // 固定按钮大小
                }
                .buttonStyle(PlainButtonStyle())
                .focusable(false)
                .help("偏好设置")
        }
        .padding(.horizontal, 16)
            .padding(.vertical, 10) // 轻微减少垂直内边距
            .frame(width: fixedWidth) // 固定按钮栏宽度
        }
        .frame(width: fixedWidth, height: fixedHeight)
        .background(VisualEffectView(material: .menu, blendingMode: .behindWindow))
        .onAppear {
            // 当视图出现时，恢复固定状态
            let savedPinState = UserDefaults.standard.bool(forKey: "popoverPinned")
            if savedPinState {
                self.isPinned = savedPinState
                // 通知AppDelegate恢复固定状态
                NotificationCenter.default.post(
                    name: NSNotification.Name("togglePinned"),
                    object: nil,
                    userInfo: ["isPinned": savedPinState]
                )
                print("\u{001B}[36m[UI]\u{001B}[0m Restored pin status: \(savedPinState)")
            }
            
            // 添加调试信息
            print("🔍 [DEBUG] TunaMenuBarView.onAppear - 开始监听switchToTab通知")
            Logger(subsystem:"ai.tuna",category:"Shortcut").notice("🔍 TunaMenuBarView.onAppear - 开始监听switchToTab通知")
            
            // 添加通知监听
            NotificationCenter.default.addObserver(
                forName: Notification.Name.switchToTab,
                object: nil,
                queue: .main) { notification in
                if let tab = notification.userInfo?["tab"] as? String {
                    print("🔍 [DEBUG] TunaMenuBarView 收到切换选项卡通知: \(tab)")
                    Logger(subsystem:"ai.tuna",category:"Shortcut").notice("🔍 TunaMenuBarView 收到切换选项卡通知: \(tab)")
                    
                    withAnimation {
                        self.currentTab = tab
                        print("TunaMenuBarView switchToTab -> \(tab)")
                        Logger(subsystem:"ai.tuna",category:"Shortcut").notice("TunaMenuBarView switchToTab -> \(tab)")
                        
                        // 如果切换到dictation选项卡，自动启动录音
                        if tab == "dictation" {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                Logger(subsystem:"ai.tuna",category:"Shortcut").notice("[R] call startRecording() from TunaMenuBarView")
                                DictationManager.shared.startRecording()
                            }
                        }
                    }
                } else {
                    print("❌ [ERROR] TunaMenuBarView 收到切换选项卡通知，但tab参数为nil")
                    Logger(subsystem:"ai.tuna",category:"Shortcut").error("❌ TunaMenuBarView 收到切换选项卡通知，但tab参数为nil")
                }
            }
        }
    }
    
    // 显示关于窗口
    private func showAboutWindow() {
        if aboutWindowReference == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 780, height: 750),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = "About Tuna"
            window.center()
            window.isReleasedWhenClosed = false
            
            let aboutView = AboutCardView()
            let hostingView = NSHostingView(rootView: aboutView)
            window.contentView = hostingView
            
            aboutWindowReference = NSWindowController(window: window)
        }
        
        NSApp.activate(ignoringOtherApps: true)
        aboutWindowReference?.showWindow(nil)
        aboutWindowReference?.window?.makeKeyAndOrderFront(nil)
    }
    
    // 显示设置窗口
    private func showSettingsWindow() {
        NotificationCenter.default.post(name: NSNotification.Name("showSettings"), object: nil)
    }
}

// Tab 按钮组件
struct TabButton: View {
    let title: String
    let iconName: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
            Image(systemName: iconName)
                    .font(.system(size: 13))
                Text(title)
                    .font(.system(size: 13))
            }
            .foregroundColor(isSelected ? .white : .white.opacity(0.6))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isSelected ? Color.white.opacity(0.1) : Color.clear)
                                    .cornerRadius(4)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .focusable(false)
    }
}

// 听写视图
struct DictationView: View {
    @EnvironmentObject var dictationManager: DictationManager
    @State private var showSavePanel = false
    @State private var statusMessage = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("语音转文字")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            
            // 如果有状态消息，显示错误提示
            if !statusMessage.isEmpty {
                Text(statusMessage)
                    .font(.system(size: 14))
                    .foregroundColor(.orange)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(6)
            }
            
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.black.opacity(0.3))
                    .frame(height: 40)
                
                if dictationManager.isRecording {
                    // 录音状态可视化
                    HStack(spacing: 3) {
                        ForEach(0..<10, id: \.self) { _ in
                            AudioVisualBar()
                        }
                    }
                    .transition(.opacity)
                } else {
                    Text(dictationManager.isRecording ? "正在录音..." : "按下按钮开始录音")
                        .foregroundColor(.white.opacity(0.8))
                        .font(.system(size: 14))
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: dictationManager.isRecording)
            
            // 文本输出框和清除按钮
            ZStack(alignment: .topTrailing) {
                    ScrollView {
                        Text(dictationManager.transcribedText.isEmpty ? "Transcription will appear here..." : dictationManager.transcribedText)
                    .font(.system(size: 14))
                            .foregroundColor(dictationManager.transcribedText.isEmpty ? .gray : .white)
                    .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                .frame(height: 170)
                    .background(Color.black.opacity(0.2))
                .cornerRadius(8)
                    .overlay(
                    RoundedRectangle(cornerRadius: 8)
                            .stroke(
                            dictationManager.isRecording && !dictationManager.isPaused ? 
                                Color.white.opacity(0.8) : // 录音时显示常亮的珍珠白色边框
                                Color.white.opacity(dictationManager.breathingAnimation ? 0.7 : 0.3), // 非录音时保持呼吸动画
                            lineWidth: dictationManager.isRecording && !dictationManager.isPaused ? 2.0 : (dictationManager.breathingAnimation ? 2.0 : 0.5)
                        )
                        .scaleEffect(dictationManager.isRecording && !dictationManager.isPaused ? 1.0 : (dictationManager.breathingAnimation ? 1.025 : 1.0)) // 录音时不需要缩放效果
                )
                
                // 清除按钮
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        dictationManager.transcribedText = ""
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(8)
                }
                .buttonStyle(PlainButtonStyle())
                .focusable(false)
                .opacity(dictationManager.transcribedText.isEmpty ? 0 : 1)
            }
            
            // 调整按钮布局 - 使录制按钮在左侧，复制/导出按钮在右侧
            HStack(spacing: 20) {
                // 录制按钮 - 放在左边
                Button(action: {
                    if dictationManager.isRecording {
                        if dictationManager.isPaused {
                            dictationManager.startRecording()
                            dictationManager.isPaused = false
                        } else {
                            dictationManager.pauseRecording()
                            dictationManager.isPaused = true
                        }
                    } else {
                        dictationManager.startRecording()
                        dictationManager.isRecording = true
                    }
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: dictationManager.isRecording ? (dictationManager.isPaused ? "play.circle" : "pause.circle") : "mic.circle")
                            .font(.system(size: 18))
                        Text(dictationManager.isRecording ? (dictationManager.isPaused ? "Continue" : "Pause") : "Record")
                            .font(.system(size: 13))
                    }
                    .frame(height: 24)
                    .padding(.horizontal, 10)
                    .background(dictationManager.isRecording && !dictationManager.isPaused ? Color.red.opacity(0.8) : Color.blue.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
                .help(dictationManager.isRecording ? (dictationManager.isPaused ? "Continue recording" : "Pause recording") : "Start recording")
                
                // 停止按钮 - 只在录音过程中显示
                if dictationManager.isRecording {
                    Button(action: {
                        dictationManager.stopRecording()
                        dictationManager.isRecording = false
                        dictationManager.isPaused = false
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "stop.circle")
                                .font(.system(size: 18))
                            Text("Stop")
                                .font(.system(size: 13))
                        }
                        .frame(height: 24)
                        .padding(.horizontal, 10)
                        .background(Color.gray.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Stop recording")
                    .transition(.scale)
                }
                
                // 右侧按钮组 - 复制和导出
                Spacer()
                
                // 复制按钮
                Button(action: {
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(dictationManager.transcribedText, forType: .string)
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 16))
                        Text("Copy")
                            .font(.system(size: 13))
                    }
                    .frame(height: 24)
                    .padding(.horizontal, 8)
                    .background(Color.blue.opacity(0.6))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(dictationManager.transcribedText.isEmpty)
                .opacity(dictationManager.transcribedText.isEmpty ? 0.5 : 1)
                .help("Copy text to clipboard")
                
                // 保存按钮
                Button(action: {
                    saveTranscription()
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 16))
                        Text("Save")
                            .font(.system(size: 13))
                    }
                    .frame(height: 24)
                    .padding(.horizontal, 8)
                    .background(Color.green.opacity(0.6))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(dictationManager.transcribedText.isEmpty)
                .opacity(dictationManager.transcribedText.isEmpty ? 0.5 : 1)
                .help("Save transcription to a file")
            }
            
            // 显示状态或进度文本
            Text(dictationManager.progressMessage.isEmpty ? 
                     (dictationManager.isRecording ? (dictationManager.isPaused ? "Paused" : "Recording...") : "Ready") : 
                     dictationManager.progressMessage)
                .font(.system(size: 12))
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 4)
            
            if dictationManager.isRecording && !dictationManager.isPaused {
                // 音频可视化效果
                HStack(spacing: 2) {
                    ForEach(0..<15, id: \.self) { _ in
                        AudioVisualBar()
                    }
                }
                .frame(height: 20)
                .padding(.top, -8)
                .transition(.opacity)
            }
        }
        .padding()
        .onAppear {
            // 启动呼吸动画
            dictationManager.breathingAnimation = true
            
            // 注册录音失败回调
            dictationManager.onStartFailure = {
                self.statusMessage = "⚠️ 无法启动听写，请确认已授权麦克风权限并检查系统设置。"
            }
        }
        .onDisappear {
            // 清除回调
            dictationManager.onStartFailure = nil
            // 清除状态消息
            self.statusMessage = ""
        }
    }
    
    // 保存转录到文件
    private func saveTranscription() {
        // 创建保存面板
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.text]
        savePanel.canCreateDirectories = true
        savePanel.isExtensionHidden = false
        savePanel.title = "Save Transcription"
        savePanel.message = "Choose a location to save the transcription"
        savePanel.nameFieldStringValue = "Transcription-\(Date().formatted(.dateTime.year().month().day().hour().minute()))"
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                do {
                    try dictationManager.transcribedText.write(to: url, atomically: true, encoding: .utf8)
                } catch {
                    print("Failed to save transcription: \(error.localizedDescription)")
                }
            }
        }
    }
}

// 音频可视化条
struct AudioVisualBar: View {
    @State private var animation = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(Color.white.opacity(0.7))
            .frame(width: 3, height: animation ? 20 : 5)
            .animation(
                Animation.easeInOut(duration: 0.2)
                    .repeatForever()
                    .delay(Double.random(in: 0...0.3)),
                value: animation
            )
            .onAppear {
                animation = true
            }
    }
}

// 统计视图
struct StatsView: View {
    @ObservedObject var audioManager: AudioManager
    
    var body: some View {
            VStack(spacing: 12) {
            // 设备统计
            ColorfulCardView(
                title: "设备统计",
                iconName: "chart.bar.fill",
                color: Color.purple
            ) {
                VStack(alignment: .leading, spacing: 8) {
                    StatRow(title: "输出设备数量", value: "\(audioManager.outputDevices.count)")
                    StatRow(title: "输入设备数量", value: "\(audioManager.inputDevices.count)")
                }
            }
        }
    }
}

// 统计行组件
struct StatRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
                Text(title)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.8))
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
        }
    }
}

// 输出设备卡片
struct OutputDeviceCard: View {
    @ObservedObject var audioManager: AudioManager
    @ObservedObject var settings: TunaSettings
    @State private var showingDeviceMenu = false
    @State private var volume: Double = 0 // 保留用于初始化
    
    var body: some View {
        ColorfulCardView(
            title: "AUDIO OUTPUT",
            iconName: "speaker.wave.2.fill",
            color: NewUI3Colors.output
        ) {
            VStack(spacing: 6) { // 减小间距
                // 设备选择按钮
                Button(action: {
                    withAnimation {
                        showingDeviceMenu.toggle()
                    }
                }) {
                    HStack {
                        Text(audioManager.selectedOutputDevice?.name ?? "无输出设备")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(8)
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                .focusable(false)
                
                // 平衡锁定按钮
                if let device = audioManager.selectedOutputDevice, device.supportsBalanceControl {
                    Button(action: {
                        audioManager.isOutputBalanceLocked.toggle()
                    }) {
                        HStack {
                            Text(audioManager.isOutputBalanceLocked ? "平衡已锁定" : "锁定平衡")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.7))
                            
                            Image(systemName: audioManager.isOutputBalanceLocked ? "lock.fill" : "lock.open")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.1))
                        .cornerRadius(6)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .focusable(false)
                }
                
                // 设备列表 - 放在最后，以确保滑块始终可见
                if showingDeviceMenu {
                    OutputDeviceList(
                        audioManager: audioManager,
                        isShowing: $showingDeviceMenu
                    )
                    .frame(height: 120) // 限制设备列表高度
                    .transition(.opacity)
                }
                
                // 音量滑块 - 始终显示，不受条件控制
                HStack {
                    Slider(
                        value: Binding(
                            get: { 
                                // 使用Double(audioManager.outputVolume * 100 - 50)转换到我们的滑块范围
                                Double(audioManager.outputVolume * 100 - 50)
                            },
                            set: { newValue in
                                if let device = audioManager.selectedOutputDevice {
                                    audioManager.setVolumeForDevice(
                                        device: device,
                                        volume: Float((newValue + 50) / 100),
                                        isInput: false
                                    )
                                    print("🟣 [UI] 输出滑块绑定更新，当前值 = \(audioManager.outputVolume)")
                                }
                            }
                        ), 
                        in: -50...50
                    )
                    .accentColor(NewUI3Colors.output)
                }
                .padding(.vertical, 3) // 减小内边距
            }
            .padding(8) // 减小内边距
        }
        .onAppear {
            // 初始化时不再需要设置volume状态变量
            // 我们直接使用audioManager.outputVolume的绑定
            print("🟣 [UI] 输出设备卡片出现，当前音量 = \(audioManager.outputVolume)")
        }
    }
}

// 输出设备列表
struct OutputDeviceList: View {
    @ObservedObject var audioManager: AudioManager
    @Binding var isShowing: Bool
    
    var body: some View {
        ScrollView {
            VStack(spacing: 1) {
                ForEach(audioManager.outputDevices) { device in
                    Button(action: {
                        audioManager.setDefaultOutputDevice(device)
                        isShowing = false
                    }) {
                        HStack {
                            Text(device.name)
                                .font(.system(size: 13))
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            if audioManager.selectedOutputDevice?.uid == device.uid {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12))
                                    .foregroundColor(NewUI3Colors.output)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .focusable(false)
                }
            }
        }
        .frame(maxHeight: 150)
        .background(Color.black.opacity(0.2))
        .cornerRadius(8)
        .transition(.opacity)
    }
}

// 输入设备卡片
struct InputDeviceCard: View {
    @ObservedObject var audioManager: AudioManager
    @ObservedObject var settings: TunaSettings
    @State private var showingDeviceMenu = false
    @State private var volume: Double = 0 // 保留用于初始化
    @State private var micLevel: Float = 0.0
    @State private var micLevelTimer: Timer? // 改为@State属性
    
    var body: some View {
        ColorfulCardView(
            title: "AUDIO INPUT",
            iconName: "mic.fill",
            color: NewUI3Colors.input
        ) {
            VStack(spacing: 6) { // 减小间距
                // 设备选择按钮
                Button(action: {
                    withAnimation {
                        showingDeviceMenu.toggle()
                    }
                }) {
                    HStack {
                        Text(audioManager.selectedInputDevice?.name ?? "无输入设备")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(8)
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                .focusable(false)
                
                // 麦克风电平指示器
                if settings.showMicrophoneLevelMeter {
                    MicLevelIndicator(level: micLevel)
                        .frame(height: 6) // 减小高度
                }
                
                // 设备列表 - 放在最后，以确保滑块始终可见
                if showingDeviceMenu {
                    InputDeviceList(
                        audioManager: audioManager,
                        isShowing: $showingDeviceMenu
                    )
                    .frame(height: 120) // 限制设备列表高度
                    .transition(.opacity)
                }
                
                // 音量滑块 - 始终显示，不受条件控制
                HStack {
                    Slider(
                        value: Binding(
                            get: { 
                                // 使用Double(audioManager.inputVolume * 100 - 50)转换到我们的滑块范围
                                Double(audioManager.inputVolume * 100 - 50)
                            },
                            set: { newValue in
                                if let device = audioManager.selectedInputDevice {
                                    audioManager.setVolumeForDevice(
                                        device: device,
                                        volume: Float((newValue + 50) / 100),
                                        isInput: true
                                    )
                                    print("🟣 [UI] 输入滑块绑定更新，当前值 = \(audioManager.inputVolume)")
                                }
                            }
                        ), 
                        in: -50...50
                    )
                    .accentColor(NewUI3Colors.input)
                }
                .padding(.vertical, 3) // 减小内边距
            }
            .padding(8) // 减小内边距
        }
        .onAppear {
            startMicLevelTimer()
            // 初始化时不再需要设置volume状态变量
            // 我们直接使用audioManager.inputVolume的绑定
            print("🟣 [UI] 输入设备卡片出现，当前音量 = \(audioManager.inputVolume)")
        }
        .onDisappear {
            stopMicLevelTimer()
        }
    }
    
    private func startMicLevelTimer() {
        micLevelTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            withAnimation(.linear(duration: 0.1)) {
                if audioManager.selectedInputDevice != nil {
                    micLevel = Float.random(in: 0.05...0.3)
                } else {
                    micLevel = 0.0
                }
            }
        }
    }
    
    private func stopMicLevelTimer() {
        micLevelTimer?.invalidate()
        micLevelTimer = nil
    }
}

// 输入设备列表
struct InputDeviceList: View {
    @ObservedObject var audioManager: AudioManager
    @Binding var isShowing: Bool
    
    var body: some View {
        ScrollView {
            VStack(spacing: 1) {
                ForEach(audioManager.inputDevices) { device in
                    Button(action: {
                        audioManager.setDefaultInputDevice(device)
                        isShowing = false
                    }) {
                        HStack {
                            Text(device.name)
                                .font(.system(size: 13))
                    .foregroundColor(.white)
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            if audioManager.selectedInputDevice?.uid == device.uid {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12))
                                    .foregroundColor(NewUI3Colors.input)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .focusable(false)
                }
            }
        }
        .frame(maxHeight: 150)
        .background(Color.black.opacity(0.2))
        .cornerRadius(8)
        .transition(.opacity)
    }
}

// 麦克风电平指示器
struct MicLevelIndicator: View {
    let level: Float
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // 背景
                Rectangle()
                    .fill(Color.black.opacity(0.2))
                    .cornerRadius(4)
                
                // 电平条
                Rectangle()
                    .fill(NewUI3Colors.input)
                    .frame(width: geometry.size.width * CGFloat(level))
                    .cornerRadius(4)
            }
        }
        .frame(height: 8)
        .animation(.linear(duration: 0.1), value: level)
    }
}

// 颜色主题
enum NewUI3Colors {
    static let output = Color(red: 0.2, green: 0.6, blue: 1.0)
    static let input = Color(red: 1.0, green: 0.4, blue: 0.4)
}

// 彩色卡片视图
struct ColorfulCardView<Content: View>: View {
    let title: String
    let iconName: String
    let color: Color
    let content: () -> Content
    
    init(title: String, iconName: String, color: Color, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.iconName = iconName
        self.color = color
        self.content = content
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // 标题栏
            HStack {
                Image(systemName: iconName)
                    .font(.system(size: 12))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(color)
                
                Spacer()
            }
            
            // 内容区域
            content()
            }
        .padding(10)
            .background(Color.black.opacity(0.2))
        .cornerRadius(12)
    }
}

// 视觉效果视图
struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

struct DeviceCard: View {
    let device: AudioDevice
    let isInput: Bool
    @ObservedObject var audioManager: AudioManager
    
    @State private var volume: Double = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 设备信息
                            HStack {
                Image(systemName: isInput ? "mic" : "speaker.wave.2")
                    .font(.system(size: 16))
                        .foregroundColor(.white)
                
                Text(device.name)
                    .font(.system(size: 14))
                        .foregroundColor(.white)
                    .lineLimit(1)
                        
                        Spacer()
            }
            
            // 音量控制
            BidirectionalSlider(value: $volume)
                .frame(height: 60)
                .onChange(of: volume) { newValue in
                    audioManager.setVolumeForDevice(
                        device: device,
                        volume: Float((newValue + 50) / 100), // 将 -50~50 转换为 0~1
                        isInput: isInput
                    )
                }
        }
        .padding()
        .background(Color(red: 0.15, green: 0.15, blue: 0.15))
        .cornerRadius(12)
        .onAppear {
            // 初始化音量值
            let currentVolume = device.volume
            volume = Double(currentVolume * 100 - 50) // 将 0~1 转换为 -50~50
        }
    }
}

// Smart Swaps状态指示器
struct SmartSwapsStatusIndicator: View {
    // 移除@ObservedObject，因为我们直接通过通知获取状态
    @State private var isSmartSwapsEnabled = false
    
    // 定义通知名称常量
    private static let smartSwapsStatusChangedNotification = NSNotification.Name("smartSwapsStatusChanged")
    
    var body: some View {
        HStack(spacing: 6) {
            // 状态指示点
            Circle()
                .fill(isSmartSwapsEnabled ? Color.green : Color.gray)
                .frame(width: 8, height: 8)
            
            // 状态文本
            Text(isSmartSwapsEnabled ? "Smart Swaps is active" : "Smart Swaps is not active")
                .font(.system(size: 12))
                .foregroundColor(isSmartSwapsEnabled ? .white : .white.opacity(0.6))
            
            Spacer()
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        // 添加点击操作，允许用户通过点击状态指示器来开启/关闭Smart Swaps
        .contentShape(Rectangle())
        .onTapGesture {
            toggleSmartSwaps()
        }
        .onAppear {
            // 立即读取当前状态
            isSmartSwapsEnabled = UserDefaults.standard.bool(forKey: "enableSmartDeviceSwapping")
            
            // 设置通知观察者
            NotificationCenter.default.addObserver(
                forName: SmartSwapsStatusIndicator.smartSwapsStatusChangedNotification,
                object: nil,
                queue: .main
            ) { notification in
                if let enabled = notification.userInfo?["enabled"] as? Bool {
                    self.isSmartSwapsEnabled = enabled
                }
            }
        }
        .onDisappear {
            // 移除观察者，避免内存泄漏
            NotificationCenter.default.removeObserver(
                self,
                name: SmartSwapsStatusIndicator.smartSwapsStatusChangedNotification,
                object: nil
            )
        }
    }
    
    // 切换Smart Swaps状态的方法
    private func toggleSmartSwaps() {
        // 切换状态
        isSmartSwapsEnabled.toggle()
        
        // 保存到UserDefaults
        UserDefaults.standard.set(isSmartSwapsEnabled, forKey: "enableSmartDeviceSwapping")
        
        // 发送通知更新其他UI组件
        NotificationCenter.default.post(
            name: SmartSwapsStatusIndicator.smartSwapsStatusChangedNotification,
            object: nil,
            userInfo: ["enabled": isSmartSwapsEnabled]
        )
        
        // 应用设置
        if isSmartSwapsEnabled {
            DispatchQueue.main.async {
                AudioManager.shared.forceApplySmartDeviceSwapping()
            }
        }
    }
}
