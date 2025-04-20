import SwiftUI

// @module: SettingsUI
// @created_by_cursor: yes
// @summary: Sidebar tab component with icon and label
// @depends_on: DesignTokens.swift

struct SidebarTab: View {
    var icon: String
    var label: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .frame(width: 22, height: 22)

                Text(label)
                    .sidebarItemStyle(isSelected: isSelected)
            }
            .frame(width: Metrics.sidebarW - 20)
            .padding(.vertical, 6)
            .foregroundColor(isSelected ? Colors.accent : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SidebarTab_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 12) {
            SidebarTab(
                icon: "gear",
                label: "General",
                isSelected: true,
                action: {}
            )

            SidebarTab(
                icon: "mic",
                label: "Dictation",
                isSelected: false,
                action: {}
            )
        }
        .padding()
        .background(Color(.windowBackgroundColor))
        .previewLayout(.sizeThatFits)
    }
}
