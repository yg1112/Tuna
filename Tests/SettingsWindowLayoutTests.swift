import XCTest
@testable import Tuna

final class SettingsWindowLayoutTests: XCTestCase {
    func testDefaultLayoutIsLean() {
        let window = TunaSettingsWindow()
        XCTAssertEqual(window.sidebarWidth, 120)
        
        // 显示窗口并等待自动调整高度
        window.show()
        
        // 等待窗口自动调整尺寸完成
        let expectation = XCTestExpectation(description: "Wait for window adjustment")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let frame = window.windowController?.window?.frame {
                XCTAssertLessThanOrEqual(frame.height, 700)
                expectation.fulfill()
            } else {
                XCTFail("Window frame not available")
            }
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testAudioTabFitsWithoutScroll() {
        let window = TunaSettingsWindow()
        
        // 显示音频标签页
        window.show(tab: .audio)
        
        // 等待窗口自动调整尺寸完成
        let expectation = XCTestExpectation(description: "Wait for audio tab adjustment")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let contentView = window.windowController?.window?.contentView,
               let frame = window.windowController?.window?.frame {
                let contentHeight = contentView.fittingSize.height
                XCTAssertLessThanOrEqual(contentHeight, frame.height)
                expectation.fulfill()
            } else {
                XCTFail("Window or content view not available")
            }
        }
        wait(for: [expectation], timeout: 1.0)
    }
} 