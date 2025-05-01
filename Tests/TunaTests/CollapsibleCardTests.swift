import SwiftUI
@testable import TunaApp
import TunaUI
import ViewInspector
import XCTest

final class CollapsibleCardTests: XCTestCase {
    func testCollapsibleCardToggle() throws {
        // Create a binding for the expanded state
        var isExpanded = false
        let binding = Binding(
            get: { isExpanded },
            set: { isExpanded = $0 }
        )

        // Create a collapsible card
        let card = CollapsibleCard(
            title: "Test Card",
            isExpanded: binding,
            collapsible: true // Explicitly set to collapsible
        ) {
            Text("Content")
                .accessibilityIdentifier("TestContent")
        }

        // Verify initial state is collapsed
        XCTAssertFalse(isExpanded, "Card should start collapsed")

        // Simulate button click to expand
        try card.inspect().find(button: "Test Card").tap()
        XCTAssertTrue(isExpanded, "Card should expand when clicked")

        // Simulate button click to collapse
        try card.inspect().find(button: "Test Card").tap()
        XCTAssertFalse(isExpanded, "Card should collapse when clicked again")
    }

    func testNonCollapsibleCard() throws {
        // Create a binding for the expanded state
        var isExpanded = false // Start with false to verify it gets forced to true
        let binding = Binding(
            get: { isExpanded },
            set: { isExpanded = $0 }
        )

        // Create a non-collapsible card
        let card = CollapsibleCard(
            title: "Test Card",
            isExpanded: binding,
            collapsible: false // Explicitly set to non-collapsible
        ) {
            Text("Content")
                .accessibilityIdentifier("TestContent")
        }

        // Verify content is visible regardless of binding value
        let content = try card.inspect().find(viewWithAccessibilityIdentifier: "TestContent")
        XCTAssertNotNil(content, "Content should always be visible for non-collapsible card")

        // Verify no chevron icon is present
        XCTAssertThrowsError(
            try card.inspect().find(viewWithAccessibilityIdentifier: "TestCardChevron"),
            "Chevron should not be present for non-collapsible card"
        )

        // Try to collapse by simulating button tap
        let button = try card.inspect().find(button: "Test Card")
        try button.tap()

        // Verify content is still visible after tap
        let contentAfterTap = try card.inspect()
            .find(viewWithAccessibilityIdentifier: "TestContent")
        XCTAssertNotNil(contentAfterTap, "Content should remain visible after button tap")

        // Try to set expanded state to false
        binding.wrappedValue = false

        // Verify content remains visible regardless of binding value
        let contentAfterCollapse = try card.inspect()
            .find(viewWithAccessibilityIdentifier: "TestContent")
        XCTAssertNotNil(
            contentAfterCollapse,
            "Content should remain visible regardless of binding value"
        )
    }

    func testChevronVisibility() throws {
        // Create a binding for the expanded state
        var isExpanded = false
        let binding = Binding(
            get: { isExpanded },
            set: { isExpanded = $0 }
        )

        // Create a collapsible card
        let collapsibleCard = CollapsibleCard(
            title: "Test Card",
            isExpanded: binding,
            collapsible: true
        ) {
            Text("Content")
        }

        // Verify chevron is visible for collapsible card
        let collapsibleView = try collapsibleCard.inspect()
        XCTAssertNoThrow(
            try collapsibleView.find(viewWithAccessibilityIdentifier: "TestCardChevron"),
            "Collapsible card should have a chevron"
        )

        // Create a non-collapsible card
        let nonCollapsibleCard = CollapsibleCard(
            title: "Test Card",
            isExpanded: binding,
            collapsible: false
        ) {
            Text("Content")
        }

        // Verify chevron is not visible for non-collapsible card
        let nonCollapsibleView = try nonCollapsibleCard.inspect()
        XCTAssertThrowsError(
            try nonCollapsibleView.find(viewWithAccessibilityIdentifier: "TestCardChevron"),
            "Non-collapsible card should not have a chevron"
        )
    }
}
