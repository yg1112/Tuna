import SwiftUI
import AppKit
import os.log

struct ModernToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            
            Spacer()
            
            ZStack {
                Capsule()
                    .fill(configuration.isOn ? Color.green : Color.gray.opacity(0.3))
                    .frame(width: 50, height: 28)
                
                Circle()
                    .fill(Color.white)
                    .shadow(radius: 1)
                    .frame(width: 24, height: 24)
                    .offset(x: configuration.isOn ? 12 : -12)
                    .animation(.spring(response: 0.2), value: configuration.isOn)
            }
            .onTapGesture {
                withAnimation {
                    configuration.isOn.toggle()
                }
            }
        }
    }
}

struct TunaSettingsView: View {
    @StateObject private var settings = TunaSettings.shared
    @StateObject private var audioManager = AudioManager.shared
    @State private var isProcessingLoginSetting = false
    @State private var selectedTranscriptionFormat = UserDefaults.standard.string(forKey: "dictationFormat") ?? "txt"
    @State private var selectedOutputDeviceUID = UserDefaults.standard.string(forKey: "defaultOutputDeviceUID") ?? ""
    @State private var selectedInputDeviceUID = UserDefaults.standard.string(forKey: "defaultInputDeviceUID") ?? ""
    @State private var isInitializing = true // 防止初始化过程中触发更新
    
    private let logger = Logger(subsystem: "com.tuna.app", category: "SettingsView")
    private let formats = ["txt", "srt", "vtt", "json"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Launch at Login Setting with Toggle
                HStack {
                    Text("Launch at Login")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // 使用Button替代Toggle，实现类似效果
                    Button(action: {
                        if !isProcessingLoginSetting {
                            toggleLoginItem()
                        }
                    }) {
                        ZStack {
                            Capsule()
                                .fill(settings.launchAtLogin ? Color.green : Color.gray.opacity(0.3))
                                .frame(width: 50, height: 28)
                            
                            Circle()
                                .fill(Color.white)
                                .shadow(radius: 1)
                                .frame(width: 24, height: 24)
                                .offset(x: settings.launchAtLogin ? 12 : -12)
                        }
                    }
                    .disabled(isProcessingLoginSetting)
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 15)
                .background(Color.black.opacity(0.3))
                .cornerRadius(12)
                
                // Transcription Settings
                VStack(alignment: .leading, spacing: 16) {
                    Text("Transcription Settings")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    
                    // File Format Selection
                    HStack {
                        Text("File Format:")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Picker("", selection: $selectedTranscriptionFormat) {
                            ForEach(formats, id: \.self) { format in
                                Text(format.uppercased()).tag(format)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 180)
                        .onChange(of: selectedTranscriptionFormat) { newValue in
                            // 只有当不在初始化过程中且值实际发生变化时才更新
                            if !isInitializing && newValue != settings.transcriptionFormat {
                                settings.transcriptionFormat = newValue
                            }
                        }
                    }
                    
                    // Output Directory Selection
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Save Location:")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Button(action: {
                                selectOutputDirectory()
                            }) {
                                Text("Change")
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 4)
                                    .background(Color(red: 0.0, green: 0.48, blue: 1.0))
                                    .cornerRadius(5)
                                    .font(.system(size: 13, weight: .regular))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        Text(settings.transcriptionOutputDirectory?.path ?? "Not Set")
                            .font(.system(size: 13))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 15)
                .background(Color.black.opacity(0.3))
                .cornerRadius(12)
                
                // Default Audio Devices
                VStack(alignment: .leading, spacing: 16) {
                    Text("Default Audio Devices")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    
                    // Default Output Device
                    HStack {
                        Text("Output Device:")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Picker("", selection: $selectedOutputDeviceUID) {
                            Text("Not Set").tag("")
                            ForEach(audioManager.outputDevices, id: \.uid) { device in
                                Text(device.name).tag(device.uid)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(width: 200)
                        .onChange(of: selectedOutputDeviceUID) { newValue in
                            // 只有当不在初始化过程中且值实际发生变化时才更新
                            if !isInitializing && newValue != settings.defaultOutputDeviceUID {
                                settings.defaultOutputDeviceUID = newValue
                                
                                // Apply setting immediately if device selected
                                if !newValue.isEmpty, let device = audioManager.outputDevices.first(where: { $0.uid == newValue }) {
                                    audioManager.setDefaultOutputDevice(device)
                                }
                            }
                        }
                    }
                    
                    // Default Input Device
                    HStack {
                        Text("Input Device:")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Picker("", selection: $selectedInputDeviceUID) {
                            Text("Not Set").tag("")
                            ForEach(audioManager.inputDevices, id: \.uid) { device in
                                Text(device.name).tag(device.uid)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(width: 200)
                        .onChange(of: selectedInputDeviceUID) { newValue in
                            // 只有当不在初始化过程中且值实际发生变化时才更新
                            if !isInitializing && newValue != settings.defaultInputDeviceUID {
                                settings.defaultInputDeviceUID = newValue
                                
                                // Apply setting immediately if device selected
                                if !newValue.isEmpty, let device = audioManager.inputDevices.first(where: { $0.uid == newValue }) {
                                    audioManager.setDefaultInputDevice(device)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 15)
                .background(Color.black.opacity(0.3))
                .cornerRadius(12)
                
                Spacer()
            }
            .padding(.top, 20)
            .frame(width: 400, height: 450)
            .padding(20)
            .background(Color(red: 0.12, green: 0.12, blue: 0.12))
            .onAppear {
                print("[VIEW] Settings view appeared")
                fflush(stdout)
                
                // 防止初始化触发循环更新
                isInitializing = true
                
                // Initialize picker values to match settings
                selectedTranscriptionFormat = settings.transcriptionFormat
                selectedOutputDeviceUID = settings.defaultOutputDeviceUID
                selectedInputDeviceUID = settings.defaultInputDeviceUID
                
                // 初始化完成后延迟将标志设为false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isInitializing = false
                }
            }
        }
    }
    
    private func toggleLoginItem() {
        // Prevent multiple clicks
        isProcessingLoginSetting = true
        
        print("[DEBUG] Toggling login item setting")
        
        // Set new state
        let newValue = !settings.launchAtLogin
        settings.launchAtLogin = newValue
        
        // Short delay to check result and update UI
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // Processing complete
            self.isProcessingLoginSetting = false
            
            print("[RESULT] Launch at login " + (newValue ? "enabled" : "disabled"))
            fflush(stdout)
        }
    }
    
    // Select transcription file save directory
    private func selectOutputDirectory() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.prompt = "Select"
        panel.title = "Select Output Directory for Transcriptions"
        
        // Find current active window
        if let window = NSApplication.shared.keyWindow ?? NSApplication.shared.mainWindow {
            panel.beginSheetModal(for: window) { response in
                if response == .OK, let url = panel.url {
                    DispatchQueue.main.async {
                        // Update settings
                        settings.transcriptionOutputDirectory = url
                        print("[SETTINGS] Transcription output directory set: \(url.path)")
                        fflush(stdout)
                    }
                }
            }
        } else {
            // If no current window found, use standard modal
            let response = panel.runModal()
            if response == .OK, let url = panel.url {
                DispatchQueue.main.async {
                    // Update settings
                    settings.transcriptionOutputDirectory = url
                    print("[SETTINGS] Transcription output directory set: \(url.path)")
                    fflush(stdout)
                }
            }
        }
    }
} 