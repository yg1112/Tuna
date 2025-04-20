import XCTest
@testable import Tuna

final class BindingIntegrityTests: XCTestCase {
    func testSettingsManagerBindings() {
        let settings = SettingsManager.shared
        
        // Test tab collapse states
        XCTAssertNotNil(settings.isLaunchOpen)
        XCTAssertNotNil(settings.isShortcutOpen)
        XCTAssertNotNil(settings.isSmartSwapsOpen)
        XCTAssertNotNil(settings.isThemeOpen)
        XCTAssertNotNil(settings.isBetaOpen)
        XCTAssertNotNil(settings.isAboutOpen)
        
        // Test feature flags
        XCTAssertNotNil(settings.isThemeChangeEnabled)
        XCTAssertNotNil(settings.enableDictationShortcut)
        XCTAssertNotNil(settings.enableSmartSwitching)
        
        // Test settings state
        XCTAssertNotNil(settings.launchAtLogin)
    }
    
    func testDictationManagerBindings() {
        let dictation = DictationManager.shared
        
        // Test core properties
        XCTAssertNotNil(dictation.state)
        XCTAssertNotNil(dictation.progressMessage)
        XCTAssertNotNil(dictation.transcribedText)
        XCTAssertNotNil(dictation.isRecording)
        
        // Test new properties
        XCTAssertNotNil(dictation.outputFormat)
        XCTAssertNotNil(dictation.magicEnabled)
        XCTAssertNotNil(dictation.outputDirectory)
    }
} 