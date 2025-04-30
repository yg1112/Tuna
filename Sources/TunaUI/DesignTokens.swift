import SwiftUI

// @module: SettingsUI
// @created_by_cursor: yes
// @summary: Design tokens for Tuna application
// @depends_on: None

public enum Colors {
    public static let accent = Color(red: 0.08, green: 0.84, blue: 0.63)
    public static let cardBg = Color(.windowBackgroundColor).opacity(0.7)
}

public enum Metrics {
    public static let sidebarW: CGFloat = 120
    public static let cardR: CGFloat = 5
    public static let cardPad: CGFloat = 8
}

public enum Typography {
    public static let title = Font.system(size: 11, weight: .medium)
    public static let body = Font.system(size: 10)
    public static let caption = Font.system(size: 9, weight: .bold)
}

// 设置侧边栏项的修饰符
public struct SettingsSidebarItemStyle: ViewModifier {
    public let isSelected: Bool

    public func body(content: Content) -> some View {
        content
            .font(.system(size: 13, weight: .bold))
            .frame(height: 22)
            .foregroundColor(self.isSelected ? Colors.accent : .primary)
    }
}

public extension View {
    func sidebarItemStyle(isSelected: Bool) -> some View {
        modifier(SettingsSidebarItemStyle(isSelected: isSelected))
    }
}
