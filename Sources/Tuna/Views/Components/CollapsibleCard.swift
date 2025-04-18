import SwiftUI

// @module: SettingsUI
// @created_by_cursor: yes
// @summary: Reusable collapsible card component with styled disclosure group
// @depends_on: DesignTokens.swift

struct CollapsibleCard<Content: View>: View {
    var title: String
    var isExpanded: Bool
    var content: () -> Content
    
    init(title: String, isExpanded: Bool = true, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.isExpanded = isExpanded
        self.content = content
    }
    
    var body: some View {
        DisclosureGroup(
            isExpanded: .constant(isExpanded),
            content: content,
            label: {
                Text(title)
                    .font(Typography.title)
                    .foregroundColor(.primary)
            }
        )
        .padding(Metrics.cardPad)
        .background(Colors.cardBg)
        .cornerRadius(Metrics.cardR)
        .overlay(
            RoundedRectangle(cornerRadius: Metrics.cardR)
                .stroke(Color(.separatorColor), lineWidth: 0.5)
        )
    }
}

struct CollapsibleCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            CollapsibleCard(title: "Expanded Card") {
                Text("Card content goes here")
                    .font(Typography.body)
                    .padding(.top, 4)
            }
            
            CollapsibleCard(title: "Collapsed Card", isExpanded: false) {
                Text("This content is hidden")
                    .font(Typography.body)
                    .padding(.top, 4)
            }
        }
        .padding()
    }
} 