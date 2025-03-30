import Foundation
import CoreAudio
import AVFoundation
import SwiftUI

class AudioManager: ObservableObject {
    static let shared = AudioManager()
    
    @Published var inputDevices: [AudioDevice] = []
    @Published var outputDevices: [AudioDevice] = []
    @Published var selectedInputDevice: AudioDevice?
    @Published var selectedOutputDevice: AudioDevice?
    @Published var inputVolume: Float = 1.0
    @Published var outputVolume: Float = 1.0
    
    private var deviceListenerID: AudioObjectPropertyListenerProc?
    
    init() {
        refreshDevices()
        setupListeners()
    }
    
    private func refreshDevices() {
        // Get all audio devices
        var propertySize: UInt32 = 0
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let status = AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &propertySize
        )
        
        if status != noErr {
            print("Error getting device list size: \(status)")
            return
        }
        
        let deviceCount = Int(propertySize) / MemoryLayout<AudioDeviceID>.size
        var deviceIDs = [AudioDeviceID](repeating: 0, count: deviceCount)
        
        AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &propertySize,
            &deviceIDs
        )
        
        // Process each device
        var newInputDevices: [AudioDevice] = []
        var newOutputDevices: [AudioDevice] = []
        
        for deviceID in deviceIDs {
            if let device = getDeviceInfo(deviceID: deviceID) {
                if device.isInput {
                    newInputDevices.append(device)
                }
                if device.isOutput {
                    newOutputDevices.append(device)
                }
            }
        }
        
        // Update the published properties
        inputDevices = newInputDevices
        outputDevices = newOutputDevices
        
        // Update selected devices if they don't exist in the new list
        if let selectedInput = selectedInputDevice, !newInputDevices.contains(where: { $0.id == selectedInput.id }) {
            selectedInputDevice = newInputDevices.first
        }
        
        if let selectedOutput = selectedOutputDevice, !newOutputDevices.contains(where: { $0.id == selectedOutput.id }) {
            selectedOutputDevice = newOutputDevices.first
        }
    }
    
    private func getDeviceInfo(deviceID: AudioDeviceID) -> AudioDevice? {
        var propertySize = UInt32(MemoryLayout<CFString>.size)
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyName,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var deviceName = "" as CFString
        let status = AudioObjectGetPropertyData(
            deviceID,
            &propertyAddress,
            0,
            nil,
            &propertySize,
            &deviceName
        )
        
        if status != noErr {
            print("Error getting device name: \(status)")
            return nil
        }
        
        let hasInput = hasDeviceCapability(deviceID: deviceID, scope: kAudioObjectPropertyScopeInput)
        let hasOutput = hasDeviceCapability(deviceID: deviceID, scope: kAudioObjectPropertyScopeOutput)
        
        // 检查设备是否为蓝牙设备
        let isBluetooth = isBluetoothDevice(deviceID: deviceID)
        
        return AudioDevice(
            id: deviceID,
            name: deviceName as String,
            isInput: hasInput,
            isOutput: hasOutput,
            isBluetooth: isBluetooth,
            batteryLevel: nil  // 暂时不实现电池电量检测
        )
    }
    
    private func hasDeviceCapability(deviceID: AudioDeviceID, scope: AudioObjectPropertyScope) -> Bool {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreamConfiguration,
            mScope: scope,
            mElement: 0
        )
        
        var propertySize: UInt32 = 0
        let status = AudioObjectGetPropertyDataSize(
            deviceID,
            &propertyAddress,
            0,
            nil,
            &propertySize
        )
        
        if status != noErr {
            return false
        }
        
        let bufferList = UnsafeMutablePointer<AudioBufferList>.allocate(capacity: Int(propertySize))
        defer { bufferList.deallocate() }
        
        let status2 = AudioObjectGetPropertyData(
            deviceID,
            &propertyAddress,
            0,
            nil,
            &propertySize,
            bufferList
        )
        
        if status2 != noErr {
            return false
        }
        
        let bufferListPointer = UnsafeMutableAudioBufferListPointer(bufferList)
        return bufferListPointer.reduce(0) { $0 + $1.mNumberChannels } > 0
    }
    
    private func isBluetoothDevice(deviceID: AudioDeviceID) -> Bool {
        var transportType = UInt32(0)
        var propertySize = UInt32(MemoryLayout<UInt32>.size)
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyTransportType,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let status = AudioObjectGetPropertyData(
            deviceID,
            &propertyAddress,
            0,
            nil,
            &propertySize,
            &transportType
        )
        
        if status == noErr {
            return transportType == kAudioDeviceTransportTypeBluetooth ||
                   transportType == kAudioDeviceTransportTypeBluetoothLE
        }
        
        return false
    }
    
    func setDefaultDevice(_ device: AudioDevice, forInput: Bool) {
        let selector = forInput ? kAudioHardwarePropertyDefaultInputDevice : kAudioHardwarePropertyDefaultOutputDevice
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var deviceID = device.id
        let status = AudioObjectSetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            UInt32(MemoryLayout<AudioDeviceID>.size),
            &deviceID
        )
        
        if status == noErr {
            DispatchQueue.main.async {
                if forInput {
                    self.selectedInputDevice = device
                } else {
                    self.selectedOutputDevice = device
                }
            }
        } else {
            print("Error setting default device: \(status)")
        }
    }
    
    func setVolumeForDevice(device: AudioDevice, volume: Float, isInput: Bool) {
        let scope = isInput ? kAudioDevicePropertyScopeInput : kAudioDevicePropertyScopeOutput
        let channel = UInt32(0)
        
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
            mScope: scope,
            mElement: channel
        )
        
        // Set the volume
        var volumeValue = volume
        var status = AudioObjectSetPropertyData(
            device.id,
            &propertyAddress,
            0,
            nil,
            UInt32(MemoryLayout<Float>.size),
            &volumeValue
        )
        
        if status != noErr {
            print("Error setting main volume: \(status)")
            
            // Try alternative method with VolumeScalar
            propertyAddress.mSelector = kAudioDevicePropertyVolumeScalar
            status = AudioObjectSetPropertyData(
                device.id,
                &propertyAddress,
                0,
                nil,
                UInt32(MemoryLayout<Float>.size),
                &volumeValue
            )
            
            if status != noErr {
                print("Error setting volume scalar: \(status)")
                return
            }
        }
        
        // Update the UI
        DispatchQueue.main.async {
            if isInput {
                self.inputVolume = volume
            } else {
                self.outputVolume = volume
            }
        }
    }
    
    private func setupListeners() {
        // Setup listener for device list changes
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let selfPointer = Unmanaged.passUnretained(self).toOpaque()
        
        let listenerBlock: AudioObjectPropertyListenerProc = { (inObjectID, inNumberAddresses, inPropertyAddresses, inClientData) -> OSStatus in
            let manager = Unmanaged<AudioManager>.fromOpaque(inClientData!).takeUnretainedValue()
            manager.refreshDevices()
            return noErr
        }
        
        deviceListenerID = listenerBlock
        
        AudioObjectAddPropertyListener(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            deviceListenerID!,
            selfPointer
        )
        
        // Also listen for default device changes
        var inputPropertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        AudioObjectAddPropertyListener(
            AudioObjectID(kAudioObjectSystemObject),
            &inputPropertyAddress,
            deviceListenerID!,
            selfPointer
        )
        
        var outputPropertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        AudioObjectAddPropertyListener(
            AudioObjectID(kAudioObjectSystemObject),
            &outputPropertyAddress,
            deviceListenerID!,
            selfPointer
        )
    }
    
    deinit {
        if let listenerID = deviceListenerID {
            var propertyAddress = AudioObjectPropertyAddress(
                mSelector: kAudioHardwarePropertyDevices,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain
            )
            
            AudioObjectRemovePropertyListener(
                AudioObjectID(kAudioObjectSystemObject),
                &propertyAddress,
                listenerID,
                Unmanaged.passUnretained(self).toOpaque()
            )
        }
    }
    
    func selectInputDevice(_ device: AudioDevice) {
        setDefaultDevice(device, forInput: true)
    }
    
    func selectOutputDevice(_ device: AudioDevice) {
        setDefaultDevice(device, forInput: false)
    }
} 