import XCTest
import SwiftUI
import SnapshotTesting
import AppKit
@testable import Tuna

final class UISnapshots: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // 设置持续集成环境的参数
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
        let audioManager = AudioManager.shared
        let settings = TunaSettings.shared
        let router = TabRouter.shared
        
        let view = MenuBarView(audioManager: audioManager, settings: settings)
            .environmentObject(router)
            .frame(width: 400, height: 439)
        
        let nsView = makeNSView(from: view, width: 400, height: 439)
        assertSnapshot(of: nsView, as: .image)
    }
    
    // 语音转写视图快照
    func test_TunaDictationView() throws {
        let view = TunaDictationView()
            .frame(width: 400, height: 500)
        
        let nsView = makeNSView(from: view, width: 400, height: 500)
        assertSnapshot(of: nsView, as: .image)
    }
    
    // 快速语音转写视图快照
    func test_QuickDictationView() throws {
        let view = QuickDictationView()
            .frame(width: 400, height: 250)
        
        let nsView = makeNSView(from: view, width: 400, height: 250)
        assertSnapshot(of: nsView, as: .image)
    }
    
    // 关于卡片视图快照
    func test_AboutCardView() throws {
        let view = AboutCardView()
            .frame(width: 780, height: 750)
        
        let nsView = makeNSView(from: view, width: 780, height: 750)
        assertSnapshot(of: nsView, as: .image)
    }
    
    // 设置视图快照
    func test_TunaSettingsView() throws {
        let view = TunaSettingsView()
            .frame(width: 600, height: 500)
        
        let nsView = makeNSView(from: view, width: 600, height: 500)
        assertSnapshot(of: nsView, as: .image)
    }
    
    // 双向滑块组件快照
    func test_BidirectionalSlider() throws {
        let view = BidirectionalSlider(value: .constant(0.0))
            .frame(width: 200, height: 50)
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
        
        let nsView = makeNSView(from: view, width: 250, height: 100)
        assertSnapshot(of: nsView, as: .image)
    }
    
    // 快捷键文本框组件快照
    func test_ShortcutTextField() throws {
        let view = ShortcutTextField(value: .constant("cmd+shift+space"), onCommit: {})
            .frame(width: 150, height: 30)
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
        
        let nsView = makeNSView(from: view, width: 200, height: 80)
        assertSnapshot(of: nsView, as: .image)
    }
    
    // GlassCard修饰符快照（需要创建一个使用该修饰符的视图）
    func test_GlassCard() throws {
        let view = Text("GlassCard Example")
            .padding()
            .glassCard()
            .frame(width: 200, height: 100)
        
        let nsView = makeNSView(from: view, width: 200, height: 100)
        assertSnapshot(of: nsView, as: .image)
    }
    
    // ModernToggle样式快照
    func test_ModernToggleStyle() throws {
        let view = Toggle("Modern Toggle", isOn: .constant(true))
            .toggleStyle(ModernToggleStyle())
            .frame(width: 200, height: 30)
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
        
        let nsView = makeNSView(from: view, width: 250, height: 80)
        assertSnapshot(of: nsView, as: .image)
    }
} 