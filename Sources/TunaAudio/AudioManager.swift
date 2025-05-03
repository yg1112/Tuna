import AVFoundation
import Combine
import CoreAudio
import Foundation
import os
import SwiftUI
import TunaTypes

// import TunaCore

@MainActor
public class AudioManager: ObservableObject, AudioManagerProtocol {
    @MainActor public static let shared = AudioManager()

    // MARK: - Published Properties (Main Actor Only)
    @Published private var _outputDevices: [any AudioDevice] = []
    @Published private var _inputDevices: [any AudioDevice] = []
    @Published private var _selectedOutputDevice: (any AudioDevice)? = nil
    @Published private var _selectedInputDevice: (any AudioDevice)? = nil
    @Published private var _inputVolume: Float = 0.5
    @Published private var _outputVolume: Float = 0.5

    private var deviceListener: AudioObjectPropertyListenerBlock?
    private var volumeListenerProc: AudioObjectPropertyListenerProc?
    private var inputVolumeListenerID: UInt32?
    private var outputVolumeListenerID: UInt32?
    private var userSelectedInputUID: String?
    private var userSelectedOutputUID: String?

    // MARK: - Private Properties
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "AudioManager")

    // Thread-safe storage using actor
    private actor ThreadSafeStorage {
        var inputDevices: [any AudioDevice] = []
        var outputDevices: [any AudioDevice] = []
        var selectedInputDevice: (any AudioDevice)? = nil
        var selectedOutputDevice: (any AudioDevice)? = nil
        var inputVolume: Float = 0.0
        var outputVolume: Float = 0.0

        func updateState(
            inputDevices: [any AudioDevice]? = nil,
            outputDevices: [any AudioDevice]? = nil,
            selectedInputDevice: (any AudioDevice)? = nil,
            selectedOutputDevice: (any AudioDevice)? = nil,
            inputVolume: Float? = nil,
            outputVolume: Float? = nil
        ) {
            if let inputDevices {
                self.inputDevices = inputDevices
            }
            if let outputDevices {
                self.outputDevices = outputDevices
            }
            if let selectedInputDevice {
                self.selectedInputDevice = selectedInputDevice
            }
            if let selectedOutputDevice {
                self.selectedOutputDevice = selectedOutputDevice
            }
            if let inputVolume {
                self.inputVolume = inputVolume
            }
            if let outputVolume {
                self.outputVolume = outputVolume
            }
        }
    }

    private let storage = ThreadSafeStorage()

    // MARK: - AudioManagerProtocol Nonisolated Implementation
    public nonisolated var inputDevices: [any AudioDevice] {
        get async {
            await self.storage.inputDevices
        }
    }

    public nonisolated var outputDevices: [any AudioDevice] {
        get async {
            await self.storage.outputDevices
        }
    }

    public nonisolated var selectedInputDevice: (any AudioDevice)? {
        get async {
            await self.storage.selectedInputDevice
        }
    }

    public nonisolated var selectedOutputDevice: (any AudioDevice)? {
        get async {
            await self.storage.selectedOutputDevice
        }
    }

    public nonisolated var inputVolume: Float {
        get async {
            await self.storage.inputVolume
        }
    }

    public nonisolated var outputVolume: Float {
        get async {
            await self.storage.outputVolume
        }
    }

    public nonisolated func currentAudioState() async -> AudioState {
        async let inputDevices = self.storage.inputDevices
        async let outputDevices = self.storage.outputDevices
        async let selectedInputDevice = self.storage.selectedInputDevice
        async let selectedOutputDevice = self.storage.selectedOutputDevice
        async let inputVolume = self.storage.inputVolume
        async let outputVolume = self.storage.outputVolume

        return await AudioState(
            inputDevices: inputDevices,
            outputDevices: outputDevices,
            selectedInputDevice: selectedInputDevice,
            selectedOutputDevice: selectedOutputDevice,
            inputVolume: inputVolume,
            outputVolume: outputVolume
        )
    }

    private init() {
        self.setupDeviceListener()
        self.setupSystemAudioVolumeListener()
        self.refreshDevices()
    }

    // MARK: - Device Management

    private func setupDeviceListener() {
        self.deviceListener = { [weak self] (
            deviceID: AudioObjectID,
            addresses: UnsafePointer<AudioObjectPropertyAddress>
        ) in
            Task { @MainActor [weak self] in
                self?.refreshDevices()
            }
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
            Task { @MainActor in
                await manager.handleVolumeChange(deviceID: deviceID, isInput: true)
            }
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

    private func handleVolumeChange(deviceID: AudioObjectID, isInput: Bool) async {
        if isInput {
            if let device = await selectedInputDevice, device.id == deviceID {
                let volume = device.getVolume()
                await self.updateInputVolume(volume)
            }
        } else {
            if let device = await selectedOutputDevice, device.id == deviceID {
                let volume = device.getVolume()
                await self.updateOutputVolume(volume)
            }
        }
    }

    private func updateInputVolume(_ volume: Float) async {
        Task { @MainActor in
            self._inputVolume = volume
        }
        await self.storage.updateState(inputVolume: volume)
    }

    private func updateOutputVolume(_ volume: Float) async {
        Task { @MainActor in
            self._outputVolume = volume
        }
        await self.storage.updateState(outputVolume: volume)
    }

    private func refreshDevices() {
        // Update published properties
        self._inputDevices = AudioDeviceImpl.allInputDevices
        self._outputDevices = AudioDeviceImpl.allOutputDevices

        // Update thread-safe storage
        Task {
            await self.storage.updateState(
                inputDevices: self._inputDevices,
                outputDevices: self._outputDevices,
                selectedInputDevice: self._selectedInputDevice,
                selectedOutputDevice: self._selectedOutputDevice,
                inputVolume: self._inputVolume,
                outputVolume: self._outputVolume
            )
        }

        // Update selected devices
        if let inputUID = userSelectedInputUID,
           let device = self._inputDevices.first(where: { $0.uid == inputUID })
        {
            Task {
                await self.selectInputDevice(device)
            }
        }

        if let outputUID = userSelectedOutputUID,
           let device = self._outputDevices.first(where: { $0.uid == outputUID })
        {
            Task {
                await self.selectOutputDevice(device)
            }
        }
    }

    public func selectOutputDevice(_ device: any AudioDevice) async {
        await self.storage.updateState(selectedOutputDevice: device)
        Task { @MainActor in
            self._selectedOutputDevice = device
            self.userSelectedOutputUID = device.uid
        }
    }

    public func selectInputDevice(_ device: any AudioDevice) async {
        await self.storage.updateState(selectedInputDevice: device)
        Task { @MainActor in
            self._selectedInputDevice = device
            self.userSelectedInputUID = device.uid
        }
    }

    public func setVolumeForDevice(_ device: any AudioDevice, volume: Float) async {
        let isInput = await inputDevices.contains { $0.id == device.id }
        device.setVolume(volume)

        if isInput {
            await self.storage.updateState(inputVolume: volume)
            Task { @MainActor in self._inputVolume = volume }
        } else {
            await self.storage.updateState(outputVolume: volume)
            Task { @MainActor in self._outputVolume = volume }
        }
    }

    /// 设置默认设备
    public func setDefaultDevice(_ device: any AudioDevice, forInput: Bool) async {
        if forInput {
            await self.selectInputDevice(device)
        } else {
            await self.selectOutputDevice(device)
        }
    }

    /// 根据UID查找设备
    public func findDevice(byUID uid: String, isInput: Bool) async -> (any AudioDevice)? {
        let devices = await (isInput ? self.inputDevices : self.outputDevices)
        return devices.first { $0.uid == uid }
    }

    /// 历史输入设备
    @Published public var historicalInputDevices: [any AudioDevice] = []

    /// 历史输出设备
    @Published public var historicalOutputDevices: [any AudioDevice] = []

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

    // MARK: - Volume Control Protocol Methods
    public func setOutputVolume(_ volume: Float) async {
        if let device = await selectedOutputDevice {
            await self.setVolumeForDevice(device, volume: volume)
        }
    }

    public func setInputVolume(_ volume: Float) async {
        if let device = await selectedInputDevice {
            await self.setVolumeForDevice(device, volume: volume)
        }
    }

    // MARK: - Volume Streams
    public var outputVolumeStream: AsyncStream<Float> {
        AsyncStream { continuation in
            Task { @MainActor in
                for await volume in self.$_outputVolume.values {
                    continuation.yield(volume)
                }
            }
        }
    }

    public var inputVolumeStream: AsyncStream<Float> {
        AsyncStream { continuation in
            Task { @MainActor in
                for await volume in self.$_inputVolume.values {
                    continuation.yield(volume)
                }
            }
        }
    }
}
