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
    let collapsible: Bool

    init(title: String, isExpanded: Binding<Bool>, collapsible: Bool = true, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self._isExpanded = isExpanded
        self.content = content
        self.collapsible = collapsible
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(self.title)
                    .font(.headline)
                Spacer()
                if collapsible {
                    Image(systemName: self.isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())
            .onTapGesture {
                if collapsible {
                    withAnimation {
                        self.isExpanded.toggle()
                    }
                }
            }
            .accessibilityIdentifier("\(self.title)Toggle")

            if !collapsible || self.isExpanded {
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
            CollapsibleCard(title: "Non-collapsible Card", isExpanded: .constant(true), collapsible: false) {
                Text("This content is always visible")
                    .font(Typography.body)
                    .padding(.top, 4)
            }

            CollapsibleCard(title: "Collapsible Card", isExpanded: .constant(false)) {
                Text("This content can be hidden")
                    .font(Typography.body)
                    .padding(.top, 4)
            }
        }
        .padding()
    }
}
