import AppKit
import Combine
import Foundation
import SwiftUI
import TunaAudio
import TunaCore
import TunaSpeech
import TunaTypes
import TunaUI

struct ModeSettingsView: View {
    @StateObject private var modeManager = AudioModeManager.shared
    @StateObject private var audioManager = AudioManager.shared
    @State private var isAddingNewMode = false
    @State private var newModeName = ""
    @State private var selectedOutputUID = ""
    @State private var selectedInputUID = ""
    @State private var editingMode: AudioMode?
    @State private var deviceNames: [String: String] = [:]
    @State private var inputDevices: [any AudioDevice] = []
    @State private var outputDevices: [any AudioDevice] = []
    @State private var modes: [AudioMode] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Mode Settings")
                .font(.headline)
                .padding(.horizontal)

            Divider()

            // 模式列表
            List(selection: Binding(
                get: { self.modeManager.currentMode },
                set: { newMode in
                    if let newMode {
                        Task {
                            await self.handleModeSelection(newMode)
                        }
                    }
                }
            )) {
                ForEach(self.modes) { mode in
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

                        if mode.id == self.modeManager.currentModeID {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        Task {
                            await self.handleModeSelection(mode)
                        }
                    }
                }
            }
            .frame(height: 200)

            Divider()

            // 添加新模式按钮
            Button(action: {
                Task {
                    let inputDevice = await audioManager.selectedInputDevice
                    let outputDevice = await audioManager.selectedOutputDevice

                    Task { @MainActor in
                        self.newModeName = ""
                        self.selectedOutputUID = outputDevice?.uid ?? ""
                        self.selectedInputUID = inputDevice?.uid ?? ""
                        self.isAddingNewMode = true
                        self.editingMode = nil
                    }
                }
            }) {
                Label("Add Mode", systemImage: "plus")
            }

            Spacer()
        }
        .padding(.vertical)
        .sheet(isPresented: self.$isAddingNewMode) {
            self.modeEditorView(isNew: true)
        }
        .sheet(item: self.$editingMode) { mode in
            self.modeEditorView(isNew: false)
        }
        .onAppear {
            Task {
                await self.loadDevices()
                await self.loadModes()
            }
        }
    }

    private func loadDevices() async {
        let inputs = await audioManager.inputDevices
        let outputs = await audioManager.outputDevices

        Task { @MainActor in
            self.inputDevices = inputs
            self.outputDevices = outputs

            // Update device names
            var names: [String: String] = [:]
            for device in inputs + outputs {
                names[device.uid] = device.name
            }
            self.deviceNames = names
        }
    }

    private func loadModes() async {
        Task { @MainActor in
            self.modes = self.modeManager.modes
        }
    }

    private func handleModeSelection(_ mode: AudioMode) async {
        await self.modeManager.applyMode(mode)
    }

    private func getDeviceName(uid: String, isInput: Bool) -> String {
        if uid.isEmpty {
            return "None"
        }
        return self.deviceNames[uid] ?? "Unknown Device"
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
                    Task {
                        await self.handleModeEdit(
                            newMode: isNew ? self.createNewMode() : nil,
                            editingMode: self.editingMode
                        )
                    }
                }
                .keyboardShortcut(.return)
                .disabled(self.newModeName.isEmpty)
            }
            .padding()
        }
        .padding()
        .frame(width: 400, height: 400)
    }

    @ViewBuilder
    private func devicePicker(for isInput: Bool, selection: Binding<String>) -> some View {
        let devices = isInput ? self.inputDevices : self.outputDevices
        Picker("Select Device", selection: selection) {
            ForEach(devices, id: \.uid) { device in
                Text(device.name).tag(device.uid)
            }
        }
    }

    private func createNewMode() async -> AudioMode {
        let outputDevice = self.outputDevices.first(where: { $0.uid == self.selectedOutputUID })
        let inputDevice = self.inputDevices.first(where: { $0.uid == self.selectedInputUID })
        let outputVolume = outputDevice?.getVolume() ?? 0.5
        let inputVolume = inputDevice?.getVolume() ?? 0.5
        return self.modeManager.createCustomMode(
            name: self.newModeName,
            outputDeviceUID: self.selectedOutputUID,
            inputDeviceUID: self.selectedInputUID,
            outputVolume: outputVolume,
            inputVolume: inputVolume
        )
    }

    private func handleModeEdit(newMode: AudioMode?, editingMode: AudioMode?) async {
        if let newMode {
            await self.handleModeSelection(newMode)
        } else if let mode = editingMode {
            var updatedMode = mode
            updatedMode.name = self.newModeName
            updatedMode.outputDeviceUID = self.selectedOutputUID
            updatedMode.inputDeviceUID = self.selectedInputUID
            self.modeManager.updateMode(updatedMode)
        }
        self.isAddingNewMode = false
        self.editingMode = nil
    }
}
