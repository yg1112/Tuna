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
                    .foregroundColor(isSelected ? .green : .primary)
                
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
            
            ForEach(devices, id: \.id) { device in
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
    let device: AudioDevice
    let isInput: Bool
    let audioManager: AudioManager
    @Binding var volume: Float
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
            
            HStack {
                Slider(value: $volume, onEditingChanged: { isEditing in
                    if !isEditing {
                        audioManager.setVolumeForDevice(device: device, volume: volume, isInput: isInput)
                    }
                })
                .padding(.horizontal, 12)
            }
            .padding(.bottom, 4)
        }
    }
}

struct QuitButton: View {
    var body: some View {
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
                onSelect: { device in
                    audioManager.selectInputDevice(device)
                }
            )
            
            Divider()
            
            // Output Devices Section
            DeviceSection(
                title: "Output Devices",
                devices: audioManager.outputDevices,
                selectedDevice: audioManager.selectedOutputDevice,
                iconName: "speaker.wave.3",
                onSelect: { device in
                    audioManager.selectOutputDevice(device)
                }
            )
            
            Divider()
            
            // Volume Controls
            if let inputDevice = audioManager.selectedInputDevice {
                VolumeControl(
                    title: "Input Volume",
                    device: inputDevice,
                    isInput: true,
                    audioManager: audioManager,
                    volume: $audioManager.inputVolume
                )
            }
            
            if let outputDevice = audioManager.selectedOutputDevice {
                VolumeControl(
                    title: "Output Volume",
                    device: outputDevice,
                    isInput: false,
                    audioManager: audioManager,
                    volume: $audioManager.outputVolume
                )
            }
            
            Divider()
            
            // Sound Settings Button
            Button(action: {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.sound") {
                    NSWorkspace.shared.open(url)
                }
            }) {
                HStack {
                    Image(systemName: "gearshape")
                        .foregroundColor(.secondary)
                        .frame(width: 16)
                    Text("Sound Settings...")
                        .foregroundColor(.primary)
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.vertical, 2)
            .padding(.horizontal, 12)
            
            Divider()
            
            QuitButton()
        }
        .padding(.vertical, 4)
        .frame(width: 260)
        .background(Color(NSColor.windowBackgroundColor))
    }
}