import Combine
import CoreAudio
import Foundation
import os.log
import SwiftUI
import TunaAudio
import TunaTypes

/// Manages audio modes in the application
@MainActor
public class AudioModeManager: ObservableObject {
    public static let shared = AudioModeManager()

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: "AudioModeManager"
    )
    private var audioManager: AudioManagerProtocol?
    private var cancellables = Set<AnyCancellable>()

    /// All available audio modes
    @Published public private(set) var modes: [AudioMode] = []

    /// Currently selected mode ID
    @Published public private(set) var currentModeID: String = "automatic"

    /// Currently selected mode
    @Published public private(set) var selectedMode: AudioMode?

    @Published public var currentMode: AudioMode?

    public init(audioManager: AudioManagerProtocol? = nil) {
        self.audioManager = audioManager
        Task { @MainActor in
            if self.audioManager == nil {
                self.audioManager = AudioManager.shared
            }
            await self.loadModes()
        }
    }

    /// Create default audio modes
    private func createDefaultModes() async {
        self.logger.debug("Creating default audio modes")

        // Automatic mode (uses system defaults)
        let automaticMode = await AudioMode(
            id: "automatic",
            name: "Automatic",
            inputVolume: 0.5,
            outputVolume: 0.5,
            isActive: false,
            outputDeviceUID: audioManager?.selectedOutputDevice?.uid ?? "",
            inputDeviceUID: self.audioManager?.selectedInputDevice?.uid ?? "",
            isAutomatic: true
        )
        self.modes.append(automaticMode)

        // Meeting mode (if MacBook speakers and mic available)
        if let macbookSpeaker = await audioManager?.outputDevices
            .first(where: { $0.name.contains("MacBook") }),
            let defaultMic = await audioManager?.inputDevices.first
        {
            let meetingMode = AudioMode(
                id: "meeting",
                name: "Meeting",
                inputVolume: 0.8,
                outputVolume: 0.7,
                isActive: false,
                outputDeviceUID: macbookSpeaker.uid,
                inputDeviceUID: defaultMic.uid
            )
            self.modes.append(meetingMode)
        }

        // Study mode (if headphones or AirPods available)
        if let headphones = await audioManager?.outputDevices.first(where: {
            $0.name.contains("AirPods") ||
                $0.name.contains("Headphones")
        }) {
            let studyMode = AudioMode(
                id: "study",
                name: "Study",
                inputVolume: 0.0,
                outputVolume: 0.6,
                isActive: false,
                outputDeviceUID: headphones.uid,
                inputDeviceUID: ""
            )
            self.modes.append(studyMode)
        }

        // Entertainment mode (if external speakers available)
        if let externalSpeaker = await audioManager?.outputDevices.first(where: {
            !$0.name.contains("MacBook") &&
                !$0.name.contains("AirPods") &&
                !$0.name.contains("Headphones")
        }) {
            let entertainmentMode = AudioMode(
                id: "entertainment",
                name: "Entertainment",
                inputVolume: 0.0,
                outputVolume: 0.8,
                isActive: false,
                outputDeviceUID: externalSpeaker.uid,
                inputDeviceUID: ""
            )
            self.modes.append(entertainmentMode)
        }

        // Select automatic mode by default
        if let automaticMode = self.modes.first(where: { $0.isAutomatic }) {
            self.selectedMode = automaticMode
        }

        self.logger.debug("Created \(self.modes.count) audio modes")
    }

    /// Setup observers for device changes
    private func setupDeviceChangeObservers() async {
        NotificationCenter.default.publisher(for: .audioDevicesChanged)
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    await self?.checkForAutomaticModeSwitch()
                }
            }
            .store(in: &self.cancellables)

        NotificationCenter.default.publisher(for: .audioDeviceDefaultChanged)
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    await self?.checkForAutomaticModeSwitch()
                }
            }
            .store(in: &self.cancellables)
    }

    /// Save audio modes
    private func saveModes() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(self.modes)
            UserDefaults.standard.set(data, forKey: "audioModes")
            self.logger.debug("Saved \(self.modes.count) audio modes")
        } catch {
            self.logger.error("Failed to save audio modes: \(error.localizedDescription)")
        }
    }

    /// Add a new audio mode
    @MainActor public func addMode(_ mode: AudioMode) {
        self.modes.append(mode)
        self.saveModes()
        self.logger.debug("Added new audio mode: \(mode.name)")
    }

    /// Update an existing audio mode
    @MainActor public func updateMode(_ mode: AudioMode) {
        if let index = modes.firstIndex(where: { $0.id == mode.id }) {
            self.modes[index] = mode
            self.saveModes()
            self.logger.debug("Updated audio mode: \(mode.name)")

            // If updating current mode, reapply settings
            if mode.id == self.currentModeID {
                Task {
                    await self.applyMode(mode)
                }
            }
        }
    }

    /// Delete an audio mode
    @MainActor public func deleteMode(withID id: String) {
        // Don't allow deleting automatic mode
        if id == "automatic" {
            self.logger.warning("Attempt to delete automatic mode rejected")
            return
        }

        self.modes.removeAll { $0.id == id }
        self.saveModes()
        self.logger.debug("Deleted audio mode ID: \(id)")

        // If deleting current mode, switch to automatic mode
        if id == self.currentModeID {
            self.currentModeID = "automatic"
        }
    }

    /// Get audio mode by ID
    public func getMode(byID id: String) -> AudioMode? {
        self.modes.first { $0.id == id }
    }

    /// Apply audio mode settings
    @MainActor public func applyMode(_ mode: AudioMode) async {
        self.logger.debug("Applying audio mode: \(mode.name)")

        // Set output device and volume
        if let device = await self.audioManager?.outputDevices
            .first(where: { $0.uid == mode.outputDeviceUID })
        {
            await self.audioManager?.selectOutputDevice(device)
            await self.audioManager?.setVolumeForDevice(device, volume: mode.outputVolume)
            self.logger.debug("Set output device: \(device.name) with volume: \(mode.outputVolume)")
        } else {
            self.logger.warning("Output device not found: \(mode.outputDeviceUID ?? "")")
        }

        // Set input device and volume
        if let device = await self.audioManager?.inputDevices
            .first(where: { $0.uid == mode.inputDeviceUID })
        {
            await self.audioManager?.selectInputDevice(device)
            await self.audioManager?.setVolumeForDevice(device, volume: mode.inputVolume)
            self.logger.debug("Set input device: \(device.name) with volume: \(mode.inputVolume)")
        } else {
            self.logger.warning("Input device not found: \(mode.inputDeviceUID ?? "")")
        }

        // Update current mode ID
        self.currentModeID = mode.id

        // Update selected mode
        self.selectedMode = mode
        self.logger.debug("Audio mode applied: \(mode.name)")
    }

    /// Check for automatic mode switch based on device changes
    private func checkForAutomaticModeSwitch() async {
        // Only proceed if we have an automatic mode
        guard let automaticMode = self.modes.first(where: { $0.isAutomatic }) else {
            return
        }

        // Update automatic mode with current devices
        var updatedMode = automaticMode
        updatedMode.outputDeviceUID = await self.audioManager?.selectedOutputDevice?.uid ?? ""
        updatedMode.inputDeviceUID = await self.audioManager?.selectedInputDevice?.uid ?? ""

        // Update the mode
        if let index = self.modes.firstIndex(where: { $0.id == automaticMode.id }) {
            self.modes[index] = updatedMode
        }

        // If automatic mode is selected, apply the updates
        if self.selectedMode?.id == automaticMode.id {
            await self.applyMode(updatedMode)
        }
    }

    /// Create a new audio mode with the given settings
    public func createMode(
        id: String = UUID().uuidString,
        name: String,
        isAutomatic: Bool = false
    ) async -> AudioMode {
        self.logger.debug("Creating new audio mode: \(name)")

        // Get current volumes
        let outputVolume = await self.audioManager?.selectedOutputDevice?.getVolume() ?? 0.5
        let inputVolume = await self.audioManager?.selectedInputDevice?.getVolume() ?? 0.5

        // Create updated mode
        let mode = await AudioMode(
            id: id,
            name: name,
            inputVolume: inputVolume,
            outputVolume: outputVolume,
            isActive: false,
            outputDeviceUID: self.audioManager?.selectedOutputDevice?.uid ?? "",
            inputDeviceUID: self.audioManager?.selectedInputDevice?.uid ?? "",
            isAutomatic: isAutomatic
        )

        // Add to modes list
        self.modes.append(mode)

        return mode
    }

    /// Create a custom audio mode
    public func createCustomMode(
        name: String,
        outputDeviceUID: String,
        inputDeviceUID: String,
        outputVolume: Float = 0.5,
        inputVolume: Float = 0.5
    ) -> AudioMode {
        let mode = AudioMode(
            name: name,
            inputVolume: inputVolume,
            outputVolume: outputVolume,
            isActive: false,
            outputDeviceUID: outputDeviceUID,
            inputDeviceUID: inputDeviceUID
        )
        self.addMode(mode)
        return mode
    }

    /// Update volumes for current mode
    public func updateCurrentModeVolumes() async {
        guard let currentMode = self.modes.first(where: { $0.id == self.currentModeID })
        else { return }

        // Get current volumes
        let outputVolume = await self.audioManager?.selectedOutputDevice?.getVolume() ?? 0.5
        let inputVolume = await self.audioManager?.selectedInputDevice?.getVolume() ?? 0.5

        // Create updated mode
        var updatedMode = currentMode
        updatedMode.outputVolume = outputVolume
        updatedMode.inputVolume = inputVolume

        // Update the mode in the array
        if let index = self.modes.firstIndex(where: { $0.id == currentMode.id }) {
            self.modes[index] = updatedMode
        }
    }

    private func loadModes() async {
        // 从 UserDefaults 加载保存的模式
        if let data = UserDefaults.standard.data(forKey: "audioModes") {
            do {
                let decoder = JSONDecoder()
                let savedModes = try decoder.decode([AudioMode].self, from: data)
                self.modes = savedModes
                self.logger.debug("Loaded \(savedModes.count) saved audio modes")

                // 如果没有自动模式，创建一个
                if !savedModes.contains(where: \.isAutomatic) {
                    await self.createDefaultModes()
                }

                // 加载上次选择的模式
                if let lastModeID = UserDefaults.standard.string(forKey: "lastSelectedModeID"),
                   let lastMode = self.modes.first(where: { $0.id == lastModeID })
                {
                    await self.applyMode(lastMode)
                } else if let automaticMode = self.modes.first(where: { $0.isAutomatic }) {
                    await self.applyMode(automaticMode)
                }
            } catch {
                self.logger.error("Failed to load saved audio modes: \(error.localizedDescription)")
                await self.createDefaultModes()
            }
        } else {
            // 如果没有保存的模式，创建默认模式
            await self.createDefaultModes()
        }

        // 设置设备变更观察者
        await self.setupDeviceChangeObservers()
    }
}

// --------------------------------------------------
// [Cursor AI] Add missing DeviceSelectionInfo for the new UI
public struct DeviceSelectionInfo {
    public let device: any AudioDevice
    public let isInput: Bool

    public init(device: any AudioDevice, isInput: Bool) {
        self.device = device
        self.isInput = isInput
    }
}
