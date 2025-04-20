import SwiftUI

struct DeviceButton: View {
    let device: AudioDevice
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: self.action) {
            Text(self.device.name)
                .foregroundColor(self.isSelected ? .accentColor : .primary)
        }
        .buttonStyle(.plain)
    }
} 