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
        
        // 使用TabRouter.switchTo切换标签
        TabRouter.switchToTab(.whispen)
        print("🔍 [DEBUG] 已调用TabRouter.switchToTab(.whispen)")
        
        // 找到当前 popover 里的 MenuBarView
        if let window = AppDelegate.shared?.popover.contentViewController?.view.window,
           let host = window.contentView?.subviews.first(where: { $0 is NSHostingView<MenuBarView> })
                as? NSHostingView<MenuBarView> {

            print("🔍 [DEBUG] 找到了MenuBarView实例，检查当前tab是: \(host.rootView.router.currentTab.rawValue)")
            print("🔍 [DEBUG] 该实例的router ID: \(ObjectIdentifier(host.rootView.router))")
            Logger(subsystem:"ai.tuna",category:"Shortcut").notice("[DIRECT] 找到了MenuBarView实例，当前tab是: \(host.rootView.router.currentTab.rawValue)")
            
            // 确保路由状态正确后，启动录音
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                print("🔍 [DEBUG] 延时0.3秒后启动录音")
                Logger(subsystem:"ai.tuna",category:"Shortcut").notice("延时0.3秒后启动录音")
                DictationManager.shared.startRecording()
            }
        } else {
            print("⚠️ [WARNING] 找不到MenuBarView实例，已通过TabRouter.switchTo切换")
            Logger(subsystem:"ai.tuna",category:"Shortcut").warning("[DIRECT] 找不到MenuBarView实例，已通过TabRouter.switchTo切换")
            
            // 即使找不到MenuBarView实例，也尝试启动录音
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                print("🔍 [DEBUG] 找不到实例，延时0.5秒后启动录音")
                Logger(subsystem:"ai.tuna",category:"Shortcut").notice("找不到实例，延时0.5秒后启动录音")
                DictationManager.shared.startRecording()
            }
        }
    }
}

// 标准Tuna界面，使用现代的布局和组件
struct MenuBarView: View {
    @ObservedObject var audioManager: AudioManager
    @ObservedObject var settings: TunaSettings
    @StateObject var router = TabRouter.shared
    @StateObject var dictationManager = DictationManager.shared
    @StateObject var statsStore = StatsStore.shared
    
    @State private var outputButtonHovered = false
    @State private var inputButtonHovered = false
    @State private var statusAppeared = false
    @State private var showVolumeControls = true
    @State private var isPinned = false
    @State private var isExpanded = true
    @State private var debugMessage: String = "" // 添加调试消息状态
    
    // 添加共享的卡片宽度常量
    let cardWidth: CGFloat = 300
    
    private let logger = Logger(subsystem: "ai.tuna", category: "UI")
    
