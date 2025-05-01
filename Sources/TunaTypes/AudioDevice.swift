import CoreAudio
import Foundation

public typealias AudioObjectID = UInt32

public struct AudioDevice: Identifiable, Hashable {
    public let id: AudioObjectID
    public let name: String
    public let uid: String

    public init(id: AudioObjectID, name: String, uid: String) {
        self.id = id
        self.name = name
        self.uid = uid
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.uid)
    }

    public static func == (lhs: AudioDevice, rhs: AudioDevice) -> Bool {
        lhs.uid == rhs.uid
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
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )

        var size = UInt32(MemoryLayout<Float>.size)
        let status = AudioObjectGetPropertyData(
            id,
            &address,
            0,
            nil,
            &size,
            &volume
        )

        if status == noErr {
            return volume
        }

        return 0.0
    }
}
