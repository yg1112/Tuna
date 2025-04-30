import SwiftUI
@testable import TunaApp
import TunaUI
import XCTest

final class DictationSettingsViewTests: XCTestCase {
    func testCollapsibleCardInitialization() throws {
        let isExpanded = false
        let binding = Binding(
            get: { isExpanded },
            set: { _ in }
        )

        let card = CollapsibleCard(title: "Test Card", isExpanded: binding) {
            Text("Content")
        }

        // Basic assertions
        XCTAssertEqual(card.title, "Test Card")
        XCTAssertFalse(binding.wrappedValue)
    }
}
