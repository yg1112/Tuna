import SwiftUI

struct DeviceListItem: View {
    let device: AudioDevice
    let isSelected: Bool
    let iconName: String
    let action: () -> Void

    var body: some View {
        Button(action: self.action) {
            HStack {
                Image(systemName: self.iconName)
                    .foregroundColor(.secondary)
                    .frame(width: 16)

                Text(self.device.name)
                    .foregroundColor(.primary)

                Spacer()
                if self.isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.green)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.vertical, 2)
        .padding(.horizontal, 12)
    }
} 