import AppKit
@testable import TunaApp
import XCTest

final class SimplePopoverTest: XCTestCase {
    var delegate: AppDelegate!

    override func setUpWithError() throws {
        try super.setUpWithError()
        // Skip tests if running in CI environment
        if ProcessInfo.processInfo.environment["CI"] != nil {
            throw XCTSkip("Skipping UI tests in CI environment")
        }
        self.delegate = AppDelegate()
        self.delegate.setupStatusItemForTesting()
    }

    override func tearDown() {
        self.delegate = nil
        super.tearDown()
    }

    func testButtonWiring() throws {
        // Skip test if running in CI environment
        try XCTSkipIf(
            ProcessInfo.processInfo.environment["CI"] != nil,
            "Skipping UI test in CI environment"
        )

        // 验证button配置
        XCTAssertNotNil(self.delegate.statusItem, "StatusItem should not be nil")
        XCTAssertNotNil(self.delegate.statusItem.button, "StatusItem button should not be nil")

        // 验证target和action设置
        let button = self.delegate.statusItem.button
        XCTAssertNotNil(button?.target, "Button target should not be nil")
        XCTAssertEqual(
            button?.target as? AppDelegate,
            self.delegate,
            "Button target should be the AppDelegate"
        )
        XCTAssertEqual(
            button?.action,
            #selector(AppDelegate.togglePopover(_:)),
            "Button action should be togglePopover:"
        )
    }
}
