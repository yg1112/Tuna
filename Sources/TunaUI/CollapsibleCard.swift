import SwiftUI
import TunaCore

// @module: SettingsUI
// @created_by_cursor: yes
// @summary: Reusable collapsible card component with styled disclosure group
// @depends_on: DesignTokens.swift

private struct NonCollapsibleButtonStyle: ButtonStyle {
    let collapsible: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(self.collapsible ? (configuration.isPressed ? 0.7 : 1.0) : 1.0)
            .allowsHitTesting(self.collapsible)
    }
}

public struct CollapsibleCard<Content: View>: View {
    public let title: String
    @Binding private var isExpandedBinding: Bool
    let content: () -> Content
    let collapsible: Bool

    private var accessibilityPrefix: String {
        // Remove spaces and special characters, keeping only alphanumeric
        // Also ensure consistent casing for identifiers
        self.title.components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined()
            .replacingOccurrences(of: " ", with: "")
    }

    // Computed binding that forces true for non-collapsible cards
    private var effectiveExpanded: Binding<Bool> {
        Binding(
            get: { self.collapsible ? self.isExpandedBinding : true },
            set: { newValue in
                if self.collapsible {
                    self.isExpandedBinding = newValue
                }
            }
        )
    }

    public init(
        title: String,
        isExpanded: Binding<Bool>,
        collapsible: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self._isExpandedBinding = isExpanded
        self.content = content
        self.collapsible = collapsible
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: {
                if self.collapsible {
                    self.effectiveExpanded.wrappedValue.toggle()
                }
            }) {
                HStack {
                    Text(self.title)
                        .font(.headline)
                    Spacer()
                    if self.collapsible {
                        Image(systemName: "chevron.right")
                            .rotationEffect(.degrees(self.effectiveExpanded.wrappedValue ? 90 : 0))
                            .animation(
                                .easeInOut(duration: 0.2),
                                value: self.effectiveExpanded.wrappedValue
                            )
                            .accessibilityIdentifier("\(self.accessibilityPrefix)Chevron")
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.clear)
            }
            .buttonStyle(NonCollapsibleButtonStyle(collapsible: self.collapsible))
            .accessibilityIdentifier("\(self.accessibilityPrefix)Header")

            if self.effectiveExpanded.wrappedValue {
                self.content()
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .accessibilityIdentifier("\(self.accessibilityPrefix)Content")
            }
        }
        .background(Color(.windowBackgroundColor))
        .cornerRadius(8)
        .shadow(radius: 2)
        .accessibilityIdentifier("\(self.accessibilityPrefix)Card")
    }
}

public struct CollapsibleCard_Previews: PreviewProvider {
    public static var previews: some View {
        VStack {
            CollapsibleCard(
                title: "Non-collapsible Card",
                isExpanded: .constant(true),
                collapsible: false
            ) {
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
