import Foundation
import CoreAudio
import AVFoundation

class AudioManager: ObservableObject {
    static let shared = AudioManager()
    
    @Published var inputDevices: [AudioDevice] = []
    @Published var outputDevices: [AudioDevice] = []
    @Published var selectedInputDevice: AudioDevice?
    @Published var selectedOutputDevice: AudioDevice?
    @Published var inputVolume: Float = 1.0
    @Published var outputVolume: Float = 1.0
    
    init() {
        updateDeviceList()
        setupDeviceChangeListener()
    }
    
    func updateDeviceList() {
        var propertySize: UInt32 = 0
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        // Get the size of the device list
        guard AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &propertySize
        ) == noErr else {
            print("Error getting device list size")
            return
        }
        
        let deviceCount = Int(propertySize) / MemoryLayout<AudioDeviceID>.size
        var deviceIDs = [AudioDeviceID](repeating: 0, count: deviceCount)
        
        // Get the device IDs
        guard AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &propertySize,
            &deviceIDs
        ) == noErr else {
            print("Error getting device IDs")
            return
        }
        
        // Process each device
        var newInputDevices: [AudioDevice] = []
        var newOutputDevices: [AudioDevice] = []
        
        for deviceID in deviceIDs {
            if let device = getDeviceInfo(deviceID: deviceID) {
                if device.hasInput {
                    newInputDevices.append(device)
                }
                if device.hasOutput {
                    newOutputDevices.append(device)
                }
            }
        }
        
        DispatchQueue.main.async {
            self.inputDevices = newInputDevices
            self.outputDevices = newOutputDevices
            self.updateSelectedDevices()
        }
    }
    
    private func getDeviceInfo(deviceID: AudioDeviceID) -> AudioDevice? {
        var propertySize = UInt32(MemoryLayout<CFString>.size)
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceNameCFString,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var deviceNameRef: CFString?
        guard AudioObjectGetPropertyData(
            deviceID,
            &propertyAddress,
            0,
            nil,
            &propertySize,
            &deviceNameRef
        ) == noErr,
        let deviceName = deviceNameRef as String? else {
            return nil
        }
        
        // Check for input/output capabilities
        let hasInput = hasDeviceCapability(deviceID: deviceID, scope: kAudioObjectPropertyScopeInput)
        let hasOutput = hasDeviceCapability(deviceID: deviceID, scope: kAudioObjectPropertyScopeOutput)
        
        return AudioDevice(id: deviceID, name: deviceName, hasInput: hasInput, hasOutput: hasOutput)
    }
    
    private func hasDeviceCapability(deviceID: AudioDeviceID, scope: AudioObjectPropertyScope) -> Bool {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreamConfiguration,
            mScope: scope,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var propertySize: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(
            deviceID,
            &propertyAddress,
            0,
            nil,
            &propertySize
        ) == noErr else {
            return false
        }
        
        let bufferList = UnsafeMutablePointer<AudioBufferList>.allocate(capacity: Int(propertySize))
        defer { bufferList.deallocate() }
        
        guard AudioObjectGetPropertyData(
            deviceID,
            &propertyAddress,
            0,
            nil,
            &propertySize,
            bufferList
        ) == noErr else {
            return false
        }
        
        let bufferCount = Int(bufferList.pointee.mNumberBuffers)
        return bufferCount > 0
    }
    
    private func setupDeviceChangeListener() {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let selfPtr = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        
        AudioObjectAddPropertyListener(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            { _, _, _, context in
                let manager = Unmanaged<AudioManager>.fromOpaque(context!).takeUnretainedValue()
                manager.updateDeviceList()
                return noErr
            },
            selfPtr
        )
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
    
    func setVolume(_ volume: Float, forInput: Bool) {
        guard let device = forInput ? selectedInputDevice : selectedOutputDevice else { return }
        
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
            mScope: forInput ? kAudioDevicePropertyScopeInput : kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        
        // First check if the device has volume control
        var hasVolume: UInt32 = 0
        var propertySize = UInt32(MemoryLayout<UInt32>.size)
        var status = AudioObjectGetPropertyDataSize(
            device.id,
            &propertyAddress,
            0,
            nil,
            &hasVolume
        )
        
        if status != noErr {
            print("Device does not support volume control")
            return
        }
        
        var newVolume = volume
        status = AudioObjectSetPropertyData(
            device.id,
            &propertyAddress,
            0,
            nil,
            UInt32(MemoryLayout<Float>.size),
            &newVolume
        )
        
        if status == noErr {
            DispatchQueue.main.async {
                if forInput {
                    self.inputVolume = volume
                } else {
                    self.outputVolume = volume
                }
            }
        } else {
            print("Error setting volume: \(status)")
        }
    }
    
    func getVolume(forInput: Bool) -> Float {
        guard let device = forInput ? selectedInputDevice : selectedOutputDevice else { return 1.0 }
        
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
            mScope: forInput ? kAudioDevicePropertyScopeInput : kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        
        // Check if the device has volume control
        var hasVolume: UInt32 = 0
        var propertySize = UInt32(MemoryLayout<UInt32>.size)
        var status = AudioObjectGetPropertyDataSize(
            device.id,
            &propertyAddress,
            0,
            nil,
            &hasVolume
        )
        
        if status != noErr {
            print("Device does not support volume control")
            return 1.0
        }
        
        var volume: Float = 1.0
        propertySize = UInt32(MemoryLayout<Float>.size)
        
        status = AudioObjectGetPropertyData(
            device.id,
            &propertyAddress,
            0,
            nil,
            &propertySize,
            &volume
        )
        
        if status == noErr {
            return volume
        } else {
            print("Error getting volume: \(status)")
            return 1.0
        }
    }
    
    private func updateSelectedDevices() {
        // Get default input device
        var propertySize = UInt32(MemoryLayout<AudioDeviceID>.size)
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var inputDeviceID: AudioDeviceID = 0
        var status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &propertySize,
            &inputDeviceID
        )
        
        if status == noErr {
            selectedInputDevice = inputDevices.first { $0.id == inputDeviceID }
        }
        
        // Get default output device
        propertyAddress.mSelector = kAudioHardwarePropertyDefaultOutputDevice
        var outputDeviceID: AudioDeviceID = 0
        status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &propertySize,
            &outputDeviceID
        )
        
        if status == noErr {
            selectedOutputDevice = outputDevices.first { $0.id == outputDeviceID }
        }
        
        // Update volumes after device selection
        inputVolume = getVolume(forInput: true)
        outputVolume = getVolume(forInput: false)
    }
    
    func selectInputDevice(_ device: AudioDevice) {
        setDefaultDevice(device, forInput: true)
    }
    
    func selectOutputDevice(_ device: AudioDevice) {
        setDefaultDevice(device, forInput: false)
    }
} 