import Combine
import CoreAudio
import Foundation
import os.log
import SwiftUI
import TunaAudio
import TunaTypes

/// Manages audio modes in the application
public class AudioModeManager: ObservableObject {
    public static let shared = AudioModeManager()

    private let logger = Logger(subsystem: "com.tuna.app", category: "AudioModeManager")
    private let audioManager = AudioManager.shared
    private var cancellables = Set<AnyCancellable>()

    /// All available audio modes
    @Published public var modes: [AudioMode] = []

    /// Currently selected mode ID
    @Published public var currentModeID: String? {
        didSet {
            if let modeID = currentModeID {
                UserDefaults.standard.set(modeID, forKey: "currentModeID")
                self.logger.debug("Saved current mode ID: \(modeID)")

                // Apply current mode settings
                if let mode = getMode(byID: modeID) {
                    self.applyMode(mode)
                }
            } else {
                UserDefaults.standard.removeObject(forKey: "currentModeID")
                self.logger.debug("Cleared current mode ID")
            }
        }
    }

    private init() {
        self.logger.debug("Initializing AudioModeManager")
        self.loadModes()

        // Load last used mode ID
        if let savedModeID = UserDefaults.standard.string(forKey: "currentModeID") {
            self.currentModeID = savedModeID
            self.logger.debug("Loaded last used mode ID: \(savedModeID)")
        }

        // Monitor device changes for potential automatic mode updates
        NotificationCenter.default.publisher(for: NSNotification.Name("audioDevicesChanged"))
            .sink { [weak self] _ in
                self?.checkForAutomaticModeSwitch()
            }
            .store(in: &self.cancellables)
    }

    /// Load saved audio modes
    private func loadModes() {
        if let data = UserDefaults.standard.data(forKey: "audioModes") {
            do {
                let decoder = JSONDecoder()
                self.modes = try decoder.decode([AudioMode].self, from: data)
                self.logger.debug("Loaded \(self.modes.count) audio modes")

                // Ensure at least one "automatic" mode exists
                if !self.modes.contains(where: \.isAutomatic) {
                    self.createDefaultModes()
                }
            } catch {
                self.logger.error("Failed to load audio modes: \(error.localizedDescription)")
                self.createDefaultModes()
            }
        } else {
            self.createDefaultModes()
        }
    }

