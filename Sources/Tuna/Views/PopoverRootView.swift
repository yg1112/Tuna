import SwiftUI

struct PopoverRootView: View {
    @EnvironmentObject private var settings: TunaSettings
    @Environment(\.colorScheme) private var systemColorScheme
    
    private var effectiveColorScheme: ColorScheme? {
        switch settings.selectedTheme {
            case "light": return .light
            case "dark": return .dark
            default: return nil // System default
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Your existing popover content
            Text("Tuna")
                .font(.title)
                .padding()
        }
        .frame(width: 300, height: 400)
        .preferredColorScheme(self.effectiveColorScheme)
    }
} 