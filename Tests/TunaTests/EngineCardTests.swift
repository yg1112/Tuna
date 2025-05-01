import SwiftUI
@testable import TunaApp
import TunaCore
import TunaUI
import ViewInspector
import XCTest

final class EngineCardTests: XCTestCase {
    override func setUp() {
        super.setUp()
        // Reset settings before each test
        TunaSettings.shared.isEngineOpen = true // Non-collapsible cards are always expanded
    }

    func testEngineCardContent() throws {
        // Create a settings view with preview settings
        let dictationTabView = DictationTabView(settings: TunaSettings.shared)

        // Find the Engine card by its ID
        let engineCard = try dictationTabView.inspect()
            .find(viewWithAccessibilityIdentifier: "EngineCard")

        // Verify the card is expanded and non-collapsible
        XCTAssertTrue(TunaSettings.shared.isEngineOpen, "Engine card should be expanded")

        // Verify content is always visible
        let engineContent = try engineCard.find(viewWithAccessibilityIdentifier: "EngineContent")
        XCTAssertNoThrow(
            try engineContent.find(viewWithAccessibilityIdentifier: "EngineSettings"),
            "Engine settings content should be visible"
        )

        // Verify header is present
        XCTAssertNoThrow(
            try engineCard.find(viewWithAccessibilityIdentifier: "EngineHeader"),
            "Engine header should be visible"
        )

        // Verify no chevron is present for non-collapsible card
        XCTAssertThrowsError(
            try engineCard.find(viewWithAccessibilityIdentifier: "EngineChevron"),
            "Non-collapsible Engine card should not have a chevron"
        )
    }
}
