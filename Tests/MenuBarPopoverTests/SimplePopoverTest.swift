import XCTest
import AppKit
@testable import Tuna

final class SimplePopoverTest: XCTestCase {
    
    func testButtonWiring() {
        // 创建AppDelegate实例
        let delegate = AppDelegate()
        
        // 初始化statusItem
        delegate.setupStatusItemForTesting()
        
        // 验证button配置
        XCTAssertNotNil(delegate.statusItem, "StatusItem should not be nil")
        XCTAssertNotNil(delegate.statusItem.button, "StatusItem button should not be nil")
        
        // 验证target和action设置
        let button = delegate.statusItem.button
        XCTAssertNotNil(button?.target, "Button target should not be nil")
        XCTAssertEqual(button?.target as? AppDelegate, delegate, "Button target should be the AppDelegate")
        XCTAssertEqual(button?.action, #selector(AppDelegate.togglePopover(_:)), "Button action should be togglePopover:")
    }
} 