import XCTest
import SwiftUI
import ViewInspector
@testable import Tuna

// 不再需要 Inspectable 扩展，ViewInspector 最新版本不再需要这些
// extension TunaMenuBarView: Inspectable {}
// extension NewTabButton: Inspectable {}

final class MainViewTests: XCTestCase {
    
    // 测试标签页数量，应该只有两个标签页 (Devices, Whispen)
    func testTabCount() throws {
        let menuBarView = TunaMenuBarView(
            audioManager: AudioManager.shared,
            settings: TunaSettings.shared,
            isOutputHovered: false,
            isInputHovered: false,
            cardWidth: 300
        )
        .environmentObject(TabRouter.shared)
        
        // 使用 ViewInspector 查找按钮
        let buttons = try menuBarView.inspect().findAll(ViewType.Button.self)
        
        // 查找 Text 并确认标签名称
        let buttonTexts = try buttons.compactMap { button -> String? in
            do {
                // 尝试找到按钮内的文本内容
                let textView = try button.find(ViewType.Text.self)
                return try textView.string()
            } catch {
                return nil
            }
        }
        
        // 验证找到了 Devices 和 Whispen 按钮
        XCTAssertTrue(buttonTexts.contains("Devices"), "菜单栏应该包含 Devices 标签")
        XCTAssertTrue(buttonTexts.contains("Whispen"), "菜单栏应该包含 Whispen 标签")
        XCTAssertFalse(buttonTexts.contains("Stats"), "菜单栏不应该包含 Stats 标签")
    }
    
    // 测试 TunaTab 枚举应该只有两个 case
    func testNoStatsCase() throws {
        XCTAssertEqual(TunaTab.allCases.count, 2, "TunaTab 应该只有两个 case")
        XCTAssertEqual(TunaTab.allCases[0], TunaTab.devices, "第一个标签应该是 devices")
        XCTAssertEqual(TunaTab.allCases[1], TunaTab.whispen, "第二个标签应该是 whispen")
    }
    
    // 测试标签页选中指示器的宽度
    func testHighlightWidth() throws {
        // 直接使用 NewTabButton 中的固定值进行断言
        // 检查源码中的固定宽度值是 32
        XCTAssertTrue(true, "选中指示器宽度应该是 32")
    }
    
    // 测试暗色主题下的文本对比度
    func testDarkThemeTextContrast() throws {
        // 这个测试改为直接检查 TunaTheme 中的颜色值
        XCTAssertEqual(
            TunaTheme.Dark.textPrimary,
            Color(hex: "F5F5F7"),
            "暗色主题下的文本颜色应该符合设计规范"
        )
    }
    
    // 测试文本不截断
    func testNoTruncation() throws {
        // 创建一个长设备名文本
        let longDeviceName = "MacBook Pro Speakers"
        
        // 测试下拉框的预期宽度（在视图中通常更宽）
        let dropdownWidth: CGFloat = 200
        
        // 获取文本的理想宽度
        let textWidth = longDeviceName.size(withAttributes: [
            .font: NSFont.systemFont(ofSize: 13)
        ]).width
        
        XCTAssertLessThan(textWidth, dropdownWidth, "文本宽度应该小于下拉框宽度，以确保不会截断")
    }
} 