import AppKit
@testable import TunaApp
import XCTest

final class MenuBarPopoverTests: XCTestCase {
    var delegate: AppDelegate!

    override func setUp() {
        super.setUp()
        self.delegate = AppDelegate()
        self.delegate.setupStatusItemForTesting()
    }

    override func tearDown() {
        self.delegate = nil
        super.tearDown()
    }

    func testStatusItemButtonWiredUp() throws {
        let button = self.delegate.statusItem.button!
        XCTAssertNotNil(button.target)
        XCTAssertEqual(button.action, #selector(AppDelegate.togglePopover(_:)))
    }

    func testTogglePopoverShowsPopover() throws {
        self.delegate.togglePopover(nil) // simulate click
        XCTAssertTrue(self.delegate.popover.isShown, "Popover should be visible after toggle")
        XCTAssertNotNil(
            self.delegate.popover.contentViewController?.view.subviews.first,
            "Popover should have visible content"
        )
    }
}
