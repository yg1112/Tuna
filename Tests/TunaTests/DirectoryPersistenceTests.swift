@testable import TunaApp
import TunaCore
import XCTest

final class DirectoryPersistenceTests: XCTestCase {
    private var testDefaults: UserDefaults!
    private var tempDirURL: URL!
    private var settings: TunaSettings!

    override func setUp() {
        super.setUp()
        // Create a test-specific UserDefaults suite
        self.testDefaults = UserDefaults(suiteName: "TunaTests")
        self.testDefaults.removePersistentDomain(forName: "TunaTests")

        // Create settings with test defaults
        self.settings = TunaSettings(defaults: self.testDefaults)
        TunaSettings.shared = self.settings

        // Create a fixed test directory path
        self.tempDirURL = URL(fileURLWithPath: "/tmp/tuna_test_dir")
        try? FileManager.default.createDirectory(
            at: self.tempDirURL,
            withIntermediateDirectories: true
        )
    }

    override func tearDown() {
        self.testDefaults.removePersistentDomain(forName: "TunaTests")
        self.testDefaults = nil
        self.settings = nil
        TunaSettings.shared = TunaSettings() // Reset shared instance
        try? FileManager.default.removeItem(at: self.tempDirURL)
        self.tempDirURL = nil
        super.tearDown()
    }

    func testDirectoryPersistence() throws {
        // Set the directory in settings
        self.settings.transcriptionOutputDirectory = self.tempDirURL

        // Verify URL was saved to UserDefaults as absoluteString
        XCTAssertEqual(
            self.testDefaults.string(forKey: "transcriptionOutputDirectory"),
            self.tempDirURL.standardized.absoluteString,
            "Directory URL should be saved as absoluteString in UserDefaults"
        )

        // Create a new settings instance with the same UserDefaults to verify persistence
        let newSettings = TunaSettings(defaults: self.testDefaults)
        XCTAssertEqual(
            newSettings.transcriptionOutputDirectory?.absoluteString,
            self.tempDirURL.standardized.absoluteString,
            "Directory URL should persist across instances"
        )
    }

    func testDirectoryDisplayHelper() {
        let settings = TunaSettings.shared

        // Test with nil directory
        settings.transcriptionOutputDirectory = nil
        XCTAssertEqual(settings.transcriptionOutputDirectoryDisplay, "Not set")

        // Test with temporary directory URL
        settings.transcriptionOutputDirectory = self.tempDirURL
        XCTAssertEqual(
            settings.transcriptionOutputDirectoryDisplay,
            self.tempDirURL.lastPathComponent,
            "Display should show last path component"
        )
    }

    func testDefaultCardExpansionStates() {
        // Create a new settings instance
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

        // Verify other cards are also expanded
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

    func testCardExpansionStatePersistence() {
        // Create a new settings instance
        let settings = TunaSettings.shared

        // Change some card states
        settings.isShortcutOpen = false
        settings.isMagicTransformOpen = false

        // Verify states are saved to UserDefaults
        XCTAssertFalse(
            self.testDefaults.bool(forKey: "isShortcutOpen"),
            "Card state should be saved to UserDefaults"
        )
        XCTAssertFalse(
            self.testDefaults.bool(forKey: "isMagicTransformOpen"),
            "Card state should be saved to UserDefaults"
        )

        // Create a new settings instance to verify persistence
        let newSettings = TunaSettings.shared
        XCTAssertFalse(
            newSettings.isShortcutOpen,
            "Card state should persist across instances"
        )
        XCTAssertFalse(
            newSettings.isMagicTransformOpen,
            "Card state should persist across instances"
        )
    }
}