    var body: some View {
        TunaMenuBarView(
            audioManager: audioManager,
            settings: settings,
            statsStore: statsStore,
            isOutputHovered: outputButtonHovered,
            isInputHovered: inputButtonHovered,
            cardWidth: cardWidth
        )
        .environmentObject(router)
        .environmentObject(dictationManager)
        .onAppear {
            print("[DEBUG] MenuBarView appeared – observer added")
            print("🖼 router id in MenuBarView.onAppear:", ObjectIdentifier(router))
            print("🟡 router.current =", router.current, "router id =", ObjectIdentifier(router))
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
                        // 使用TabRouter.switchTo统一切换标签
                        TabRouter.switchTo(tab)
                        print("switchToTab -> \(tab), router id: \(ObjectIdentifier(self.router))")
                        
                        // 如果切换到dictation选项卡，自动启动录音
                        if tab == "dictation" {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                Logger(subsystem:"ai.tuna",category:"Shortcut").notice("[R] call startRecording() from MenuBarView")
                                self.dictationManager.startRecording()
                                print("🎙 通过MenuBarView启动录音")
                            }
                        }
                    }
                } else {
                    print("❌ [ERROR] MenuBarView 收到切换选项卡通知，但tab参数为nil")
                    Logger(subsystem:"ai.tuna",category:"Shortcut").error("❌ MenuBarView 收到切换选项卡通知，但tab参数为nil")
                }
            }
            
            // 添加dictationDebugMessage通知监听
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("dictationDebugMessage"),
                object: nil,
                queue: .main) { notification in
                if let message = notification.userInfo?["message"] as? String {
                    print("🔍 [DEBUG] MenuBarView 收到dictationDebugMessage通知: \(message)")
                    self.debugMessage = message
                }
            }
        }
        .onDisappear {
            // 移除通知监听
            print("🔍 [DEBUG] MenuBarView.onDisappear - 移除通知监听器")
            NotificationCenter.default.removeObserver(self, name: Notification.Name.switchToTab, object: nil)
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name("dictationDebugMessage"), object: nil)
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
    @EnvironmentObject var router: TabRouter
    @EnvironmentObject var dictationManager: DictationManager
    @ObservedObject var statsStore: StatsStore
    let isOutputHovered: Bool
    let isInputHovered: Bool
    let cardWidth: CGFloat
    
    // 固定尺寸
    private let fixedWidth: CGFloat = 400  // 使用固定宽度400
    // 去除固定高度，改为自适应
    
    @State private var showingAboutWindow = false
    @State private var isPinned = false // 添加固定状态
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            // 1. 顶部区域 - 标题和标签选择
            VStack(spacing: 0) {
                // 标题栏
                HStack {
                    Text("Tuna")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(TunaTheme.textPri)
                    
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
                            .foregroundColor(isPinned ? TunaTheme.textPri : TunaTheme.textSec)
                            .frame(width: 20, height: 20)
                            .background(
                                Circle()
                                    .fill(isPinned ? TunaTheme.accent.opacity(0.15) : Color.clear)
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
                
                // 添加Stats Ribbon
                StatsRibbonView(store: statsStore)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                
                // Tab 切换栏 - 使用新的设计
                HStack(spacing: 0) {
                    // Devices 标签
                    NewTabButton(
                        title: TunaTab.devices.rawValue,
                        isSelected: router.currentTab == .devices,
                        action: { router.currentTab = .devices }
                    )
                    .frame(maxWidth: .infinity)
                    
                    // Whispen 标签
                    NewTabButton(
                        title: TunaTab.whispen.rawValue,
                        isSelected: router.currentTab == .whispen,
                        action: { router.currentTab = .whispen }
                    )
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            
            // 2. 中间内容区域 - 使用GeometryReader动态调整高度的可滚动区域
            GeometryReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        switch router.currentTab {
                        case .devices:
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
                            
                        case .whispen:
                            DictationView()
                                .environmentObject(dictationManager) // 明确注入DictationManager
                                .environmentObject(router) // 确保router被正确传递
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                        }
                        
                        // 添加一个空间占位符，确保所有标签页内容至少占据相同的高度
                        // 这样可以保证底部按钮位置一致
                        Spacer(minLength: 50)
                    }
                    .padding(.bottom, 8)
                }
                .frame(maxHeight: 520) // let it grow, cap at 520pt
                .scrollIndicators(.hidden) // 隐藏所有滚动指示器
            }
            
            Divider() // 添加分隔线，视觉上区分内容区和底部按钮区
                .background(TunaTheme.border)
            
            // 3. 底部按钮栏 - 固定位置
            HStack(spacing: 21) {
                Spacer()
                
                // 退出按钮
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    Image(systemName: "power")
                        .font(.system(size: 16))
                        .foregroundColor(TunaTheme.textSec)
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
                        .foregroundColor(TunaTheme.textSec)
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
                        .foregroundColor(TunaTheme.textSec)
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
        .frame(width: fixedWidth, minHeight: 460) // 只固定宽度，高度自适应，但确保最小高度
        .background(TunaTheme.background)
        .onAppear {
            print("🖼 router id in TunaMenuBarView.onAppear:", ObjectIdentifier(router))
            print("🟡 TunaMenuBarView.body router.current =", router.current, "router id =", ObjectIdentifier(router))
            print("ROUTER-DBG [3]", ObjectIdentifier(router), router.current)
            
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
            
            // 添加AutoSize Popover
            if let hostingView = NSApplication.shared.windows.first?.contentView {
                AppDelegate.shared?.popover.contentSize = hostingView.intrinsicContentSize
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
                        // 使用TabRouter.switchTo统一切换标签
                        TabRouter.switchTo(tab)
                        print("TunaMenuBarView switchToTab -> \(tab), router id: \(ObjectIdentifier(self.router))")
                        
                        // 如果切换到dictation选项卡，自动启动录音
                        if tab == "dictation" {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                Logger(subsystem:"ai.tuna",category:"Shortcut").notice("[R] call startRecording() from TunaMenuBarView")
                                self.dictationManager.startRecording()  // 使用self.dictationManager代替DictationManager.shared
                                print("🎙 尝试通过TunaMenuBarView启动录音")
                            }
                        }
                    }
                } else {
                    print("❌ [ERROR] TunaMenuBarView 收到切换选项卡通知，但tab参数为nil")
                    Logger(subsystem:"ai.tuna",category:"Shortcut").error("❌ TunaMenuBarView 收到切换选项卡通知，但tab参数为nil")
                }
            }
        }
        .onDisappear {
            // 移除通知监听
            print("🔍 [DEBUG] TunaMenuBarView.onDisappear - 移除通知监听器")
            NotificationCenter.default.removeObserver(self, name: Notification.Name.switchToTab, object: nil)
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

// 新的标签按钮组件，符合设计需求
struct NewTabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                Text(title)
                    .font(.system(size: 13))
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .foregroundColor(isSelected ? TunaTheme.textPri : TunaTheme.textSec)
                    .background(isSelected ? TunaTheme.accent.opacity(0.18) : Color.clear)
                
                // 选中指示器
                if isSelected {
                    Capsule()
                        .fill(TunaTheme.accent)
                        .frame(width: 32, height: 2)
                        .offset(y: 4)
                        .transition(.opacity)
                } else {
                    Capsule()
                        .fill(Color.clear)
                        .frame(width: 32, height: 2)
                        .offset(y: 4)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .focusable(false)
    }
}

