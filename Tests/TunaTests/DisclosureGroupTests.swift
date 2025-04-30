import SwiftUI
@testable import TunaApp
import TunaCore
import ViewInspector
import XCTest

final class DisclosureGroupTests: XCTestCase {
    override func setUp() {
        super.setUp()
        // Reset settings before each test
        TunaSettings.shared.isEngineOpen = false
        TunaSettings.shared.isTranscriptionOutputOpen = false
    }

    func testEngineDisclosureExpansion() throws {
        // Create a settings view with preview settings
        let settingsView = TunaSettingsView()

        // Get the dictation tab view
        let dictationTab = try settingsView.inspect().find(viewWithId: "dictationTab")

        // Find the Engine card by its ID
        let engineCard = try dictationTab.find(viewWithId: "EngineCard")

        // Initially the card should be collapsed
        XCTAssertFalse(TunaSettings.shared.isEngineOpen)

        // Simulate a tap on the header
        try engineCard.button().tap()

        // The card should now be expanded
        XCTAssertTrue(TunaSettings.shared.isEngineOpen)

        // Tap again to collapse
        try engineCard.button().tap()

        // The card should be collapsed again
        XCTAssertFalse(TunaSettings.shared.isEngineOpen)
    }

    func testTranscriptionOutputDisclosureExpansion() throws {
        // Create a settings view with preview settings
        let settingsView = TunaSettingsView()

        // Get the dictation tab view
        let dictationTab = try settingsView.inspect().find(viewWithId: "dictationTab")

        // Find the Transcription Output card by its ID
        let transcriptionCard = try dictationTab.find(viewWithId: "TranscriptionOutputCard")

        // Initially the card should be collapsed
        XCTAssertFalse(TunaSettings.shared.isTranscriptionOutputOpen)

        // Simulate a tap on the header
        try transcriptionCard.button().tap()

        // The card should now be expanded
        XCTAssertTrue(TunaSettings.shared.isTranscriptionOutputOpen)

        // Tap again to collapse
        try transcriptionCard.button().tap()

        // The card should be collapsed again
        XCTAssertFalse(TunaSettings.shared.isTranscriptionOutputOpen)
    }

    func testNoChevronIconsPresent() throws {
        // Create a settings view with preview settings
        let settingsView = TunaSettingsView()

        // Get the dictation tab view
        let dictationTab = try settingsView.inspect().find(viewWithId: "dictationTab")

        // Try to find any chevron icons
        let upChevrons = try dictationTab.findAll(ViewType.Image.self).filter { image in
            try image.actualImage().name() == "chevron.up"
        }
        let downChevrons = try dictationTab.findAll(ViewType.Image.self).filter { image in
            try image.actualImage().name() == "chevron.down"
        }

        // Verify no chevrons are present
        XCTAssertEqual(upChevrons.count, 0, "Should not find any up chevrons")
        XCTAssertEqual(downChevrons.count, 0, "Should not find any down chevrons")
    }
}
