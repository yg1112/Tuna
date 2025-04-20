import SwiftUI

struct DeviceButton: View {
    let device: AudioDevice
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(device.name)
                .foregroundColor(isSelected ? .accentColor : .primary)
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
        Button(action: action) {
            HStack {
                Image(systemName: iconName)
                    .foregroundColor(.secondary)
                    .frame(width: 16)

                Text(device.name)
                    .foregroundColor(.primary)

                Spacer()
                if isSelected {
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
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)

            ForEach(devices) { device in
                DeviceListItem(
                    device: device,
                    isSelected: device.id == selectedDevice?.id,
                    iconName: iconName,
                    action: { onSelect(device) }
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
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)

            HStack {
                Slider(value: $volume, onEditingChanged: { _ in
                    audioManager.setVolume(volume, forInput: isInput)
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
                devices: audioManager.inputDevices,
                selectedDevice: audioManager.selectedInputDevice,
                iconName: "mic",
                onSelect: audioManager.selectInputDevice
            )

            Divider()

            // Output Devices Section
            DeviceSection(
                title: "Output Devices",
                devices: audioManager.outputDevices,
                selectedDevice: audioManager.selectedOutputDevice,
                iconName: "speaker.wave.3",
                onSelect: audioManager.selectOutputDevice
            )

            Divider()

            // Volume Controls
            if audioManager.selectedInputDevice != nil {
                VolumeControl(
                    title: "Input Volume",
                    volume: $audioManager.inputVolume,
                    isInput: true
                )
            }

            if audioManager.selectedOutputDevice != nil {
                VolumeControl(
                    title: "Output Volume",
                    volume: $audioManager.outputVolume,
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