// Smart Swaps 状态指示器组件
struct SmartSwapsStatusIndicator: View {
    @ObservedObject private var settings = TunaSettings.shared
    
    var body: some View {
        if settings.enableSmartSwitching {
            HStack {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 11))
                    .foregroundColor(TunaTheme.accent)
                
                Text("Smart Device Switching: On")
                    .font(.system(size: 12))
                    .foregroundColor(TunaTheme.textSec)
                
                Spacer()
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 6)
            .background(TunaTheme.panel.opacity(0.5))
            .cornerRadius(4)
        } else {
            EmptyView()
        }
    }
}

// 听写视图
struct DictationView: View {
    @EnvironmentObject var dictationManager: DictationManager
    @State private var showSavePanel = false
    @State private var statusMessage = ""
    
    var body: some View {
        VStack(spacing: 20) {
            // 顶部标题区域 - 现代化设计
            HStack {
                Text("语音转文字")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                if dictationManager.isRecording && !dictationManager.isPaused {
                    // 录音指示器
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                        
                        Text("录音中")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(10)
                }
            }
            
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
            
            // 状态指示区域
            VStack(spacing: 4) {
                // 显示状态或进度文本
                Text(dictationManager.progressMessage.isEmpty ? 
                     (dictationManager.isRecording ? (dictationManager.isPaused ? "Paused" : "Recording...") : "Ready") : 
                     dictationManager.progressMessage)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                
                if dictationManager.isRecording && !dictationManager.isPaused {
                    // 音频可视化效果
                    HStack(spacing: 2) {
                        ForEach(0..<15, id: \.self) { _ in
                            AudioVisualBar()
                        }
                    }
                    .frame(height: 20)
                    .transition(.opacity)
                }
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

// 输出设备卡片 - 更新使用新的主题和卡片样式
struct OutputDeviceCard: View {
    @ObservedObject var audioManager: AudioManager
    @ObservedObject var settings: TunaSettings
    
    @State private var showingDeviceList = false
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题栏
            Text("Output Device")
                .tunaCardHeader()
            
            // 设备选择器
            VStack(alignment: .leading, spacing: 10) {
                // 设备选择按钮
                Button(action: {
                    withAnimation {
                        showingDeviceList.toggle()
                    }
                }) {
                    HStack {
                        if let device = audioManager.selectedOutputDevice {
                            Text(device.name)
                                .tunaCardInfo()
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            Text("No device selected")
                                .tunaCardInfo()
                                .opacity(0.7)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12))
                            .foregroundColor(TunaTheme.textPri)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(isHovered ? TunaTheme.accent.opacity(0.1) : Color.clear)
                    .cornerRadius(6)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                .focusable(false)
                .onHover { hovering in
                    isHovered = hovering
                }
                
                // 设备列表（仅在显示时显示）
                if showingDeviceList {
                    OutputDeviceList(
                        audioManager: audioManager,
                        isShowing: $showingDeviceList
                    )
                }
                
                // 仅当首选项启用且有选定设备时显示音量滑块
                if settings.showVolumeSliders, let device = audioManager.selectedOutputDevice, !device.name.isEmpty {
                    Divider()
                        .background(TunaTheme.border)
                        .padding(.vertical, 6)
                    
                    HStack {
                        // 音量图标
                        Image(systemName: audioManager.outputVolume < 0.1 ? "speaker.slash" : "speaker.wave.2")
                            .font(.system(size: 14))
                            .foregroundColor(TunaTheme.textSec)
                        
                        // 音量滑块 - 使用设备音量而非直接绑定到 audioManager.outputVolume
                        Slider(
                            value: Binding(
                                get: { audioManager.outputVolume },
                                set: { newValue in
                                    if let device = audioManager.selectedOutputDevice {
                                        audioManager.setVolumeForDevice(
                                            device: device,
                                            volume: Float(newValue),
                                            isInput: false
                                        )
                                    }
                                }
                            ),
                            in: 0...1
                        )
                        .accentColor(TunaTheme.accent)
                        
                        // 数值显示
                        Text("\(Int(audioManager.outputVolume * 100))%")
                            .font(.system(size: 12))
                            .foregroundColor(TunaTheme.textSec)
                            .frame(width: 36, alignment: .trailing)
                    }
                }
            }
        }
        .padding(.bottom, 6)
        .tunaCard()
    }
}

// 输出设备列表 - 更新使用新的主题
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
                                .foregroundColor(TunaTheme.textPri)
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            if audioManager.selectedOutputDevice?.uid == device.uid {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12))
                                    .foregroundColor(TunaTheme.accent)
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
        .background(TunaTheme.panel.opacity(0.5))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(TunaTheme.border, lineWidth: 1)
        )
        .transition(.opacity)
    }
}

