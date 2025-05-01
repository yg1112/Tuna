import AppKit
@testable import TunaApp
import XCTest

final class MenuBarPopoverTests: XCTestCase {
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

    func testStatusItemButtonWiredUp() throws {
        // Skip test if running in CI environment
        try XCTSkipIf(
            ProcessInfo.processInfo.environment["CI"] != nil,
            "Skipping UI test in CI environment"
        )

        let button = self.delegate.statusItem.button!
        XCTAssertNotNil(button.target)
        XCTAssertEqual(button.action, #selector(AppDelegate.togglePopover(_:)))
    }

    func testTogglePopoverShowsPopover() throws {
        // Skip test if running in CI environment
        try XCTSkipIf(
            ProcessInfo.processInfo.environment["CI"] != nil,
            "Skipping UI test in CI environment"
        )

        self.delegate.togglePopover(nil) // simulate click
        XCTAssertTrue(self.delegate.popover.isShown, "Popover should be visible after toggle")
        XCTAssertNotNil(
            self.delegate.popover.contentViewController?.view.subviews.first,
            "Popover should have visible content"
        )
    }
}
