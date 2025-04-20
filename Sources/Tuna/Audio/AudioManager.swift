import SwiftUI
import Combine

class AudioManager: NSObject, ObservableObject {
    static let shared = AudioManager()
    
    @Published var selectedOutputDevice: AudioDevice?
    @Published var selectedInputDevice: AudioDevice?
    @Published var outputDevices: [AudioDevice] = []
    @Published var inputDevices: [AudioDevice] = []
    @Published private(set) var inputVolume: Float = 0.0
    @Published private(set) var outputVolume: Float = 0.0
    
    @objc dynamic func getInputVolume() -> Float {
        guard let device = selectedInputDevice else { return 0.0 }
        return device.volume
    }
    
    @objc dynamic func setInputVolume(_ volume: Float) {
        guard let device = selectedInputDevice else { return }
        device.volume = volume
        self.inputVolume = volume
    }
    
    @objc dynamic func getOutputVolume() -> Float {
        guard let device = selectedOutputDevice else { return 0.0 }
        return device.volume
    }
    
    @objc dynamic func setOutputVolume(_ volume: Float) {
        guard let device = selectedOutputDevice else { return }
        device.volume = volume
        self.outputVolume = volume
    }
    
    func setVolume(_ volume: Float, forInput isInput: Bool) {
        if isInput {
            self.setInputVolume(volume)
        } else {
            self.setOutputVolume(volume)
        }
    }
    
    private func getSystemVolumeForDevice(device: AudioDevice, isInput: Bool) -> Float {
        let scope = isInput ? kAudioDevicePropertyScopeInput : kAudioDevicePropertyScopeOutput
        let deviceID = device.id
        var volume: Float32 = 0.0
        var size = UInt32(MemoryLayout<Float32>.size)

        // 尝试方法1: 使用硬件服务属性(这对蓝牙设备最可靠)
        var hardwareServiceAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMasterVolume,
            mScope: scope,
            mElement: kAudioObjectPropertyElementMain
        )

        if AudioObjectHasProperty(deviceID, &hardwareServiceAddress) {
            let status = AudioObjectGetPropertyData(
                deviceID,
                &hardwareServiceAddress,
                0,
                nil,
                &size,
                &volume
            )
            if status == noErr {
                print("\u{001B}[32m[VOLUME]\u{001B}[0m Successfully got hardware service volume for device '\(device.name)': \(volume)")
                return volume
            } else {
                print("\u{001B}[33m[VOLUME]\u{001B}[0m Failed to get hardware service volume for device '\(device.name)': Error \(status)")
            }
        }

        // 尝试方法2: 使用虚拟主音量
        var virtualAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVirtualMasterVolume,
            mScope: scope,
            mElement: kAudioObjectPropertyElementMain
        )

        if AudioObjectHasProperty(deviceID, &virtualAddress) {
            let status = AudioObjectGetPropertyData(
                deviceID,
                &virtualAddress,
                0,
                nil,
                &size,
                &volume
            )
            if status == noErr {
                print("\u{001B}[32m[VOLUME]\u{001B}[0m Successfully got virtual master volume for device '\(device.name)': \(volume)")
                return volume
            } else {
                print("\u{001B}[33m[VOLUME]\u{001B}[0m Failed to get virtual master volume for device '\(device.name)': Error \(status)")
            }
        }

        // 尝试方法3: 使用标准音量缩放器
        var scalarAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: scope,
            mElement: kAudioObjectPropertyElementMain
        )

        if AudioObjectHasProperty(deviceID, &scalarAddress) {
            let status = AudioObjectGetPropertyData(
                deviceID,
                &scalarAddress,
                0,
                nil,
                &size,
                &volume
            )
            if status == noErr {
                print("\u{001B}[32m[VOLUME]\u{001B}[0m Successfully got scalar volume for device '\(device.name)': \(volume)")
                return volume
            } else {
                print("\u{001B}[33m[VOLUME]\u{001B}[0m Failed to get scalar volume for device '\(device.name)': Error \(status)")
            }
        }

        // If all methods fail, return default volume
        print("\u{001B}[31m[VOLUME]\u{001B}[0m All volume retrieval methods failed for device '\(device.name)', using default volume: 1.0")
        return 1.0
    }

    private func setVolumeForDevice(device: AudioDevice, volume: Float, isInput: Bool) {
        let scope = isInput ? kAudioDevicePropertyScopeInput : kAudioDevicePropertyScopeOutput
        let deviceID = device.id
        var newVolume = volume
        var size = UInt32(MemoryLayout<Float32>.size)

        // 尝试方法1: 使用硬件服务属性(这对蓝牙设备最可靠)
        var hardwareServiceAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMasterVolume,
            mScope: scope,
            mElement: kAudioObjectPropertyElementMain
        )

        if AudioObjectHasProperty(deviceID, &hardwareServiceAddress) {
            let status = AudioObjectSetPropertyData(
                deviceID,
                &hardwareServiceAddress,
                0,
                nil,
                size,
                &newVolume
            )
            if status == noErr {
                print("\u{001B}[32m[VOLUME]\u{001B}[0m Successfully set hardware service volume for device '\(device.name)' to \(volume)")
                return
            } else {
                print("\u{001B}[33m[VOLUME]\u{001B}[0m Failed to set hardware service volume for device '\(device.name)': Error \(status)")
            }
        }

        // 尝试方法2: 使用虚拟主音量
        var virtualAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVirtualMasterVolume,
            mScope: scope,
            mElement: kAudioObjectPropertyElementMain
        )

        if AudioObjectHasProperty(deviceID, &virtualAddress) {
            let status = AudioObjectSetPropertyData(
                deviceID,
                &virtualAddress,
                0,
                nil,
                size,
                &newVolume
            )
            if status == noErr {
                print("\u{001B}[32m[VOLUME]\u{001B}[0m Successfully set virtual master volume for device '\(device.name)' to \(volume)")
                return
            } else {
                print("\u{001B}[33m[VOLUME]\u{001B}[0m Failed to set virtual master volume for device '\(device.name)': Error \(status)")
            }
        }

        // 尝试方法3: 使用标准音量缩放器
        var scalarAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: scope,
            mElement: kAudioObjectPropertyElementMain
        )

        if AudioObjectHasProperty(deviceID, &scalarAddress) {
            let status = AudioObjectSetPropertyData(
                deviceID,
                &scalarAddress,
                0,
                nil,
                size,
                &newVolume
            )
            if status == noErr {
                print("\u{001B}[32m[VOLUME]\u{001B}[0m Successfully set scalar volume for device '\(device.name)' to \(volume)")
                return
            } else {
                print("\u{001B}[33m[VOLUME]\u{001B}[0m Failed to set scalar volume for device '\(device.name)': Error \(status)")
            }
        }

        print("\u{001B}[31m[VOLUME]\u{001B}[0m All volume setting methods failed for device '\(device.name)'")
    }
} 