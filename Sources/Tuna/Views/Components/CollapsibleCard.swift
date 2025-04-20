import SwiftUI

// @module: SettingsUI
// @created_by_cursor: yes
// @summary: Reusable collapsible card component with styled disclosure group
// @depends_on: DesignTokens.swift

struct CollapsibleCard<Content: View>: View {
    var title: String
    @Binding var isExpanded: Bool
    var content: () -> Content

    // Constructor with Binding
    init(title: String, isExpanded: Binding<Bool>, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        _isExpanded = isExpanded
        self.content = content
    }

    // Backward compatibility with static isExpanded value
    init(title: String, isExpanded: Bool = true, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        _isExpanded = .constant(isExpanded)
        self.content = content
    }

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            content()
                .padding(.top, 6)
        } label: {
            Button(action: {
                print("🔵 \(title) tapped") // 调试日志
                withAnimation(.easeInOut(duration: 0.15)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(title)
                        .font(Typography.title)
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .foregroundColor(.secondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(Metrics.cardPad)
        .background(Colors.cardBg)
        .allowsHitTesting(true) // 明确允许点击
        .cornerRadius(Metrics.cardR)
        .overlay(
            RoundedRectangle(cornerRadius: Metrics.cardR)
                .stroke(Color(.separatorColor), lineWidth: 0.5)
                .allowsHitTesting(false)
        )
        .overlay(
            Rectangle().fill(Color.green.opacity(0.85))
                .frame(width: 3)
                .opacity(isExpanded ? 1 : 0)
                .allowsHitTesting(false)
                .animation(.easeInOut(duration: 0.15), value: isExpanded),
            alignment: .leading
        )
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
