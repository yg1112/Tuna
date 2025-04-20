import SwiftUI

struct OutputDeviceSection: View {
    @EnvironmentObject var audioManager: AudioManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Output")
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            
            ForEach(audioManager.outputDevices) { device in
                DeviceCardView(
                    device: device,
                    isInput: false,
                    selectedDeviceID: .init(
                        get: { audioManager.selectedOutputDevice?.id ?? 0 },
                        set: { _ in }
                    )
                )
            }
        }
    }
}

struct InputDeviceSection: View {
    @EnvironmentObject var audioManager: AudioManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Input")
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            
            ForEach(audioManager.inputDevices) { device in
                DeviceCardView(
                    device: device,
                    isInput: true,
                    selectedDeviceID: .init(
                        get: { audioManager.selectedInputDevice?.id ?? 0 },
                        set: { _ in }
                    )
                )
            }
        }
    }
}

struct MenuDevicesView: View {
    @EnvironmentObject var audioManager: AudioManager
    
    var body: some View {
        VStack(spacing: 16) {
            OutputDeviceSection()
            
            Divider()
                .padding(.vertical, 8)
            
            InputDeviceSection()
        }
        .padding(.vertical)
    }
}

#Preview {
    MenuDevicesView()
        .environmentObject(AudioManager.shared)
} 