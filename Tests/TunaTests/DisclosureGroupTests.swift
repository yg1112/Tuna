import SwiftUI
@testable import TunaApp
import TunaCore
import ViewInspector
import XCTest

final class DisclosureGroupTests: XCTestCase {
    override func setUp() {
        super.setUp()
        // Reset settings before each test - non-collapsible cards are always expanded
        TunaSettings.shared.isEngineOpen = true
        TunaSettings.shared.isTranscriptionOutputOpen = true
    }

    func testEngineDisclosureExpansion() throws {
        let dictationTabView = DictationTabView(settings: TunaSettings.shared)

        // Find the Engine card and verify its components
        let engineCard = try dictationTabView.inspect()
            .find(viewWithAccessibilityIdentifier: "EngineCard")
        XCTAssertNoThrow(
            try engineCard.find(viewWithAccessibilityIdentifier: "EngineHeader"),
            "Engine header should be visible"
        )
        XCTAssertNoThrow(
            try engineCard.find(viewWithAccessibilityIdentifier: "EngineContent"),
            "Engine content should be visible"
        )
        XCTAssertThrowsError(
            try engineCard.find(viewWithAccessibilityIdentifier: "EngineChevron"),
            "Non-collapsible Engine card should not have a chevron"
        )
    }

    func testTranscriptionOutputDisclosureExpansion() throws {
        let dictationTabView = DictationTabView(settings: TunaSettings.shared)

        // Find the Transcription Output card and verify its components
        let transcriptionCard = try dictationTabView.inspect()
            .find(viewWithAccessibilityIdentifier: "TranscriptionOutputCard")
        XCTAssertNoThrow(
            try transcriptionCard
                .find(viewWithAccessibilityIdentifier: "TranscriptionOutputHeader"),
            "Transcription output header should be visible"
        )
        XCTAssertNoThrow(
            try transcriptionCard
                .find(viewWithAccessibilityIdentifier: "TranscriptionOutputContent"),
            "Transcription output content should be visible"
        )
        XCTAssertThrowsError(
            try transcriptionCard
                .find(viewWithAccessibilityIdentifier: "TranscriptionOutputChevron"),
            "Non-collapsible Transcription Output card should not have a chevron"
        )
    }

    func testNoChevronIconsPresent() throws {
        let dictationTabView = DictationTabView(settings: TunaSettings.shared)

        // Verify that chevron icons are not present in any non-collapsible cards
        let engineCard = try dictationTabView.inspect()
            .find(viewWithAccessibilityIdentifier: "EngineCard")
        XCTAssertThrowsError(
            try engineCard.find(viewWithAccessibilityIdentifier: "EngineChevron"),
            "Engine card should not have a chevron"
        )

        let transcriptionCard = try dictationTabView.inspect()
            .find(viewWithAccessibilityIdentifier: "TranscriptionOutputCard")
        XCTAssertThrowsError(
            try transcriptionCard
                .find(viewWithAccessibilityIdentifier: "TranscriptionOutputChevron"),
            "Transcription Output card should not have a chevron"
        )
    }
}
