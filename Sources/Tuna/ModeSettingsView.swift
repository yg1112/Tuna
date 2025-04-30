import SwiftUI
import TunaCore

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
                ForEach(self.modeManager.modes) { mode in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(mode.name)
                                .fontWeight(
                                    mode.id == self.modeManager
                                        .currentModeID ? .bold : .regular
                                )

                            if !mode.outputDeviceUID.isEmpty {
                                HStack {
                                    Image(systemName: "speaker.wave.2")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(self.getDeviceName(
                                        uid: mode.outputDeviceUID,
                                        isInput: false
                                    ))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                }
                            }

                            if !mode.inputDeviceUID.isEmpty {
                                HStack {
                                    Image(systemName: "mic")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(self.getDeviceName(
                                        uid: mode.inputDeviceUID,
                                        isInput: true
                                    ))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                }
                            }
                        }

                        Spacer()

                        // 编辑按钮
                        Button(action: {
                            self.editingMode = mode
                            self.selectedOutputUID = mode.outputDeviceUID
                            self.selectedInputUID = mode.inputDeviceUID
                            self.newModeName = mode.name
                        }) {
                            Image(systemName: "pencil")
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        .disabled(mode.isAutomatic) // 不允许编辑自动模式

                        // 删除按钮
                        Button(action: {
                            self.modeManager.deleteMode(withID: mode.id)
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        .disabled(mode.isAutomatic) // 不允许删除自动模式
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        self.modeManager.currentModeID = mode.id
                    }
                }
            }
            .frame(minHeight: 200)

            Divider()

            // 添加新模式按钮
            Button(action: {
                self.newModeName = ""
                self.selectedOutputUID = self.audioManager.selectedOutputDevice?.uid ?? ""
                self.selectedInputUID = self.audioManager.selectedInputDevice?.uid ?? ""
                self.isAddingNewMode = true
                self.editingMode = nil
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
        .sheet(isPresented: self.$isAddingNewMode) {
            self.modeEditorView(isNew: true)
        }
        .sheet(item: self.$editingMode) { mode in
            self.modeEditorView(isNew: false)
        }
    }

    private func modeEditorView(isNew: Bool) -> some View {
        VStack(spacing: 20) {
            Text(isNew ? "Add New Mode" : "Edit Mode")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Text("Mode Name")
                    .fontWeight(.medium)
                TextField("Enter mode name", text: self.$newModeName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding(.horizontal)

            VStack(alignment: .leading, spacing: 8) {
                Text("Output Device")
                    .fontWeight(.medium)
                self.devicePicker(for: false, selection: self.$selectedOutputUID)
            }
            .padding(.horizontal)

            VStack(alignment: .leading, spacing: 8) {
                Text("Input Device")
                    .fontWeight(.medium)
                self.devicePicker(for: true, selection: self.$selectedInputUID)
            }
            .padding(.horizontal)

            HStack {
                Button("Cancel") {
                    self.isAddingNewMode = false
                    self.editingMode = nil
                }
                .keyboardShortcut(.escape)

                Spacer()

                Button(isNew ? "Add" : "Save") {
                    if isNew {
                        // 添加新模式
                        let outputVolume = self.audioManager.findDevice(
                            byUID: self.selectedOutputUID,
                            isInput: false
                        )?.getVolume() ?? 0.5
                        let inputVolume = self.audioManager.findDevice(
                            byUID: self.selectedInputUID,
                            isInput: true
                        )?.getVolume() ?? 0.5

                        let newMode = self.modeManager.createCustomMode(
                            name: self.newModeName,
                            outputDeviceUID: self.selectedOutputUID,
                            inputDeviceUID: self.selectedInputUID,
                            outputVolume: outputVolume,
                            inputVolume: inputVolume
                        )

                        // 自动切换到新模式
                        self.modeManager.currentModeID = newMode.id
                    } else if let mode = editingMode {
                        // 更新现有模式
                        var updatedMode = mode
                        updatedMode.name = self.newModeName
                        updatedMode.outputDeviceUID = self.selectedOutputUID
                        updatedMode.inputDeviceUID = self.selectedInputUID

                        self.modeManager.updateMode(updatedMode)
                    }

                    self.isAddingNewMode = false
                    self.editingMode = nil
                }
                .keyboardShortcut(.return)
                .disabled(self.newModeName.isEmpty)
            }
            .padding()
        }
        .padding()
        .frame(width: 400, height: 400)
    }

    private func devicePicker(for isInput: Bool, selection: Binding<String>) -> some View {
        let devices = isInput ? self.audioManager.inputDevices : self.audioManager.outputDevices
        let historicalDevices = isInput ? self.audioManager.historicalInputDevices : self
            .audioManager
            .historicalOutputDevices

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
