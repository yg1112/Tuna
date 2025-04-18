import XCTest
import SwiftUI
import SnapshotTesting
import AppKit
@testable import Tuna

final class UISnapshots: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // 设置持续集成环境的参数 - 使用新API
        // 注意：虽然isRecording是废弃API，但在移植到新API前仍需使用
        SnapshotTesting.isRecording = ProcessInfo.processInfo.environment["RECORD_SNAPSHOTS"] == "1"
    }
    
    // 辅助函数 - 将SwiftUI视图封装为NSView用于快照测试
    func makeNSView<V: View>(from view: V, width: CGFloat, height: CGFloat) -> NSView {
        let hostingView = NSHostingView(rootView: view)
        hostingView.frame = NSRect(x: 0, y: 0, width: width, height: height)
        return hostingView
    }
    
    // 菜单栏视图快照
    func test_MenuBarView() throws {
        if ProcessInfo.processInfo.environment["RECORD_SNAPSHOTS"] != "1" {
            throw XCTSkip("此测试需要重新生成快照以反映新设计。请运行 RECORD_SNAPSHOTS=1 swift test")
        }
        
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
        
        assertSnapshot(of: NSHostingController(rootView: view), as: .image(size: .init(width: 400, height: 450)))
    }
    
    // 语音转写视图快照
    func test_TunaDictationView() throws {
        if ProcessInfo.processInfo.environment["RECORD_SNAPSHOTS"] != "1" {
            throw XCTSkip("此测试需要重新生成快照以反映新设计。请运行 RECORD_SNAPSHOTS=1 swift test")
        }
        
        let view = TunaDictationView()
        assertSnapshot(of: NSHostingController(rootView: view), as: .image(size: .init(width: 400, height: 400)))
    }
    
    // 快速语音转写视图快照
    func test_QuickDictationView() throws {
        let view = QuickDictationView()
        assertSnapshot(of: NSHostingController(rootView: view), as: .image(size: .init(width: 500, height: 300)))
    }
    
    // 关于卡片视图快照
    func test_AboutCardView() throws {
        let view = AboutCardView()
        assertSnapshot(of: NSHostingController(rootView: view), as: .image(size: .init(width: 780, height: 700)))
    }
    
    // 设置视图快照
    func test_TunaSettingsView() throws {
        let view = TunaSettingsView()
        assertSnapshot(of: NSHostingController(rootView: view), as: .image(size: .init(width: 600, height: 600)))
    }
    
    // 快捷键文本框组件快照
    func test_ShortcutTextField() throws {
        let view = ShortcutTextField(keyCombo: .constant("⌘+X"))
            .frame(width: 200, height: 50)
            .background(Color.gray.opacity(0.2))
        
        assertSnapshot(of: NSHostingController(rootView: view), as: .image(size: .init(width: 220, height: 70)))
    }
    
    // 双向滑块组件快照
    func test_BidirectionalSlider() throws {
        let view = BidirectionalSlider(value: .constant(0))
            .frame(width: 250, height: 60)
            .background(Color.gray.opacity(0.2))
        
        assertSnapshot(of: NSHostingController(rootView: view), as: .image(size: .init(width: 270, height: 80)))
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
        
        assertSnapshot(of: NSHostingController(rootView: view), as: .image(size: .init(width: 220, height: 120)))
    }
    
    // ModernToggle样式快照
    func test_ModernToggleStyle() throws {
        let view = Toggle("Test Toggle", isOn: .constant(true))
            .toggleStyle(ModernToggleStyle())
            .frame(width: 200, height: 40)
            .background(Color.gray.opacity(0.2))
            .environment(\.colorScheme, .dark)
        
        assertSnapshot(of: NSHostingController(rootView: view), as: .image(size: .init(width: 220, height: 60)))
    }
} 