// 输入设备卡片 - 更新使用新的主题和卡片样式
struct InputDeviceCard: View {
    @ObservedObject var audioManager: AudioManager
    @ObservedObject var settings: TunaSettings
    
    @State private var showingDeviceList = false
    @State private var isHovered = false
    @State private var micLevel: Float = 0.0
    @State private var micLevelTimer: Timer?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题栏
            Text("Input Device")
                .tunaCardHeader()
            
            // 设备选择器
            VStack(alignment: .leading, spacing: 10) {
                // 设备选择按钮
                Button(action: {
                    withAnimation {
                        showingDeviceList.toggle()
                    }
                }) {
                    HStack {
                        if let device = audioManager.selectedInputDevice {
                            Text(device.name)
                                .tunaCardInfo()
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            Text("No device selected")
                                .tunaCardInfo()
                                .opacity(0.7)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12))
                            .foregroundColor(TunaTheme.textPri)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(isHovered ? TunaTheme.accent.opacity(0.1) : Color.clear)
                    .cornerRadius(6)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                .focusable(false)
                .onHover { hovering in
                    isHovered = hovering
                }
                
                // 设备列表（仅在显示时显示）
                if showingDeviceList {
                    InputDeviceList(
                        audioManager: audioManager,
                        isShowing: $showingDeviceList
                    )
                }
                
                // 麦克风电平指示器
                if let _ = audioManager.selectedInputDevice {
                    Divider()
                        .background(TunaTheme.border)
                        .padding(.vertical, 6)
                    
                    HStack {
                        // 麦克风图标
                        Image(systemName: "mic")
                            .font(.system(size: 14))
                            .foregroundColor(TunaTheme.textSec)
                        
                        // 电平指示器
                        MicLevelIndicator(level: micLevel)
                            .frame(height: 8)
                        
                        // 仅当首选项启用时显示音量滑块
                        if settings.showMicrophoneLevelMeter {
                            // 麦克风音量滑块 - 使用设备音量而非直接绑定到 audioManager.inputVolume
                            Slider(
                                value: Binding(
                                    get: { audioManager.inputVolume },
                                    set: { newValue in
                                        if let device = audioManager.selectedInputDevice {
                                            audioManager.setVolumeForDevice(
                                                device: device,
                                                volume: Float(newValue),
                                                isInput: true
                                            )
                                        }
                                    }
                                ),
                                in: 0...1
                            )
                            .accentColor(TunaTheme.accent)
                            
                            // 数值显示
                            Text("\(Int(audioManager.inputVolume * 100))%")
                                .font(.system(size: 12))
                                .foregroundColor(TunaTheme.textSec)
                                .frame(width: 36, alignment: .trailing)
                        }
                    }
                }
            }
        }
        .padding(.bottom, 6)
        .tunaCard()
        .onAppear {
            startMicLevelTimer()
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

// 输入设备列表 - 更新使用新的主题
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
                                .foregroundColor(TunaTheme.textPri)
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            if audioManager.selectedInputDevice?.uid == device.uid {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12))
                                    .foregroundColor(TunaTheme.accent)
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
        .background(TunaTheme.panel.opacity(0.5))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(TunaTheme.border, lineWidth: 1)
        )
        .transition(.opacity)
    }
}

// 麦克风电平指示器 - 更新使用新的主题
struct MicLevelIndicator: View {
    let level: Float
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // 背景
                Rectangle()
                    .fill(TunaTheme.border.opacity(0.5))
                    .cornerRadius(4)
                
                // 电平条
                Rectangle()
                    .fill(TunaTheme.accent)
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

// 空的 StatsView 实现，仅用于向后兼容
struct StatsView: View {
    @ObservedObject var audioManager: AudioManager
    
    var body: some View {
        // 这是一个空实现，仅用于向后兼容
        EmptyView()
    }
}
