import AVFoundation
import Combine
import CoreAudio
import Foundation
import SwiftUI
import TunaTypes

// import TunaCore

public class AudioManager: ObservableObject {
    public static let shared = AudioManager()

    @Published public private(set) var outputDevices: [AudioDeviceImpl] = []
    @Published public private(set) var inputDevices: [AudioDeviceImpl] = []
    @Published public private(set) var selectedOutputDeviceImpl: AudioDeviceImpl?
    @Published public private(set) var selectedInputDeviceImpl: AudioDeviceImpl?
    @Published public private(set) var outputVolume: Float = 0.0
    @Published public private(set) var inputVolume: Float = 0.0

    public var selectedOutputDevice: AudioDevice? {
        self.selectedOutputDeviceImpl?.device
    }

    public var selectedInputDevice: AudioDevice? {
        self.selectedInputDeviceImpl?.device
    }

    private var deviceListener: AudioObjectPropertyListenerBlock?
    private var volumeListenerProc: AudioObjectPropertyListenerProc?
    private var inputVolumeListenerID: UInt32?
    private var outputVolumeListenerID: UInt32?
    private var userSelectedInputUID: String?
    private var userSelectedOutputUID: String?

    private init() {
        self.setupDeviceListener()
        self.setupSystemAudioVolumeListener()
        self.updateDevices()
    }

    private func setupDeviceListener() {
        self.deviceListener = { [weak self] (
            deviceID: AudioObjectID,
            addresses: UnsafePointer<AudioObjectPropertyAddress>
        ) in
            self?.updateDevices()
        }

        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        let status = AudioObjectAddPropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            nil,
            self.deviceListener!
        )

        if status != noErr {
            print("Failed to add device listener: \(status)")
        }
    }

    private func setupSystemAudioVolumeListener() {
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        self.volumeListenerProc = { deviceID, _, _, clientData in
            let manager = Unmanaged<AudioManager>.fromOpaque(clientData!).takeUnretainedValue()
            manager.handleVolumeChange(deviceID: deviceID, isInput: true)
            return noErr
        }

        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        let status = AudioObjectAddPropertyListener(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            self.volumeListenerProc!,
            selfPtr
        )

        if status != noErr {
            print("Failed to add volume listener: \(status)")
        }
    }

    private func handleVolumeChange(deviceID: AudioObjectID, isInput: Bool) {
        DispatchQueue.main.async {
            if isInput {
                if let device = self.selectedInputDeviceImpl, device.id == deviceID {
                    self.inputVolume = device.getVolume()
                }
            } else {
                if let device = self.selectedOutputDeviceImpl, device.id == deviceID {
                    self.outputVolume = device.getVolume()
                }
            }
        }
    }

    private func updateDevices() {
        // Get current devices
        let currentOutputDevices = self.getAudioDevices(scope: kAudioDevicePropertyScopeOutput)
        let currentInputDevices = self.getAudioDevices(scope: kAudioDevicePropertyScopeInput)

        // Update current devices
        DispatchQueue.main.async {
            self.outputDevices = currentOutputDevices.compactMap { device in
                AudioDeviceImpl(deviceID: device.id)
            }

            self.inputDevices = currentInputDevices.compactMap { device in
                AudioDeviceImpl(deviceID: device.id)
            }

            // Update selected devices if needed
            if let selectedOutput = self.selectedOutputDevice,
               !currentOutputDevices.contains(where: { $0.uid == selectedOutput.uid })
            {
                self.selectedOutputDeviceImpl = nil
            }

            if let selectedInput = self.selectedInputDevice,
               !currentInputDevices.contains(where: { $0.uid == selectedInput.uid })
            {
                self.selectedInputDeviceImpl = nil
            }
        }
    }

    private func getAudioDevices(scope: AudioObjectPropertyScope) -> [AudioDevice] {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var propertySize: UInt32 = 0
        var status = AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &propertySize
        )

        if status != noErr {
            print("Error getting devices size: \(status)")
            return []
        }

        let deviceCount = Int(propertySize) / MemoryLayout<AudioDeviceID>.size
        var deviceIDs = [AudioDeviceID](repeating: 0, count: deviceCount)

        status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &propertySize,
            &deviceIDs
        )

        if status != noErr {
            print("Error getting device IDs: \(status)")
            return []
        }

        return deviceIDs.compactMap { deviceID in
            if let impl = AudioDeviceImpl(deviceID: deviceID) {
                return impl.device
            }
            return nil
        }
    }

    private func directSystemVolumeQuery(device: AudioDeviceImpl, isInput: Bool) -> Float {
        device.getVolume()
    }

    public func selectOutputDevice(_ device: AudioDevice) {
        if let impl = AudioDeviceImpl(deviceID: device.id) {
            self.selectedOutputDeviceImpl = impl
            self.outputVolume = impl.getVolume()
        }
    }

    public func selectInputDevice(_ device: AudioDevice) {
        if let impl = AudioDeviceImpl(deviceID: device.id) {
            self.selectedInputDeviceImpl = impl
            self.inputVolume = impl.getVolume()
        }
    }

    deinit {
        if let deviceListener {
            var address = AudioObjectPropertyAddress(
                mSelector: kAudioHardwarePropertyDevices,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain
            )

            AudioObjectRemovePropertyListenerBlock(
                AudioObjectID(kAudioObjectSystemObject),
                &address,
                nil,
                deviceListener
            )
        }

        if let volumeListenerProc {
            var address = AudioObjectPropertyAddress(
                mSelector: kAudioHardwarePropertyDefaultInputDevice,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain
            )

            AudioObjectRemovePropertyListener(
                AudioObjectID(kAudioObjectSystemObject),
                &address,
                volumeListenerProc,
                Unmanaged.passUnretained(self).toOpaque()
            )
        }
    }
}
