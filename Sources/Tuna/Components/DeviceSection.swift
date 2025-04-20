import SwiftUI

struct DeviceSection: View {
    let title: String
    let devices: [AudioDevice]
    let selectedDevice: AudioDevice?
    let iconName: String
    let onSelect: (AudioDevice) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(self.title)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)

            ForEach(self.devices) { device in
                DeviceListItem(
                    device: device,
                    isSelected: device.id == self.selectedDevice?.id,
                    iconName: self.iconName,
                    action: { self.onSelect(device) }
                )
            }
        }
    }
} 