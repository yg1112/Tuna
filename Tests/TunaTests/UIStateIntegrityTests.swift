import XCTest
@testable import Tuna

final class UIStateIntegrityTests: XCTestCase {
    func testAllUIStatePropertiesExist() throws {
        let uiState = UIState()
        let mirror = Mirror(reflecting: uiState)
        
        // Get all property names from UIState
        let propertyNames = mirror.children.compactMap { child in
            return child.label
        }
        
        // Verify each Section case has a corresponding property
        for section in UIState.Section.allCases {
            let propertyName = section.rawValue
            XCTAssertTrue(
                propertyNames.contains(propertyName),
                "Missing UIState property: \(propertyName)"
            )
        }
    }
    
    func testAllPropertiesHaveSection() throws {
        let uiState = UIState()
        let mirror = Mirror(reflecting: uiState)
        
        // Get all boolean property names
        let boolPropertyNames = mirror.children.compactMap { child -> String? in
            guard child.value is Bool else { return nil }
            return child.label
        }
        
        // Get all section raw values
        let sectionRawValues = Set(UIState.Section.allCases.map(\.rawValue))
        
        // Verify each boolean property has a corresponding section
        for propertyName in boolPropertyNames {
            XCTAssertTrue(
                sectionRawValues.contains(propertyName),
                "Missing Section case for property: \(propertyName)"
            )
        }
    }
    
    func testKeyPathsWork() throws {
        let uiState = UIState()
        
        // Test each keyPath can get and set values
        for section in UIState.Section.allCases {
            let keyPath = section.keyPath
            
            // Test get
            XCTAssertFalse(uiState[keyPath: keyPath], "Initial value should be false")
            
            // Test set
            uiState[keyPath: keyPath] = true
            XCTAssertTrue(uiState[keyPath: keyPath], "Value should be settable to true")
        }
    }
} 