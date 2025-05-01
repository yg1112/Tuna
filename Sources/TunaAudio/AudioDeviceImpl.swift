import CoreAudio
import Foundation
import TunaTypes

public class AudioDeviceImpl: Identifiable {
    private let deviceID: AudioObjectID
    var device: AudioDevice
    private var hasInput: Bool = false
    private var hasOutput: Bool = false
    private var supportsBalanceControl: Bool = false
    private var balanceLocked: Bool = false

    public init?(deviceID: AudioObjectID) {
        self.deviceID = deviceID

        // Get device name
        var propertySize = UInt32(MemoryLayout<CFString>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyName,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var deviceNameRef: CFString?
        let nameStatus = AudioObjectGetPropertyData(
            deviceID,
            &address,
            0,
            nil,
            &propertySize,
            &deviceNameRef
        )

        if nameStatus != noErr || deviceNameRef == nil {
            print("Failed to get device name: \(nameStatus)")
            return nil
        }

        // Get device UID
        address.mSelector = kAudioDevicePropertyDeviceUID
        var deviceUIDRef: CFString?
        let uidStatus = AudioObjectGetPropertyData(
            deviceID,
            &address,
            0,
            nil,
            &propertySize,
            &deviceUIDRef
        )

        if uidStatus != noErr || deviceUIDRef == nil {
            print("Failed to get device UID: \(uidStatus)")
            return nil
        }

        // Initialize device
        let deviceName = deviceNameRef! as String
        let deviceUID = deviceUIDRef! as String
        self.device = AudioDevice(id: deviceID, name: deviceName, uid: deviceUID)

        // Check input/output capabilities
        self.hasInput = self.device.hasInput
        self.hasOutput = self.device.hasOutput

        // Check balance control support
        let scope = self.hasInput ? kAudioDevicePropertyScopeInput : kAudioDevicePropertyScopeOutput

        var panPropertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStereoPan,
            mScope: scope,
            mElement: kAudioObjectPropertyElementMain
        )

        var balancePropertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStereoPan,
            mScope: scope,
            mElement: kAudioObjectPropertyElementMain
        )

        var isSettable: DarwinBoolean = false

        // Check standard stereo balance support
        if AudioObjectHasProperty(deviceID, &panPropertyAddress) {
            let status = AudioObjectIsPropertySettable(deviceID, &panPropertyAddress, &isSettable)
            if status == noErr, isSettable.boolValue {
                self.supportsBalanceControl = true
                print("Device \(self.device.name) supports StereoPan balance control")
            }
        }

        // If standard balance not supported, check virtual balance
        if !self.supportsBalanceControl, AudioObjectHasProperty(deviceID, &balancePropertyAddress) {
            let status = AudioObjectIsPropertySettable(
                deviceID,
                &balancePropertyAddress,
                &isSettable
            )
            if status == noErr, isSettable.boolValue {
                self.supportsBalanceControl = true
                print("Device \(self.device.name) supports VirtualMasterBalance control")
            }
        }

        if !self.supportsBalanceControl {
            print("Device \(self.device.name) does not support balance control")
        }
    }

    // Add minimal initialization constructor
    public convenience init(device: AudioDevice) {
        self.init(deviceID: device.id, device: device)!
    }

    private init?(deviceID: AudioObjectID, device: AudioDevice) {
        self.deviceID = deviceID
        self.device = device
        self.hasInput = device.hasInput
        self.hasOutput = device.hasOutput
        self.supportsBalanceControl = false
        self.balanceLocked = false
    }

    public var id: AudioObjectID {
        self.deviceID
    }

    public var name: String {
        self.device.name
    }

    public var uid: String {
        self.device.uid
    }

    public func getVolume() -> Float {
        self.device.getVolume()
    }

    public func setVolume(_ volume: Float) {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )

        var newVolume = volume
        let status = AudioObjectSetPropertyData(
            deviceID,
            &propertyAddress,
            0,
            nil,
            UInt32(MemoryLayout<Float>.size),
            &newVolume
        )

        if status != noErr {
            print("Failed to set volume: \(status)")
        }
    }

    public func getBalance() -> Float {
        var balance: Float = 0.0
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStereoPan,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )

        var size = UInt32(MemoryLayout<Float>.size)
        let status = AudioObjectGetPropertyData(
            deviceID,
            &propertyAddress,
            0,
            nil,
            &size,
            &balance
        )

        if status == noErr {
            return balance
        }

        return 0.0
    }

    public func setBalance(_ balance: Float) {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStereoPan,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )

        var newBalance = balance
        let status = AudioObjectSetPropertyData(
            deviceID,
            &propertyAddress,
            0,
            nil,
            UInt32(MemoryLayout<Float>.size),
            &newBalance
        )

        if status != noErr {
            print("Failed to set balance: \(status)")
        }
    }
}
