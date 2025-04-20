import AppKit
import os.log
import SwiftUI

class MainWindowManager: NSObject {
    static let shared = MainWindowManager()

    private var windowController: NSWindowController?
    private let logger = Logger(subsystem: "ai.tuna", category: "MainWindowManager")

    // 获取主窗口
    var mainWindow: NSWindow? {
        windowController?.window
    }

    // 显示主窗口
    func show() {
        // 如果窗口已存在，则显示它
        if let window = mainWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            logger.notice("显示现有主窗口")
            return
        }

        // 否则创建新窗口
        createAndShowMainWindow()
    }

    // 创建并显示主窗口
    private func createAndShowMainWindow() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 500),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Tuna"
        window.center()
        window.isReleasedWhenClosed = false

        // 创建主视图并注入TabRouter和DictationManager
        let mainView = MainWindowView()
            .environmentObject(TabRouter.shared)
            .environmentObject(DictationManager.shared)

        // 创建一个NSHostingController来托管SwiftUI视图
        let hostingController = NSHostingController(rootView: mainView)

        // 设置窗口的内容视图
        window.contentView = hostingController.view

        // 创建窗口控制器并显示窗口
        windowController = NSWindowController(window: window)
        windowController?.showWindow(nil)

        // 确保应用处于活动状态并窗口显示在前
        NSApp.activate(ignoringOtherApps: true)

        logger.notice("已创建并显示主窗口")
    }
}

// 主窗口视图
struct MainWindowView: View {
    @EnvironmentObject var router: TabRouter // 使用TabRouter而不是本地状态
    @EnvironmentObject var dictationManager: DictationManager
    @StateObject private var audioManager = AudioManager.shared
    @StateObject private var settings = TunaSettings.shared

    var body: some View {
        VStack(spacing: 0) {
            // 顶部标签栏
            HStack(spacing: 8) {
                Spacer()

                Button(action: {
                    router.current = "devices"
                }) {
                    VStack {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 16))
                        Text("Devices")
                            .font(.system(size: 12))
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(router.current == "devices" ? Color.blue.opacity(0.6) : Color.clear)
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                .foregroundColor(router.current == "devices" ? .white : .secondary)

                Button(action: {
                    router.current = "dictation"
                }) {
                    VStack {
                        Image(systemName: "waveform")
                            .font(.system(size: 16))
                        Text("Whispen")
                            .font(.system(size: 12))
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        router.current == "dictation" ? Color.blue.opacity(0.6) : Color
                            .clear
                    )
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                .foregroundColor(router.current == "dictation" ? .white : .secondary)

                Button(action: {
                    router.current = "settings"
                }) {
                    VStack {
                        Image(systemName: "gear")
                            .font(.system(size: 16))
                        Text("Settings")
                            .font(.system(size: 12))
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        router.current == "settings" ? Color.blue.opacity(0.6) : Color
                            .clear
                    )
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                .foregroundColor(router.current == "settings" ? .white : .secondary)

                Spacer()
            }
            .padding(.top, 16)
            .padding(.bottom, 8)

            // 内容区域
            ZStack {
                // 设备管理标签
                if router.current == "devices" {
                    ScrollView {
                        VStack(spacing: 16) {
                            // 输出设备卡片
                            OutputDeviceCard(audioManager: audioManager, settings: settings)

                            // 输入设备卡片
                            InputDeviceCard(audioManager: audioManager, settings: settings)
                        }
                        .padding()
                    }
                }

                // 听写标签
                if router.current == "dictation" {
                    DictationView()
                        .environmentObject(dictationManager)
                }

                // 设置标签
                if router.current == "settings" {
                    TunaSettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Spacer()
        }
        .padding()
        .frame(minWidth: 380, minHeight: 450)
        .onAppear {
            // 记录窗口出现
            Logger(subsystem: "ai.tuna", category: "MainWindow")
                .notice("MainWindow appeared with router.current == \(router.current)")
        }
    }
}
