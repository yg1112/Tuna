import XCTest
import SwiftUI
import ViewInspector
@testable import Tuna

final class ThemeToggleTests: XCTestCase {
    override func setUp() {
        super.setUp()
        // Reset theme to system before each test
        UserDefaults.standard.set("system", forKey: "selectedTheme")
    }
    
    func testThemeToggleInPopover() throws {
        let settings = TunaSettings.shared
        let popoverView = PopoverRootView()
            .environmentObject(settings)
        
        // Test light theme
        UserDefaults.standard.set("light", forKey: "selectedTheme")
        let lightScheme = try popoverView.inspect().view(PopoverRootView.self).environment(\.colorScheme)
        XCTAssertEqual(lightScheme, .light)
        
        // Test dark theme
        UserDefaults.standard.set("dark", forKey: "selectedTheme")
        let darkScheme = try popoverView.inspect().view(PopoverRootView.self).environment(\.colorScheme)
        XCTAssertEqual(darkScheme, .dark)
    }
    
    func testThemeSettingPersistence() {
        let settings = TunaSettings.shared
        
        // Test default value
        XCTAssertEqual(settings.selectedTheme, "system")
        
        // Test setting a new value
        settings.selectedTheme = "dark"
        XCTAssertEqual(settings.selectedTheme, "dark")
        XCTAssertEqual(UserDefaults.standard.string(forKey: "selectedTheme"), "dark")
    }
}

// Make PopoverRootView inspectable
extension PopoverRootView: Inspectable { } 