import SwiftUI

// @module: SettingsUI
// @created_by_cursor: yes
// @summary: Design tokens for Tuna application
// @depends_on: None

enum Colors {
    static let accent = Color(red: 0.08, green: 0.84, blue: 0.63)
    static let cardBg = Color(.windowBackgroundColor).opacity(0.7)
}

enum Metrics {
    static let sidebarW: CGFloat = 120
    static let cardR: CGFloat = 5
    static let cardPad: CGFloat = 8
}

enum Typography {
    static let title = Font.system(size: 11, weight: .medium)
    static let body = Font.system(size: 10)
    static let caption = Font.system(size: 9)
} 