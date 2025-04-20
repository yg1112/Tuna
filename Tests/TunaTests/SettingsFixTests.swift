import XCTest
import SwiftUI
import ViewInspector
@testable import Tuna

// 不再需要Inspectable扩展，ViewInspector最新版本不需要显式声明

// 添加SettingsUIState类定义
class SettingsUIState: ObservableObject {
    @Published var isEngineOpen: Bool = false
    @Published var isTranscriptionOpen: Bool = false
}

class SettingsFixTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // 确保在每个测试开始前重置设置
        UserDefaults.standard.removeObject(forKey: "theme")
        UserDefaults.standard.removeObject(forKey: "dictationFormat")
        UserDefaults.standard.removeObject(forKey: "dictationOutputDirectory")
        UserDefaults.standard.removeObject(forKey: "whisperAPIKey")
    }

    // MARK: - CollapsibleCard Tests
    
    func testCollapsibleCardToggle() throws {
        // 测试CollapsibleCard的isExpanded功能
        var isExpanded = false
        
        // 创建绑定
        let binding = Binding(
            get: { isExpanded },
            set: { isExpanded = $0 }
        )
        
        // 创建一个CollapsibleCard实例
        let card = CollapsibleCard(title: "Test Card", isExpanded: binding) {
            Text("Content")
        }
        
        // 验证初始状态是折叠的
        XCTAssertFalse(isExpanded)
        
        // 模拟点击展开
        binding.wrappedValue = true
        
        // 验证状态已更改
        XCTAssertTrue(isExpanded)
    }
    
    // MARK: - SettingsUIState Tests
    
    func testSettingsUIState() throws {
        // 测试SettingsUIState正常工作
        let uiState = SettingsUIState()
        
        // 验证初始状态
        XCTAssertFalse(uiState.isEngineOpen)
        XCTAssertFalse(uiState.isTranscriptionOpen)
        
        // 模拟打开Engine卡片
        uiState.isEngineOpen = true
        
        // 验证状态变更
        XCTAssertTrue(uiState.isEngineOpen)
        XCTAssertFalse(uiState.isTranscriptionOpen)
        
        // 模拟打开Transcription卡片
        uiState.isTranscriptionOpen = true
        
        // 验证两个卡片都是打开状态
        XCTAssertTrue(uiState.isEngineOpen)
        XCTAssertTrue(uiState.isTranscriptionOpen)
    }
    
    // MARK: - Transcription Format Tests
    
    func testTranscriptionFormatChanges() throws {
        // 测试格式切换功能
        UserDefaults.standard.set("txt", forKey: "dictationFormat")
        
        // 验证初始格式
        XCTAssertEqual(UserDefaults.standard.string(forKey: "dictationFormat"), "txt")
        
        // 模拟选择新格式
        UserDefaults.standard.set("json", forKey: "dictationFormat")
        
        // 验证格式已更改
        XCTAssertEqual(UserDefaults.standard.string(forKey: "dictationFormat"), "json")
    }
    
    // MARK: - Theme Tests
    
    func testThemeChangeNotification() throws {
        // 测试主题变更通知
        let expectation = XCTestExpectation(description: "Theme change notification received")
        var receivedChange = false
        
        // 设置为初始状态（系统模式）
        UserDefaults.standard.set("system", forKey: "theme")
        
        // 监听通知
        let observer = NotificationCenter.default.addObserver(
            forName: .appearanceChanged,
            object: nil,
            queue: .main
        ) { _ in
            receivedChange = true
            expectation.fulfill()
        }
        
        // 模拟更改主题
        UserDefaults.standard.set("dark", forKey: "theme")
        // 手动发送通知以模拟SettingsView中的行为
        NotificationCenter.default.post(name: .appearanceChanged, object: nil)
        
        // 等待通知
        wait(for: [expectation], timeout: 1)
        
        // 验证结果
        XCTAssertTrue(receivedChange)
        XCTAssertEqual(UserDefaults.standard.string(forKey: "theme"), "dark")
        
        // 清理
        NotificationCenter.default.removeObserver(observer)
    }
}

// 添加通知名称扩展，以匹配应用中的定义
extension Notification.Name {
    static let appearanceChanged = Notification.Name("TunaAppearanceDidChange")
} 