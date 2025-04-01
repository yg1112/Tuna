import SwiftUI

struct ModeSettingsView: View {
    @StateObject private var modeManager = AudioModeManager.shared
    @StateObject private var audioManager = AudioManager.shared
    @State private var isAddingNewMode = false
    @State private var newModeName = ""
    @State private var selectedOutputUID = ""
    @State private var selectedInputUID = ""
    @State private var editingMode: AudioMode?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Mode Settings")
                .font(.headline)
                .padding(.horizontal)
            
            Divider()
            
            // 模式列表
            List {
                ForEach(modeManager.modes) { mode in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(mode.name)
                                .fontWeight(mode.id == modeManager.currentModeID ? .bold : .regular)
                            
                            if !mode.outputDeviceUID.isEmpty {
                                HStack {
                                    Image(systemName: "speaker.wave.2")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(getDeviceName(uid: mode.outputDeviceUID, isInput: false))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            if !mode.inputDeviceUID.isEmpty {
                                HStack {
                                    Image(systemName: "mic")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(getDeviceName(uid: mode.inputDeviceUID, isInput: true))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        // 编辑按钮
                        Button(action: {
                            editingMode = mode
                            selectedOutputUID = mode.outputDeviceUID
                            selectedInputUID = mode.inputDeviceUID
                            newModeName = mode.name
                        }) {
                            Image(systemName: "pencil")
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        .disabled(mode.isAutomatic) // 不允许编辑自动模式
                        
                        // 删除按钮
                        Button(action: {
                            modeManager.deleteMode(withID: mode.id)
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        .disabled(mode.isAutomatic) // 不允许删除自动模式
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        modeManager.currentModeID = mode.id
                    }
                }
            }
            .frame(minHeight: 200)
            
            Divider()
            
            // 添加新模式按钮
            Button(action: {
                newModeName = ""
                selectedOutputUID = audioManager.selectedOutputDevice?.uid ?? ""
                selectedInputUID = audioManager.selectedInputDevice?.uid ?? ""
                isAddingNewMode = true
                editingMode = nil
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add New Mode")
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 8)
            
            Spacer()
        }
        .padding(.vertical)
        .sheet(isPresented: $isAddingNewMode) {
            modeEditorView(isNew: true)
        }
        .sheet(item: $editingMode) { mode in
            modeEditorView(isNew: false)
        }
    }
    
    private func modeEditorView(isNew: Bool) -> some View {
        VStack(spacing: 20) {
            Text(isNew ? "Add New Mode" : "Edit Mode")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Mode Name")
                    .fontWeight(.medium)
                TextField("Enter mode name", text: $newModeName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Output Device")
                    .fontWeight(.medium)
                devicePicker(for: false, selection: $selectedOutputUID)
            }
            .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Input Device")
                    .fontWeight(.medium)
                devicePicker(for: true, selection: $selectedInputUID)
            }
            .padding(.horizontal)
            
            HStack {
                Button("Cancel") {
                    isAddingNewMode = false
                    editingMode = nil
                }
                .keyboardShortcut(.escape)
                
                Spacer()
                
                Button(isNew ? "Add" : "Save") {
                    if isNew {
                        // 添加新模式
                        let outputVolume = audioManager.findDevice(byUID: selectedOutputUID, isInput: false)?.getVolume() ?? 0.5
                        let inputVolume = audioManager.findDevice(byUID: selectedInputUID, isInput: true)?.getVolume() ?? 0.5
                        
                        let newMode = modeManager.createCustomMode(
                            name: newModeName,
                            outputDeviceUID: selectedOutputUID,
                            inputDeviceUID: selectedInputUID,
                            outputVolume: outputVolume,
                            inputVolume: inputVolume
                        )
                        
                        // 自动切换到新模式
                        modeManager.currentModeID = newMode.id
                    } else if let mode = editingMode {
                        // 更新现有模式
                        var updatedMode = mode
                        updatedMode.name = newModeName
                        updatedMode.outputDeviceUID = selectedOutputUID
                        updatedMode.inputDeviceUID = selectedInputUID
                        
                        modeManager.updateMode(updatedMode)
                    }
                    
                    isAddingNewMode = false
                    editingMode = nil
                }
                .keyboardShortcut(.return)
                .disabled(newModeName.isEmpty)
            }
            .padding()
        }
        .padding()
        .frame(width: 400, height: 400)
    }
    
    private func devicePicker(for isInput: Bool, selection: Binding<String>) -> some View {
        let devices = isInput ? audioManager.inputDevices : audioManager.outputDevices
        let historicalDevices = isInput ? audioManager.historicalInputDevices : audioManager.historicalOutputDevices
        
        return Picker("", selection: selection) {
            Text("None").tag("")
            
            if !devices.isEmpty {
                Section(header: Text("Available Devices")) {
                    ForEach(devices) { device in
                        Text(device.name).tag(device.uid)
                    }
                }
            }
            
            if !historicalDevices.isEmpty {
                Section(header: Text("Historical Devices")) {
                    ForEach(historicalDevices) { device in
                        if !devices.contains(where: { $0.uid == device.uid }) {
                            Text("\(device.name) (Unavailable)").tag(device.uid)
                        }
                    }
                }
            }
        }
        .pickerStyle(DefaultPickerStyle())
        .labelsHidden()
    }
    
    private func getDeviceName(uid: String, isInput: Bool) -> String {
        if uid.isEmpty {
            return "None"
        }
        
        if let device = audioManager.findDevice(byUID: uid, isInput: isInput) {
            return device.name
        }
        
        return "Unknown Device"
    }
} 