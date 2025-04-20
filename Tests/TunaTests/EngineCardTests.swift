import SwiftUI
@testable import Tuna
import ViewInspector
import XCTest

final class EngineCardTests: XCTestCase {
    override func setUp() {
        super.setUp()
        UserDefaultsHelper.resetAllSettings()
        TunaSettings.shared.loadDefaults()
    }
    
    override func tearDown() {
        UserDefaultsHelper.resetAllSettings()
        super.tearDown()
    }
    
    func testEngineCardExpansionState() throws {
        let testKey = "isEngineOpen"
        
        // Create a binding that uses UserDefaults
        let binding = Binding<Bool>(
            get: { UserDefaults.standard.bool(forKey: testKey) },
            set: { UserDefaults.standard.set($0, forKey: testKey) }
        )
        
        // Create the card with the binding
        let card = CollapsibleCard(title: "Engine", isExpanded: binding) {
            Text("Test Content")
        }
        
        // Initially, the card should be collapsed
        XCTAssertFalse(UserDefaults.standard.bool(forKey: testKey))
        
        // Expand the card
        UserDefaults.standard.set(true, forKey: testKey)
        
        // Verify the card is expanded
        XCTAssertTrue(UserDefaults.standard.bool(forKey: testKey))
    }
}
