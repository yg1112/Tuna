import XCTest
import SwiftUI
@testable import Tuna

class SettingsLaunchTests: XCTestCase {
    
    func testSettingsOpensNewView() throws {
        let app = try TunaTestHarness.launch()
        app.menuBar.tunaIcon.click()
        app.menuBar.settings.click()
        XCTAssert(app.windows["Tuna Settings"].staticTexts["Shortcut (PRO)"].exists)
    }
    
}

// Helper class for launching and testing Tuna app
class TunaTestHarness {
    static func launch() throws -> XCUIApplication {
        let app = XCUIApplication()
        app.launch()
        
        // 等待状态栏图标加载
        let timeout = 5.0
        let expectation = XCTestExpectation(description: "Wait for status bar item to appear")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
            expectation.fulfill()
        }
        
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout + 1.0)
        if result != .completed {
            XCTFail("等待状态栏图标超时")
            throw NSError(domain: "TunaTests", code: 1, userInfo: [NSLocalizedDescriptionKey: "等待状态栏图标超时"])
        }
        
        return app
    }
}

// 扩展XCUIApplication以便访问菜单栏元素
extension XCUIApplication {
    var menuBar: MenuBarElements {
        return MenuBarElements(app: self)
    }
}

// 定义菜单栏元素访问器
class MenuBarElements {
    let app: XCUIApplication
    
    init(app: XCUIApplication) {
        self.app = app
    }
    
    var tunaIcon: XCUIElement {
        return app.statusItems["Tuna Audio Controls"].firstMatch
    }
    
    var settings: XCUIElement {
        return app.buttons["偏好设置"].firstMatch
    }
} 