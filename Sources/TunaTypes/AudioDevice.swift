import CoreAudio
import Foundation

public typealias AudioObjectID = UInt32

// Base audio device type with CoreAudio functionality
public protocol AudioDevice: Identifiable, Hashable, Codable {
    var id: AudioObjectID { get }
    var name: String { get }
    var uid: String { get }
    var isInput: Bool { get }
    var hasInput: Bool { get }
    var hasOutput: Bool { get }
    func getVolume() -> Float
    func setVolume(_ volume: Float)
}

// Concrete implementation of AudioDevice
public struct AudioDeviceImpl: AudioDevice {
    public let id: AudioObjectID
    public let name: String
    public let uid: String
    public let isInput: Bool

    public init(id: AudioObjectID, name: String, uid: String, isInput: Bool) {
        self.id = id
        self.name = name
        self.uid = uid
        self.isInput = isInput
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
        hasher.combine(self.isInput)
    }

    public static func == (lhs: AudioDeviceImpl, rhs: AudioDeviceImpl) -> Bool {
        lhs.id == rhs.id && lhs.isInput == rhs.isInput
    }

    public var hasInput: Bool {
        self.hasDeviceCapability(scope: kAudioDevicePropertyScopeInput)
    }

    public var hasOutput: Bool {
        self.hasDeviceCapability(scope: kAudioDevicePropertyScopeOutput)
    }

    private func hasDeviceCapability(scope: AudioObjectPropertyScope) -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreamConfiguration,
            mScope: scope,
            mElement: kAudioObjectPropertyElementMain
        )

        var propertySize: UInt32 = 0
        let result = AudioObjectGetPropertyDataSize(
            id,
            &address,
            0,
            nil,
            &propertySize
        )

        if result != noErr {
            return false
        }

        let bufferList = UnsafeMutablePointer<AudioBufferList>.allocate(capacity: 1)
        defer { bufferList.deallocate() }

        let status = AudioObjectGetPropertyData(
            id,
            &address,
            0,
            nil,
            &propertySize,
            bufferList
        )

        if status != noErr {
            return false
        }

        let bufferCount = Int(bufferList.pointee.mNumberBuffers)
        return bufferCount > 0
    }

    public func getVolume() -> Float {
        var volume: Float = 0.0
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: isInput ? kAudioDevicePropertyScopeInput : kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )

        var size = UInt32(MemoryLayout<Float>.size)
        let status = AudioObjectGetPropertyData(id, &address, 0, nil, &size, &volume)

        if status != noErr {
            print("Error getting volume: \(status)")
            return 0.0
        }

        return volume
    }

    public func setVolume(_ volume: Float) {
        var newVolume = volume
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: isInput ? kAudioDevicePropertyScopeInput : kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )

        let status = AudioObjectSetPropertyData(
            id,
            &address,
            0,
            nil,
            UInt32(MemoryLayout<Float>.size),
            &newVolume
        )

        if status != noErr {
            print("Error setting volume: \(status)")
        }
    }

    // MARK: - Static Device List Methods
    public static var allInputDevices: [any AudioDevice] {
        getDevices(isInput: true)
    }

    public static var allOutputDevices: [any AudioDevice] {
        getDevices(isInput: false)
    }

    private static func getDevices(isInput: Bool) -> [any AudioDevice] {
        var propertySize: UInt32 = 0
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        guard AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &propertySize
        ) == noErr else {
            return []
        }

        let deviceCount = Int(propertySize) / MemoryLayout<AudioDeviceID>.size
        var deviceIDs = [AudioDeviceID](repeating: 0, count: deviceCount)

        guard AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &propertySize,
            &deviceIDs
        ) == noErr else {
            return []
        }

        return deviceIDs.compactMap { deviceID in
            var name = ""
            var uid = ""

            // Get device name
            var propertySize = UInt32(MemoryLayout<CFString>.size)
            var nameAddress = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyDeviceNameCFString,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain
            )

            var cfName: CFString? = nil
            let cfNamePtr = UnsafeMutablePointer<CFString?>.allocate(capacity: 1)
            defer { cfNamePtr.deallocate() }

            guard AudioObjectGetPropertyData(
                deviceID,
                &nameAddress,
                0,
                nil,
                &propertySize,
                cfNamePtr
            ) == noErr else {
                return nil
            }
            cfName = cfNamePtr.pointee
            name = cfName as String? ?? ""

            // Get device UID
            var uidAddress = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyDeviceUID,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain
            )

            var cfUID: CFString? = nil
            let cfUIDPtr = UnsafeMutablePointer<CFString?>.allocate(capacity: 1)
            defer { cfUIDPtr.deallocate() }

            guard AudioObjectGetPropertyData(
                deviceID,
                &uidAddress,
                0,
                nil,
                &propertySize,
                cfUIDPtr
            ) == noErr else {
                return nil
            }
            cfUID = cfUIDPtr.pointee
            uid = cfUID as String? ?? ""

            // Check if device has input/output channels
            let device = AudioDeviceImpl(id: deviceID, name: name, uid: uid, isInput: isInput)
            return isInput ? (device.hasInput ? device : nil) : (device.hasOutput ? device : nil)
        }
    }
}
