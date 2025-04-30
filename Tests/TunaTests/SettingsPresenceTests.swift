import SwiftUI
@testable import TunaApp
import TunaCore
import TunaUI
import ViewInspector
import XCTest

final class SettingsPresenceTests: XCTestCase {
    var settingsView: TunaSettingsView!

    override func setUp() {
        super.setUp()
        UserDefaultsHelper.resetCardExpansionStates()
        TunaSettings.shared.loadDefaults()
        self.settingsView = TunaSettingsView()
    }

    override func tearDown() {
        UserDefaultsHelper.resetCardExpansionStates()
        self.settingsView = nil
        super.tearDown()
    }

    func testGeneralTabCardPresence() throws {
        // Get the general tab view
        let generalTab = try settingsView.inspect().find(viewWithId: "generalTab")

        // Find all CollapsibleCard titles
        let cardTitles = try generalTab.findAll(ViewType.Text.self)
            .compactMap { try $0.string() }
            .filter { $0 == "Launch on Startup" || $0 == "Check for Updates" }

        // Verify required cards are present
        XCTAssertEqual(cardTitles.count, 2, "Should have exactly 2 cards")
        XCTAssertTrue(cardTitles.contains("Launch on Startup"), "Should contain Launch card")
        XCTAssertTrue(cardTitles.contains("Check for Updates"), "Should contain Updates card")
    }

    func testDictationTabCardPresence() throws {
        // Get the dictation tab view
        let dictationTab = try settingsView.inspect().find(viewWithId: "dictationTab")

        // Find all CollapsibleCard titles
        let cardTitles = try dictationTab.findAll(ViewType.Text.self)
            .compactMap { try $0.string() }
            .filter {
                $0 == "Shortcut" || $0 == "Magic Transform" || $0 == "Engine" || $0 ==
                    "Transcription Output"
            }

        // Verify all four required cards are present
        XCTAssertEqual(cardTitles.count, 4, "Should have exactly 4 cards")
        XCTAssertTrue(cardTitles.contains("Shortcut"), "Should contain Shortcut card")
        XCTAssertTrue(cardTitles.contains("Magic Transform"), "Should contain Magic Transform card")
        XCTAssertTrue(cardTitles.contains("Engine"), "Should contain Engine card")
        XCTAssertTrue(
            cardTitles.contains("Transcription Output"),
            "Should contain Transcription Output card"
        )
    }

    func testAudioTabCardPresence() throws {
        // Get the audio tab view
        let audioTab = try settingsView.inspect().find(viewWithId: "audioTab")

        // Find all CollapsibleCard titles
        let cardTitles = try audioTab.findAll(ViewType.Text.self)
            .compactMap { try $0.string() }
            .filter { $0 == "Smart Swaps" || $0 == "Audio Devices" }

        // Verify required cards are present
        XCTAssertEqual(cardTitles.count, 2, "Should have exactly 2 cards")
        XCTAssertTrue(cardTitles.contains("Smart Swaps"), "Should contain Smart Swaps card")
        XCTAssertTrue(cardTitles.contains("Audio Devices"), "Should contain Audio Devices card")
    }

    func testAppearanceTabCardPresence() throws {
        // Get the appearance tab view
        let appearanceTab = try settingsView.inspect().find(viewWithId: "appearanceTab")

        // Find all CollapsibleCard titles
        let cardTitles = try appearanceTab.findAll(ViewType.Text.self)
            .compactMap { try $0.string() }
            .filter { $0 == "Theme" || $0 == "Appearance" }

        // Verify required cards are present
        XCTAssertEqual(cardTitles.count, 2, "Should have exactly 2 cards")
        XCTAssertTrue(cardTitles.contains("Theme"), "Should contain Theme card")
        XCTAssertTrue(cardTitles.contains("Appearance"), "Should contain Appearance card")
    }

    func testAdvancedTabCardPresence() throws {
        // Get the advanced tab view
        let advancedTab = try settingsView.inspect().find(viewWithId: "advancedTab")

        // Find all CollapsibleCard titles
        let cardTitles = try advancedTab.findAll(ViewType.Text.self)
            .compactMap { try $0.string() }
            .filter { $0 == "Beta Features" || $0 == "Debug" }

        // Verify required cards are present
        XCTAssertEqual(cardTitles.count, 2, "Should have exactly 2 cards")
        XCTAssertTrue(cardTitles.contains("Beta Features"), "Should contain Beta Features card")
        XCTAssertTrue(cardTitles.contains("Debug"), "Should contain Debug card")
    }

    func testSupportTabCardPresence() throws {
        // Get the support tab view
        let supportTab = try settingsView.inspect().find(viewWithId: "supportTab")

        // Find all CollapsibleCard titles
        let cardTitles = try supportTab.findAll(ViewType.Text.self)
            .compactMap { try $0.string() }
            .filter { $0 == "About Tuna" }

        // Verify required cards are present
        XCTAssertEqual(cardTitles.count, 1, "Should have exactly 1 card")
        XCTAssertTrue(cardTitles.contains("About Tuna"), "Should contain About card")
    }

    func testAllCardsDefaultExpansionState() throws {
        let settings = TunaSettings.shared

        // Verify all cards are expanded by default
        XCTAssertTrue(settings.isShortcutOpen, "Shortcut card should be expanded by default")
        XCTAssertTrue(
            settings.isMagicTransformOpen,
            "Magic Transform card should be expanded by default"
        )
        XCTAssertTrue(settings.isEngineOpen, "Engine card should be expanded by default")
        XCTAssertTrue(
            settings.isTranscriptionOutputOpen,
            "Transcription Output card should be expanded by default"
        )
        XCTAssertTrue(settings.isLaunchOpen, "Launch card should be expanded by default")
        XCTAssertTrue(settings.isUpdatesOpen, "Updates card should be expanded by default")
        XCTAssertTrue(settings.isSmartSwapsOpen, "Smart Swaps card should be expanded by default")
        XCTAssertTrue(
            settings.isAudioDevicesOpen,
            "Audio Devices card should be expanded by default"
        )
        XCTAssertTrue(settings.isThemeOpen, "Theme card should be expanded by default")
        XCTAssertTrue(settings.isAppearanceOpen, "Appearance card should be expanded by default")
        XCTAssertTrue(settings.isBetaOpen, "Beta Features card should be expanded by default")
        XCTAssertTrue(settings.isDebugOpen, "Debug card should be expanded by default")
        XCTAssertTrue(settings.isAboutOpen, "About card should be expanded by default")
    }
}
