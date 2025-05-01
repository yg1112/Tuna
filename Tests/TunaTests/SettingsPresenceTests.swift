import SwiftUI
@testable import TunaApp
import TunaAudio
import TunaCore
import TunaUI
import ViewInspector
import XCTest

final class SettingsPresenceTests: XCTestCase {
    var testDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        // Create a test-specific UserDefaults suite
        self.testDefaults = UserDefaults(suiteName: "ai.tuna.tests")
        self.testDefaults.removePersistentDomain(forName: "ai.tuna.tests")

        // Reset card expansion states
        self.resetTestEnvironment()

        // Initialize settings with test defaults
        TunaSettings.shared = TunaSettings(defaults: self.testDefaults)
        TunaSettings.shared.loadDefaults()
    }

    override func tearDown() {
        self.resetTestEnvironment()
        self.testDefaults.removePersistentDomain(forName: "ai.tuna.tests")
        self.testDefaults = nil
        super.tearDown()
    }

    private func resetTestEnvironment() {
        // Reset all expansion states
        TunaSettings.shared.isEngineOpen = false
        TunaSettings.shared.isTranscriptionOutputOpen = false
        TunaSettings.shared.isShortcutOpen = false
        TunaSettings.shared.isMagicTransformOpen = false
        TunaSettings.shared.isLaunchOpen = false
        TunaSettings.shared.isUpdatesOpen = false
        TunaSettings.shared.isAudioDevicesOpen = false
        TunaSettings.shared.isThemeOpen = false
        TunaSettings.shared.isAppearanceOpen = false
        TunaSettings.shared.isBetaOpen = false
        TunaSettings.shared.isDebugOpen = false
        TunaSettings.shared.isAboutOpen = false
    }

    func testGeneralTabCardPresence() throws {
        let generalTabView = GeneralTabView(settings: TunaSettings.shared)
        let view = try generalTabView.inspect()

        // Find cards in the general tab
        let scrollView = try view.find(ViewType.ScrollView.self)
        let vstack = try scrollView.vStack()

        // Find Launch on Startup card
        let launchCard = try vstack.find(viewWithAccessibilityIdentifier: "launchCard")
        XCTAssertNotNil(launchCard, "Launch on Startup card should be present")

        // Find Check for Updates card
        let updatesCard = try vstack.find(viewWithAccessibilityIdentifier: "updatesCard")
        XCTAssertNotNil(updatesCard, "Check for Updates card should be present")
    }

    func testDictationTabCardPresence() throws {
        let dictationTabView = DictationTabView(settings: TunaSettings.shared)
        let view = try dictationTabView.inspect()

        // Find the cards by their accessibility identifiers
        let engineCard = try view.find(viewWithAccessibilityIdentifier: "EngineCard")
        XCTAssertNotNil(engineCard)

        let transcriptionCard = try view
            .find(viewWithAccessibilityIdentifier: "TranscriptionOutputCard")
        XCTAssertNotNil(transcriptionCard)

        // Verify card titles
        let engineTitle = try engineCard.find(text: "Engine")
        XCTAssertNotNil(engineTitle)

        let transcriptionTitle = try transcriptionCard.find(text: "Transcription Output")
        XCTAssertNotNil(transcriptionTitle)
    }

    func testAudioTabCardPresence() throws {
        let audioTabView = AudioTabView(
            settings: TunaSettings.shared,
            audioManager: AudioManager.shared
        )
        let view = try audioTabView.inspect()

        // Find cards in the audio tab
        let scrollView = try view.find(ViewType.ScrollView.self)
        let vstack = try scrollView.vStack()

        // Find Audio Devices card
        let audioDevicesCard = try vstack.find(viewWithAccessibilityIdentifier: "audioDevicesCard")
        XCTAssertNotNil(audioDevicesCard, "Audio Devices card should be present")
    }

    func testAppearanceTabCardPresence() throws {
        let appearanceTabView = AppearanceTabView(settings: TunaSettings.shared)
        let view = try appearanceTabView.inspect()

        // Find cards in the appearance tab
        let scrollView = try view.find(ViewType.ScrollView.self)
        let vstack = try scrollView.vStack()

        // Find Theme card
        let themeCard = try vstack.find(viewWithAccessibilityIdentifier: "themeCard")
        XCTAssertNotNil(themeCard, "Theme card should be present")

        // Find Appearance card
        let appearanceCard = try vstack.find(viewWithAccessibilityIdentifier: "appearanceCard")
        XCTAssertNotNil(appearanceCard, "Appearance card should be present")
    }

    func testAdvancedTabCardPresence() throws {
        let advancedTabView = AdvancedTabView(settings: TunaSettings.shared)
        let view = try advancedTabView.inspect()

        // Find cards in the advanced tab
        let scrollView = try view.find(ViewType.ScrollView.self)
        let vstack = try scrollView.vStack()

        // Find Beta Features card
        let betaCard = try vstack.find(viewWithAccessibilityIdentifier: "betaCard")
        XCTAssertNotNil(betaCard, "Beta Features card should be present")

        // Find Debug card
        let debugCard = try vstack.find(viewWithAccessibilityIdentifier: "debugCard")
        XCTAssertNotNil(debugCard, "Debug card should be present")
    }

    func testSupportTabCardPresence() throws {
        let supportTabView = SupportTabView(settings: TunaSettings.shared)
        let view = try supportTabView.inspect()

        // Find cards in the support tab
        let scrollView = try view.find(ViewType.ScrollView.self)
        let vstack = try scrollView.vStack()

        // Find About card
        let aboutCard = try vstack.find(viewWithAccessibilityIdentifier: "aboutCard")
        XCTAssertNotNil(aboutCard, "About card should be present")
    }
}
