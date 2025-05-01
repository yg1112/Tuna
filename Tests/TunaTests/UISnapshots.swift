import AppKit
import SnapshotTesting
import SwiftUI
@testable import TunaApp
import TunaAudio
import TunaCore
import TunaUI
import ViewInspector
import XCTest

final class UISnapshots: XCTestCase {
    override func setUp() {
        super.setUp()
        // Create snapshots directory if it doesn't exist
        let fileURL = URL(fileURLWithPath: #file)
        let snapshotsDir = fileURL.deletingLastPathComponent()
            .appendingPathComponent("__Snapshots__")
        try? FileManager.default.createDirectory(
            at: snapshotsDir,
            withIntermediateDirectories: true
        )
    }

    // 辅助函数 - 将SwiftUI视图封装为NSView用于快照测试
    func makeNSView(from view: some View, width: CGFloat, height: CGFloat) -> NSView {
        let hostingView = NSHostingView(rootView: view)
        hostingView.frame = NSRect(x: 0, y: 0, width: width, height: height)
        return hostingView
    }

    // 菜单栏视图快照
    func test_MenuBarView() throws {
        let audioManager = AudioManager.shared
        let settings = TunaSettings.shared
        let router = TabRouter.shared

        let view = TunaMenuBarView(
            audioManager: audioManager,
            settings: settings,
            statsStore: StatsStore.shared,
            isOutputHovered: false,
            isInputHovered: false,
            cardWidth: 300
        )
        .environmentObject(router)

        assertSnapshot(
            of: NSHostingController(rootView: view),
            as: .image(size: .init(width: 400, height: 450)),
            record: ProcessInfo.processInfo.environment["SNAPSHOT_RECORD"] == "1"
        )
    }

    // 语音转写视图快照
    func test_TunaDictationView() throws {
        let view = TunaDictationView(animationsDisabled: true)
            .transaction { $0.disablesAnimations = true }
            .environment(\.colorScheme, .dark)

        assertSnapshot(
            of: NSHostingController(rootView: view),
            as: .image(size: .init(width: 400, height: 400)),
            record: ProcessInfo.processInfo.environment["SNAPSHOT_RECORD"] == "1"
        )
    }

    // 快速语音转写视图快照
    func test_QuickDictationView() throws {
        // 创建固定时间的NowProvider
        let staticNowProvider = StaticNowProvider(TestConstants.previewDate)

        // 创建测试专用DictationManager
        let testDictationManager = DictationManager.createForTesting(nowProvider: staticNowProvider)
        testDictationManager.reset() // 确保状态重置

        // 创建使用测试依赖的QuickDictationView
        let view = QuickDictationView(
            dictationManager: testDictationManager,
            animationsDisabled: true
        )
        .transaction { $0.disablesAnimations = true }
        .environment(\.colorScheme, .dark) // 使用固定的颜色方案以避免系统设置差异

        assertSnapshot(
            of: NSHostingController(rootView: view),
            as: .image(size: .init(width: 500, height: 300)),
            record: ProcessInfo.processInfo.environment["SNAPSHOT_RECORD"] == "1"
        )
    }

    // 关于卡片视图快照
    func test_AboutCardView() throws {
        let view = AboutCardView()
        assertSnapshot(
            of: NSHostingController(rootView: view),
            as: .image(size: .init(width: 780, height: 700)),
            record: ProcessInfo.processInfo.environment["SNAPSHOT_RECORD"] == "1"
        )
    }

    // 设置视图快照
    func test_TunaSettingsView() throws {
        let view = TunaSettingsView()
        assertSnapshot(
            of: NSHostingController(rootView: view),
            as: .image(size: .init(width: 600, height: 600)),
            record: ProcessInfo.processInfo.environment["SNAPSHOT_RECORD"] == "1"
        )
    }

    // 快捷键文本框组件快照
    func test_ShortcutTextField() throws {
        let view = ShortcutTextField(keyCombo: .constant("⌘+X"))
            .frame(width: 200, height: 50)
            .background(Color.gray.opacity(0.2))

        assertSnapshot(
            of: NSHostingController(rootView: view),
            as: .image(size: .init(width: 220, height: 70)),
            record: ProcessInfo.processInfo.environment["SNAPSHOT_RECORD"] == "1"
        )
    }

    // 双向滑块组件快照
    func test_BidirectionalSlider() throws {
        let view = BidirectionalSlider(value: .constant(0))
            .frame(width: 250, height: 60)
            .background(Color.gray.opacity(0.2))

        assertSnapshot(
            of: NSHostingController(rootView: view),
            as: .image(size: .init(width: 270, height: 80)),
            record: ProcessInfo.processInfo.environment["SNAPSHOT_RECORD"] == "1"
        )
    }

    // GlassCard修饰符快照（需要创建一个使用该修饰符的视图）
    func test_GlassCard() throws {
        let view = Text("Glass Card Example")
            .padding()
            .background(
                VisualEffectView(material: .popover, blendingMode: .behindWindow)
                    .cornerRadius(12)
            )
            .frame(width: 200, height: 100)

        assertSnapshot(
            of: NSHostingController(rootView: view),
            as: .image(size: .init(width: 220, height: 120)),
            record: ProcessInfo.processInfo.environment["SNAPSHOT_RECORD"] == "1"
        )
    }

    // ModernToggle样式快照
    func test_ModernToggleStyle() throws {
        let view = Toggle("Test Toggle", isOn: .constant(true))
            .toggleStyle(ModernToggleStyle())
            .frame(width: 200, height: 40)
            .background(Color.gray.opacity(0.2))
            .environment(\.colorScheme, .dark)

        assertSnapshot(
            of: NSHostingController(rootView: view),
            as: .image(size: .init(width: 220, height: 60)),
            record: ProcessInfo.processInfo.environment["SNAPSHOT_RECORD"] == "1"
        )
    }
}
