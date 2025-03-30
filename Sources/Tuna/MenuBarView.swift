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
    let onTap: () -> Void
    
    var deviceIcon: String {
        if device.name.contains("MacBook Pro") {
            return device.isInput ? "laptopcomputer" : "laptopcomputer"
        } else if device.name.contains("HDR") || device.name.contains("Display") {
            return "display"
        } else if device.name.contains("AirPods") || device.name.contains("Headphones") {
            return "airpodspro"
        } else if device.name.contains("iPhone") {
            return "iphone"
        } else {
            return device.isInput ? "mic" : "speaker.wave.2"
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: deviceIcon)
                    .font(.system(size: 14))
                    .foregroundColor(isSelected ? .green : .secondary)
                    .frame(width: 20)
                
                Text(device.name)
                    .font(.system(size: 14))
                    .lineLimit(1)
                    .truncationMode(.middle)
                
                Spacer()
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .buttonStyle(DeviceButtonStyle())
    }
}

struct DeviceSection: View {
    let title: String
    let devices: [AudioDevice]
    let selectedDevice: AudioDevice?
    let onDeviceSelected: (AudioDevice) -> Void
    let volumeControl: (() -> VolumeSlider)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
            
            ForEach(devices) { device in
                DeviceListItem(device: device, isSelected: device.id == selectedDevice?.id) {
                    onDeviceSelected(device)
                }
            }
            
            if let volumeControl = volumeControl {
                volumeControl()
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
            }
        }
    }
}

struct VolumeControl: View {
    @ObservedObject var audioManager: AudioManager
    
    var body: some View {
        VStack(spacing: 12) {
            if let outputDevice = audioManager.selectedOutputDevice {
                VolumeSlider(
                    icon: "speaker.wave.2.fill",
                    volume: Binding(
                        get: { audioManager.outputVolume },
                        set: { audioManager.setVolumeForDevice(device: outputDevice, volume: $0, isInput: false) }
                    )
                )
            }
            
            if let inputDevice = audioManager.selectedInputDevice {
                VolumeSlider(
                    icon: "mic.fill",
                    volume: Binding(
                        get: { audioManager.inputVolume },
                        set: { audioManager.setVolumeForDevice(device: inputDevice, volume: $0, isInput: true) }
                    )
                )
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }
}

struct VolumeSlider: View {
    let icon: String
    @Binding var volume: Float
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .frame(width: 16)
            
            Slider(value: $volume, in: 0...1)
                .controlSize(.small)
            
            Text("\(Int(volume * 100))%")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .frame(width: 35, alignment: .trailing)
        }
    }
}

struct SoundSettingsButton: View {
    var body: some View {
        Button(action: {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.sound") {
                NSWorkspace.shared.open(url)
            }
        }) {
            HStack {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                
                Text("Sound Settings...")
                    .font(.system(size: 14))
                
                Spacer()
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .buttonStyle(DeviceButtonStyle())
    }
}

struct QuitButton: View {
    var body: some View {
        Button(action: {
            NSApplication.shared.terminate(nil)
        }) {
            HStack {
                Image(systemName: "power")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                
                Text("Quit")
                    .font(.system(size: 14))
                
                Spacer()
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .buttonStyle(DeviceButtonStyle())
    }
}

struct DeviceButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? (colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.1)) : Color.clear)
    }
}

@available(macOS 13.0, *)
struct MenuBarView: View {
    @ObservedObject var audioManager = AudioManager.shared
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            DeviceSection(
                title: "Output Devices",
                devices: audioManager.outputDevices,
                selectedDevice: audioManager.selectedOutputDevice,
                onDeviceSelected: { device in
                    audioManager.setDefaultDevice(device, forInput: false)
                },
                volumeControl: audioManager.selectedOutputDevice.map { device in
                    {
                        VolumeSlider(
                            icon: "speaker.wave.2.fill",
                            volume: Binding(
                                get: { audioManager.outputVolume },
                                set: { audioManager.setVolumeForDevice(device: device, volume: $0, isInput: false) }
                            )
                        )
                    }
                }
            )
            
            if !audioManager.inputDevices.isEmpty {
                Divider()
                DeviceSection(
                    title: "Input Devices",
                    devices: audioManager.inputDevices,
                    selectedDevice: audioManager.selectedInputDevice,
                    onDeviceSelected: { device in
                        audioManager.setDefaultDevice(device, forInput: true)
                    },
                    volumeControl: audioManager.selectedInputDevice.map { device in
                        {
                            VolumeSlider(
                                icon: "mic.fill",
                                volume: Binding(
                                    get: { audioManager.inputVolume },
                                    set: { audioManager.setVolumeForDevice(device: device, volume: $0, isInput: true) }
                                )
                            )
                        }
                    }
                )
            }
            
            Divider()
            
            SoundSettingsButton()
            
            Divider()
            
            QuitButton()
        }
        .padding(.vertical, 5)
        .background {
            if colorScheme == .dark {
                Color.black.opacity(0.2)
            }
            Rectangle()
                .fill(.thinMaterial)
        }
        .cornerRadius(6)
    }
}