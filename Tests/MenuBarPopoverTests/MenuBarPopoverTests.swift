import AppKit
@testable import TunaApp
import XCTest

final class MenuBarPopoverTests: XCTestCase {
    func testStatusItemButtonWiredUp() throws {
        let delegate = AppDelegate()
        delegate.setupStatusItemForTesting() // implement below
        let button = delegate.statusItem.button!
        XCTAssertNotNil(button.target)
        XCTAssertEqual(button.action, #selector(AppDelegate.togglePopover(_:)))
    }

    func testTogglePopoverShowsPopover() throws {
        let delegate = AppDelegate()
        delegate.setupStatusItemForTesting()
        delegate.togglePopover(nil) // simulate click
        XCTAssertTrue(delegate.popover.isShown, "Popover should be visible after toggle")
        XCTAssertNotNil(
            delegate.popover.contentViewController?.view.subviews.first,
            "Popover should have visible content"
        )
    }
}
