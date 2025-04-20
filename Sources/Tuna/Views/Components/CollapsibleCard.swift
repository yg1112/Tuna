import AppKit
import SwiftUI

// @module: SettingsUI
// @created_by_cursor: yes
// @summary: Reusable collapsible card component with styled disclosure group
// @depends_on: DesignTokens.swift

struct CollapsibleCard<Content: View>: View {
    let title: String
    @Binding var isExpanded: Bool
    let content: () -> Content

    init(title: String, isExpanded: Binding<Bool>, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self._isExpanded = isExpanded
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: {
                withAnimation {
                    self.isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(self.title)
                        .font(.headline)
                    Spacer()
                    Image(systemName: self.isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityIdentifier("\(self.title)Toggle")

            if self.isExpanded {
                self.content()
                    .padding(.top, 8)
                    .transition(.opacity)
            }
        }
        .padding(.horizontal)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(8)
    }
}

struct CollapsibleCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            CollapsibleCard(title: "Expanded Card", isExpanded: .constant(true)) {
                Text("Card content goes here")
                    .font(Typography.body)
                    .padding(.top, 4)
            }

            CollapsibleCard(title: "Collapsed Card", isExpanded: .constant(false)) {
                Text("This content is hidden")
                    .font(Typography.body)
                    .padding(.top, 4)
            }
        }
        .padding()
    }
}
