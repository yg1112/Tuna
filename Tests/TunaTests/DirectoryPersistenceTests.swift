import XCTest
@testable import Tuna

final class DirectoryPersistenceTests: XCTestCase {
    private var testDefaults: UserDefaults!
    private var tempDirURL: URL!
    
    override func setUp() {
        super.setUp()
        // Create a test-specific UserDefaults suite
        self.testDefaults = UserDefaults(suiteName: "TunaTests")
        self.testDefaults.removePersistentDomain(forName: "TunaTests")
        
        // Create a temporary directory for testing
        self.tempDirURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDirURL, withIntermediateDirectories: true)
    }
    
    override func tearDown() {
        self.testDefaults.removePersistentDomain(forName: "TunaTests")
        self.testDefaults = nil
        try? FileManager.default.removeItem(at: tempDirURL)
        self.tempDirURL = nil
        super.tearDown()
    }
    
    func testDirectoryPersistence() throws {
        // Set the directory in settings
        let settings = TunaSettings.shared
        settings.transcriptionOutputDirectory = tempDirURL
        
        // Verify URL was saved to UserDefaults as absoluteString
        XCTAssertEqual(
            self.testDefaults.string(forKey: "transcriptionOutputDirectory"),
            tempDirURL.absoluteString,
            "Directory URL should be saved as absoluteString in UserDefaults"
        )
        
        // Create a new settings instance to verify persistence
        let newSettings = TunaSettings.shared
        XCTAssertEqual(
            newSettings.transcriptionOutputDirectory?.absoluteString,
            tempDirURL.absoluteString,
            "Directory URL should persist across instances"
        )
    }
    
    func testDirectoryDisplayHelper() {
        let settings = TunaSettings.shared
        
        // Test with nil directory
        settings.transcriptionOutputDirectory = nil
        XCTAssertEqual(settings.transcriptionOutputDirectoryDisplay, "Not set")
        
        // Test with temporary directory URL
        settings.transcriptionOutputDirectory = tempDirURL
        XCTAssertEqual(
            settings.transcriptionOutputDirectoryDisplay,
            tempDirURL.lastPathComponent,
            "Display should show last path component"
        )
    }
    
    func testDefaultCardExpansionStates() {
        // Create a new settings instance
        let settings = TunaSettings.shared
        
        // Verify all cards are expanded by default
        XCTAssertTrue(settings.isShortcutOpen, "Shortcut card should be expanded by default")
        XCTAssertTrue(settings.isMagicTransformOpen, "Magic Transform card should be expanded by default")
        XCTAssertTrue(settings.isEngineOpen, "Engine card should be expanded by default")
        XCTAssertTrue(settings.isTranscriptionOutputOpen, "Transcription Output card should be expanded by default")
        
        // Verify other cards are also expanded
        XCTAssertTrue(settings.isLaunchOpen, "Launch card should be expanded by default")
        XCTAssertTrue(settings.isUpdatesOpen, "Updates card should be expanded by default")
        XCTAssertTrue(settings.isSmartSwapsOpen, "Smart Swaps card should be expanded by default")
        XCTAssertTrue(settings.isAudioDevicesOpen, "Audio Devices card should be expanded by default")
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