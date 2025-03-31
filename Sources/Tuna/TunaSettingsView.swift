import SwiftUI

struct SystemToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: { configuration.isOn.toggle() }) {
            RoundedRectangle(cornerRadius: 16)
                .fill(configuration.isOn ? Color.accentColor : Color(NSColor.controlColor))
                .frame(width: 36, height: 20)
                .overlay(
                    Circle()
                        .fill(Color.white)
                        .shadow(radius: 1)
                        .frame(width: 18, height: 18)
                        .offset(x: configuration.isOn ? 8 : -8)
                        .animation(.spring(response: 0.2), value: configuration.isOn)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TunaSettingsView: View {
    @StateObject private var audioManager = AudioManager.shared
    @StateObject private var settings = TunaSettings.shared
    
    private var uniqueOutputDevices: [AudioDevice] {
        // 使用 Dictionary 的方式去重，保留最新的设备状态
        var devices: [String: AudioDevice] = [:]
        // 先添加当前可用设备
        for device in audioManager.outputDevices {
            var updatedDevice = device
            updatedDevice.isDefault = true  // 标记为当前可用
            devices[device.uid] = updatedDevice
        }
        // 再添加历史设备（如果没有被当前设备覆盖）
        for device in audioManager.historicalOutputDevices {
            if devices[device.uid] == nil {
                var updatedDevice = device
                updatedDevice.isDefault = false  // 标记为历史设备
                devices[device.uid] = updatedDevice
            }
        }
        return Array(devices.values).sorted { $0.name < $1.name }
    }
    
    private var uniqueInputDevices: [AudioDevice] {
        var devices: [String: AudioDevice] = [:]
        for device in audioManager.inputDevices {
            var updatedDevice = device
            updatedDevice.isDefault = true
            devices[device.uid] = updatedDevice
        }
        for device in audioManager.historicalInputDevices {
            if devices[device.uid] == nil {
                var updatedDevice = device
                updatedDevice.isDefault = false
                devices[device.uid] = updatedDevice
            }
        }
        return Array(devices.values).sorted { $0.name < $1.name }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Launch at Login with system settings style
            HStack {
                Text("Launch at Login")
                    .foregroundColor(.primary)
                Spacer()
                Toggle("", isOn: $settings.launchAtLogin)
                    .toggleStyle(SystemToggleStyle())
                    .labelsHidden()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
            
            GroupBox {
                VStack(alignment: .leading, spacing: 15) {
                    // Output Device
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Default Output Device")
                            .fontWeight(.medium)
                        Picker("", selection: $settings.preferredOutputDeviceUID) {
                            Text("None").tag("")
                            ForEach(uniqueOutputDevices) { device in
                                HStack {
                                    Image(systemName: "speaker.wave.2")
                                        .foregroundColor(device.isDefault ? .primary : .secondary)
                                    Text(device.name)
                                        .foregroundColor(.primary)  // 设备名称始终使用正常颜色
                                    if !device.isDefault {  // 使用 isDefault 判断设备是否可用
                                        Text("(Unavailable)")
                                            .foregroundColor(.secondary)
                                            .italic()
                                    }
                                }
                                .tag(device.uid)
                            }
                        }
                        .labelsHidden()
                    }
                    
                    Divider()
                    
                    // Input Device
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Default Input Device")
                            .fontWeight(.medium)
                        Picker("", selection: $settings.preferredInputDeviceUID) {
                            Text("None").tag("")
                            ForEach(uniqueInputDevices) { device in
                                HStack {
                                    Image(systemName: "mic")
                                        .foregroundColor(device.isDefault ? .primary : .secondary)
                                    Text(device.name)
                                        .foregroundColor(.primary)  // 设备名称始终使用正常颜色
                                    if !device.isDefault {  // 使用 isDefault 判断设备是否可用
                                        Text("(Unavailable)")
                                            .foregroundColor(.secondary)
                                            .italic()
                                    }
                                }
                                .tag(device.uid)
                            }
                        }
                        .labelsHidden()
                    }
                }
                .padding()
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding(.vertical)
        .frame(minWidth: 400, minHeight: 300)
        .onChange(of: settings.launchAtLogin) { newValue in
            print("开机自启动状态更改为: \(newValue)")
        }
        .onChange(of: settings.preferredOutputDeviceUID) { newValue in
            print("设置优先输出设备: \(newValue)")
        }
        .onChange(of: settings.preferredInputDeviceUID) { newValue in
            print("设置优先输入设备: \(newValue)")
        }
    }
} 