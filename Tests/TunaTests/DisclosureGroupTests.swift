import SwiftUI
@testable import Tuna
import ViewInspector
import XCTest

// Enable inspection for TunaSettingsView
extension TunaSettingsView: Inspectable {}

final class DisclosureGroupTests: XCTestCase {
    func testEngineDisclosureExpansion() throws {
        // Create a settings view with preview settings
        let settingsView = TunaSettingsView()

        // Get the dictation tab view
        let dictationTab = try settingsView.inspect().find(viewWithId: "dictationTab")

        // Find the Engine card by its title
        let engineCard = try dictationTab.find(viewWithTag: "EngineCard")

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

        // Find the Transcription Output card by its title
        let transcriptionCard = try dictationTab.find(viewWithTag: "TranscriptionOutputCard")

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
}
