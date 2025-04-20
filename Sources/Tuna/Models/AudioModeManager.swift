import Combine
import CoreAudio
import Foundation
import os.log
import SwiftUI

/// Manages audio modes in the application
class AudioModeManager: ObservableObject {
    static let shared = AudioModeManager()

    private let logger = Logger(subsystem: "com.tuna.app", category: "AudioModeManager")
    private let audioManager = AudioManager.shared
    private var cancellables = Set<AnyCancellable>()

    /// All available audio modes
    @Published var modes: [AudioMode] = []

    /// Currently selected mode ID
    @Published var currentModeID: String? {
        didSet {
            if let modeID = currentModeID {
                UserDefaults.standard.set(modeID, forKey: "currentModeID")
                logger.debug("Saved current mode ID: \(modeID)")

                // Apply current mode settings
                if let mode = getMode(byID: modeID) {
                    applyMode(mode)
                }
            } else {
                UserDefaults.standard.removeObject(forKey: "currentModeID")
                logger.debug("Cleared current mode ID")
            }
        }
    }

    private init() {
        logger.debug("Initializing AudioModeManager")
        loadModes()

        // Load last used mode ID
        if let savedModeID = UserDefaults.standard.string(forKey: "currentModeID") {
            currentModeID = savedModeID
            logger.debug("Loaded last used mode ID: \(savedModeID)")
        }

        // Monitor device changes for potential automatic mode updates
        NotificationCenter.default.publisher(for: NSNotification.Name("audioDevicesChanged"))
            .sink { [weak self] _ in
                self?.checkForAutomaticModeSwitch()
            }
            .store(in: &cancellables)
    }

    /// Load saved audio modes
    private func loadModes() {
        if let data = UserDefaults.standard.data(forKey: "audioModes") {
            do {
                let decoder = JSONDecoder()
                modes = try decoder.decode([AudioMode].self, from: data)
                logger.debug("Loaded \(modes.count) audio modes")

                // Ensure at least one "automatic" mode exists
                if !modes.contains(where: \.isAutomatic) {
                    createDefaultModes()
                }
            } catch {
                logger.error("Failed to load audio modes: \(error.localizedDescription)")
                createDefaultModes()
            }
        } else {
            createDefaultModes()
        }
    }

    /// Create default audio modes
    private func createDefaultModes() {
        logger.debug("Creating default audio modes")

        // Create modes based on current devices
        var newModes: [AudioMode] = []

        // Add automatic mode
        let automaticMode = AudioMode(
            id: "automatic",
            name: "Automatic",
            outputDeviceUID: audioManager.selectedOutputDevice?.uid ?? "",
            inputDeviceUID: audioManager.selectedInputDevice?.uid ?? "",
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
                inputDeviceUID: defaultMic.uid
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
                inputDeviceUID: headphones.uid
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
                inputDeviceUID: "", // No input device
                outputVolume: 0.7
            )
            newModes.append(entertainmentMode)
        }

        modes = newModes
        saveModes()

        // Default to automatic mode
        currentModeID = "automatic"
    }

    /// Save audio modes
    private func saveModes() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(modes)
            UserDefaults.standard.set(data, forKey: "audioModes")
            logger.debug("Saved \(modes.count) audio modes")
        } catch {
            logger.error("Failed to save audio modes: \(error.localizedDescription)")
        }
    }

    /// Add a new audio mode
    func addMode(_ mode: AudioMode) {
        modes.append(mode)
        saveModes()
        logger.debug("Added new audio mode: \(mode.name)")
    }

    /// Update an existing audio mode
    func updateMode(_ mode: AudioMode) {
        if let index = modes.firstIndex(where: { $0.id == mode.id }) {
            modes[index] = mode
            saveModes()
            logger.debug("Updated audio mode: \(mode.name)")

            // If updating current mode, reapply settings
            if mode.id == currentModeID {
                applyMode(mode)
            }
        }
    }

    /// Delete an audio mode
    func deleteMode(withID id: String) {
        // Don't allow deleting automatic mode
        if id == "automatic" {
            logger.warning("Attempt to delete automatic mode rejected")
            return
        }

        modes.removeAll { $0.id == id }
        saveModes()
        logger.debug("Deleted audio mode ID: \(id)")

        // If deleting current mode, switch to automatic mode
        if id == currentModeID {
            currentModeID = "automatic"
        }
    }

    /// Get audio mode by ID
    func getMode(byID id: String) -> AudioMode? {
        modes.first { $0.id == id }
    }

    /// Apply audio mode settings
    func applyMode(_ mode: AudioMode) {
        logger.debug("Applying audio mode: \(mode.name)")

        // Set output device
        if !mode.outputDeviceUID.isEmpty {
            if let device = audioManager.findDevice(byUID: mode.outputDeviceUID, isInput: false) {
                audioManager.selectOutputDevice(device)
                audioManager.setVolumeForDevice(
                    device: device,
                    volume: mode.outputVolume,
                    isInput: false
                )
                logger.debug("Set output device: \(device.name), volume: \(mode.outputVolume)")
            } else {
                logger.warning("Output device not found: \(mode.outputDeviceUID)")
            }
        }

        // Set input device
        if !mode.inputDeviceUID.isEmpty {
            if let device = audioManager.findDevice(byUID: mode.inputDeviceUID, isInput: true) {
                audioManager.selectInputDevice(device)
                audioManager.setVolumeForDevice(
                    device: device,
                    volume: mode.inputVolume,
                    isInput: true
                )
                logger.debug("Set input device: \(device.name), volume: \(mode.inputVolume)")
            } else {
                logger.warning("Input device not found: \(mode.inputDeviceUID)")
            }
        }
    }

    /// Update current mode's device volumes
    func updateCurrentModeVolumes() {
        guard let currentModeID,
              let index = modes.firstIndex(where: { $0.id == currentModeID })
        else {
            return
        }

        // Update volume values
        modes[index].outputVolume = audioManager.outputVolume
        modes[index].inputVolume = audioManager.inputVolume

        saveModes()
        logger
            .debug(
                "Updated current mode volumes: output=\(audioManager.outputVolume), input=\(audioManager.inputVolume)"
            )
    }

    /// Check if automatic mode switch is needed
    private func checkForAutomaticModeSwitch() {
        // Only check if automatic mode is selected
        if currentModeID != "automatic" {
            return
        }

        // Update automatic mode device settings
        if let index = modes.firstIndex(where: { $0.id == "automatic" }) {
            var automaticMode = modes[index]

            // Update to current devices
            if let outputDevice = audioManager.selectedOutputDevice {
                automaticMode.outputDeviceUID = outputDevice.uid
                automaticMode.outputVolume = audioManager.outputVolume
            }

            if let inputDevice = audioManager.selectedInputDevice {
                automaticMode.inputDeviceUID = inputDevice.uid
                automaticMode.inputVolume = audioManager.inputVolume
            }

            modes[index] = automaticMode
            saveModes()
            logger.debug("Updated automatic mode device settings")
        }
    }

    /// Create a custom mode
    func createCustomMode(
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

        addMode(newMode)
        return newMode
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
