import XCTest
import SwiftUI
@testable import Tuna

final class EngineCardTests: XCTestCase {
    override func setUp() {
        super.setUp()
        // Reset settings before each test
        UserDefaults.standard.removeObject(forKey: "isEngineOpen")
    }
    
    func testEngineCardStateDefaultsFalse() {
        // Create a new settings instance
        let settings = TunaSettings.shared
        
        // Test default value
        XCTAssertFalse(settings.isEngineOpen, "Engine card should be collapsed by default")
    }
    
    func testEngineCardStateToggle() {
        // Get shared settings instance
        let settings = TunaSettings.shared
        
        // Start with default state (false)
        XCTAssertFalse(settings.isEngineOpen, "Engine card should start collapsed")
        
        // Toggle state
        settings.isEngineOpen = true
        XCTAssertTrue(settings.isEngineOpen, "Engine card should be expanded after toggle")
        
        // Toggle back
        settings.isEngineOpen = false
        XCTAssertFalse(settings.isEngineOpen, "Engine card should be collapsed after second toggle")
    }
    
    func testEngineCardStatePersistence() {
        // First verify default state
        XCTAssertFalse(TunaSettings.shared.isEngineOpen, "Should start collapsed")
        
        // Set to expanded
        TunaSettings.shared.isEngineOpen = true
        
        // Create new instance to verify persistence
        let newSettings = TunaSettings.shared
        XCTAssertTrue(newSettings.isEngineOpen, "Expanded state should persist in UserDefaults")
        
        // Reset to collapsed
        newSettings.isEngineOpen = false
        XCTAssertFalse(TunaSettings.shared.isEngineOpen, "Collapsed state should persist")
    }
} 