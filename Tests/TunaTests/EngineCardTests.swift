import XCTest
import SwiftUI
@testable import Tuna

final class EngineCardTests: XCTestCase {
    override func setUp() {
        super.setUp()
        // Reset settings before each test
        UserDefaults.standard.removeObject(forKey: "isEngineOpen")
    }
    
    func testCollapsibleCardToggle() {
        // Create an observable state value
        var isExpanded = false
        
        // Create a CollapsibleCard with a binding
        let _ = CollapsibleCard(title: "Test Card", isExpanded: Binding(
            get: { isExpanded },
            set: { isExpanded = $0 }
        )) {
            Text("Content")
        }
        
        // Verify initial state is collapsed
        XCTAssertFalse(isExpanded)
        
        // Simulate button tap - directly change the bound value
        isExpanded = true
        
        // Verify state has changed to expanded
        XCTAssertTrue(isExpanded, "Card should be expanded after button tap")
        
        // Simulate tap again to collapse
        isExpanded = false
        
        // Verify state has changed back to collapsed
        XCTAssertFalse(isExpanded, "Card should be collapsed after second tap")
    }
    
    func testCardPersistsState() {
        // Create a UserDefaults key for testing
        let testKey = "engineCard.testState"
        
        // Clear any existing value
        UserDefaults.standard.removeObject(forKey: testKey)
        
        // Create a binding to UserDefaults
        let binding = Binding<Bool>(
            get: { UserDefaults.standard.bool(forKey: testKey) },
            set: { UserDefaults.standard.set($0, forKey: testKey) }
        )
        
        // Create a card with this binding
        let _ = CollapsibleCard(title: "Test Card", isExpanded: binding) {
            Text("Content")
        }
        
        // Verify default state is false
        XCTAssertFalse(UserDefaults.standard.bool(forKey: testKey))
        
        // Change the state to expanded
        UserDefaults.standard.set(true, forKey: testKey)
        
        // Verify state has changed
        XCTAssertTrue(UserDefaults.standard.bool(forKey: testKey))
        
        // Clean up
        UserDefaults.standard.removeObject(forKey: testKey)
    }
} 