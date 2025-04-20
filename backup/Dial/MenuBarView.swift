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

struct VolumeControl: View {
    let title: String
    @Binding var volume: Float
    let isInput: Bool
    @EnvironmentObject private var audioManager: AudioManager

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(self.title)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)

            HStack {
                Slider(value: self.$volume, onEditingChanged: { _ in
                    self.audioManager.setVolume(self.volume, forInput: self.isInput)
                })
                .padding(.horizontal, 12)
            }
            .padding(.bottom, 4)
        }
    }
}

@available(macOS 13.0, *)
struct MenuBarView: View {
    @EnvironmentObject private var audioManager: AudioManager
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 4) {
            // Input Devices Section
            DeviceSection(
                title: "Input Devices",
                devices: self.audioManager.inputDevices,
                selectedDevice: self.audioManager.selectedInputDevice,
                iconName: "mic",
                onSelect: self.audioManager.selectInputDevice
            )

            Divider()

            // Output Devices Section
            DeviceSection(
                title: "Output Devices",
                devices: self.audioManager.outputDevices,
                selectedDevice: self.audioManager.selectedOutputDevice,
                iconName: "speaker.wave.3",
                onSelect: self.audioManager.selectOutputDevice
            )

            Divider()

            // Volume Controls
            if self.audioManager.selectedInputDevice != nil {
                VolumeControl(
                    title: "Input Volume",
                    volume: self.$audioManager.inputVolume,
                    isInput: true
                )
            }

            if self.audioManager.selectedOutputDevice != nil {
                VolumeControl(
                    title: "Output Volume",
                    volume: self.$audioManager.outputVolume,
                    isInput: false
                )
            }

            Divider()

            // Quit Button
            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                HStack {
                    Image(systemName: "power")
                        .foregroundColor(.secondary)
                        .frame(width: 16)
                    Text("Quit")
                        .foregroundColor(.primary)
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.vertical, 2)
            .padding(.horizontal, 12)
        }
        .padding(.vertical, 4)
        .frame(width: 260)
        .background(Color(NSColor.windowBackgroundColor))
    }
}