    /// Create default audio modes
    private func createDefaultModes() {
        self.logger.debug("Creating default audio modes")

        // Create modes based on current devices
        var newModes: [AudioMode] = []

        // Add automatic mode
        let automaticMode = AudioMode(
            id: "automatic",
            name: "Automatic",
            outputDeviceUID: audioManager.selectedOutputDevice?.uid ?? "",
            inputDeviceUID: self.audioManager.selectedInputDevice?.uid ?? "",
            outputVolume: 0.5,
            inputVolume: 0.5,
            isAutomatic: true
        )
        newModes.append(automaticMode)

        // Meeting mode (if MacBook speakers and mic available)
        if let macbookSpeaker = audioManager.outputDevices
            .first(where: { $0.name.contains("MacBook") }),
            let defaultMic = audioManager.inputDevices.first
        {
            let meetingMode = AudioMode(
                name: "Meeting",
                outputDeviceUID: macbookSpeaker.uid,
                inputDeviceUID: defaultMic.uid,
                outputVolume: 0.5,
                inputVolume: 0.5
            )
            newModes.append(meetingMode)
        }

        // Study mode (if headphones or AirPods available)
        if let headphones = audioManager.outputDevices.first(where: {
            $0.name.contains("AirPods") ||
                $0.name.contains("Headphones")
        }) {
            let studyMode = AudioMode(
                name: "Study",
                outputDeviceUID: headphones.uid,
                inputDeviceUID: headphones.uid,
                outputVolume: 0.5,
                inputVolume: 0.5
            )
            newModes.append(studyMode)
        }

        // Entertainment mode (if external speakers available)
        if let externalSpeaker = audioManager.outputDevices.first(where: {
            !$0.name.contains("MacBook") &&
                !$0.name.contains("AirPods") &&
                !$0.name.contains("Headphones")
        }) {
            let entertainmentMode = AudioMode(
                name: "Entertainment",
                outputDeviceUID: externalSpeaker.uid,
                inputDeviceUID: "",
                outputVolume: 0.7
            )
            newModes.append(entertainmentMode)
        }

        self.modes = newModes
        self.saveModes()

        // Default to automatic mode
        self.currentModeID = "automatic"
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
    public func addMode(_ mode: AudioMode) {
        self.modes.append(mode)
        self.saveModes()
        self.logger.debug("Added new audio mode: \(mode.name)")
    }

    /// Update an existing audio mode
    public func updateMode(_ mode: AudioMode) {
        if let index = modes.firstIndex(where: { $0.id == mode.id }) {
            self.modes[index] = mode
            self.saveModes()
            self.logger.debug("Updated audio mode: \(mode.name)")

            // If updating current mode, reapply settings
            if mode.id == self.currentModeID {
                self.applyMode(mode)
            }
        }
    }

    /// Delete an audio mode
    public func deleteMode(withID id: String) {
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
    public func applyMode(_ mode: AudioMode) {
        self.logger.debug("Applying audio mode: \(mode.name)")

        // Set output device and volume
        if !mode.outputDeviceUID.isEmpty,
           let device = audioManager.outputDevices.first(where: { $0.uid == mode.outputDeviceUID })
        {
            self.audioManager.selectOutputDevice(device)
            if let volume = mode.outputVolume {
                self.audioManager.setVolumeForDevice(
                    device: device,
                    volume: volume,
                    isInput: false
                )
                self.logger.debug("Set output device: \(device.name), volume: \(volume)")
            } else {
                self.logger.debug("Set output device: \(device.name), using default volume")
            }
        } else {
            self.logger.warning("Output device not found: \(mode.outputDeviceUID)")
        }

        // Set input device and volume
        if !mode.inputDeviceUID.isEmpty,
           let device = audioManager.inputDevices.first(where: { $0.uid == mode.inputDeviceUID })
        {
            self.audioManager.selectInputDevice(device)
            if let volume = mode.inputVolume {
                self.audioManager.setVolumeForDevice(
                    device: device,
                    volume: volume,
                    isInput: true
                )
                self.logger.debug("Set input device: \(device.name), volume: \(volume)")
            } else {
                self.logger.debug("Set input device: \(device.name), using default volume")
            }
        } else {
            self.logger.warning("Input device not found: \(mode.inputDeviceUID)")
        }
    }

    /// Check for automatic mode switch based on device changes
    private func checkForAutomaticModeSwitch() {
        // Only proceed if we have an automatic mode
        guard let automaticMode = self.modes.first(where: { $0.isAutomatic }) else {
            return
        }

        // Update automatic mode with current devices
        var updatedMode = automaticMode
        updatedMode.outputDeviceUID = self.audioManager.selectedOutputDevice?.uid ?? ""
        updatedMode.inputDeviceUID = self.audioManager.selectedInputDevice?.uid ?? ""

        // Update the mode
        self.updateMode(updatedMode)

        // If we're in automatic mode, apply the updated settings
        if self.currentModeID == automaticMode.id {
            self.applyMode(updatedMode)
        }
    }

    /// Create a new audio mode with the given settings
    public func createMode(
        name: String,
        outputDeviceUID: String,
        inputDeviceUID: String,
        outputVolume: Float,
        inputVolume: Float
    ) -> AudioMode {
        let newMode = AudioMode(
            name: name,
            outputDeviceUID: outputDeviceUID,
            inputDeviceUID: inputDeviceUID,
            outputVolume: outputVolume,
            inputVolume: inputVolume
        )
        self.addMode(newMode)
        return newMode
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
            outputDeviceUID: outputDeviceUID,
            inputDeviceUID: inputDeviceUID,
            outputVolume: outputVolume,
            inputVolume: inputVolume
        )
        self.addMode(mode)
        return mode
    }

    /// Update volumes for current mode
    public func updateCurrentModeVolumes() {
        guard let currentMode = self.modes.first(where: { $0.id == self.currentModeID })
        else { return }

        // Get current volumes
        let outputVolume = self.audioManager.selectedOutputDevice?.getVolume() ?? 0.5
        let inputVolume = self.audioManager.selectedInputDevice?.getVolume() ?? 0.5

        // Create updated mode
        let updatedMode = AudioMode(
            id: currentMode.id,
            name: currentMode.name,
            outputDeviceUID: currentMode.outputDeviceUID,
            inputDeviceUID: currentMode.inputDeviceUID,
            outputVolume: outputVolume,
            inputVolume: inputVolume,
            isAutomatic: currentMode.isAutomatic
        )

        // Update mode
        self.updateMode(updatedMode)
    }
}

// --------------------------------------------------
// [Cursor AI] Add missing DeviceSelectionInfo for the new UI
public struct DeviceSelectionInfo {
    public let device: AudioDevice
    public let isInput: Bool

    public init(device: AudioDevice, isInput: Bool) {
        self.device = device
        self.isInput = isInput
    }
}
