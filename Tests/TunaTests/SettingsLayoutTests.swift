import XCTest
import SwiftUI
import ViewInspector
@testable import Tuna

final class SettingsLayoutTests: XCTestCase {
    func testSidebarWidth() throws {
        let settingsView = TunaSettingsView()
        
        // Find sidebar VStack
        let sidebar = try settingsView.inspect().hStack().vStack(0)
        let sidebarWidth = try sidebar.fixedWidth()
        
        XCTAssertLessThanOrEqual(sidebarWidth, 180, "Sidebar width should not exceed 180pt")
    }
    
    func testWindowHeight() throws {
        let window = TunaSettingsWindow()
        
        // Get content height of each tab
        let tabs = SettingsTab.allCases
        var maxHeight: CGFloat = 0
        
        for tab in tabs {
            let view = settingsViewForTab(tab)
            let height = try view.inspect().fixedHeight() ?? 0
            maxHeight = max(maxHeight, height)
        }
        
        // Add padding (48pt)
        let expectedMaxHeight = maxHeight + 48
        
        // Get actual window height
        let windowHeight = window.contentRect(forFrameRect: window.frame).height
        
        XCTAssertLessThanOrEqual(windowHeight, expectedMaxHeight, "Window height should not exceed content height + 48pt padding")
    }
    
    private func settingsViewForTab(_ tab: SettingsTab) -> some View {
        switch tab {
            case .general:
                return AnyView(GeneralSettingsView())
            case .dictation:
                return AnyView(DictationSettingsView())
            case .audio:
                return AnyView(AudioSettingsView())
            case .appearance:
                return AnyView(AppearanceSettingsView())
            case .advanced:
                return AnyView(AdvancedSettingsView())
            case .support:
                return AnyView(SupportSettingsView())
        }
    }
}

// Make settings views inspectable
extension TunaSettingsView: Inspectable { }
extension TunaSettingsWindow: Inspectable { }
extension GeneralSettingsView: Inspectable { }
extension DictationSettingsView: Inspectable { }
extension AudioSettingsView: Inspectable { }
extension AppearanceSettingsView: Inspectable { }
extension AdvancedSettingsView: Inspectable { }
extension SupportSettingsView: Inspectable { } 