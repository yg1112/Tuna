import Foundation
import CoreAudio

enum AudioScope {
    case input
    case output
}

struct AudioDevice: Identifiable, Hashable, Codable {
    let id: AudioDeviceID
    let name: String
    let uid: String
    let hasInput: Bool
    let hasOutput: Bool
    var isDefault: Bool = false  // 标记设备是否在当前可用列表中
    
    var volume: Float {
        get {
            getVolume()
        }
    }
    
    // Hashable implementation
    func hash(into hasher: inout Hasher) {
        hasher.combine(uid)
    }
    
    static func == (lhs: AudioDevice, rhs: AudioDevice) -> Bool {
        return lhs.uid == rhs.uid
    }
    
    // Codable implementation
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case uid
        case hasInput
        case hasOutput
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(AudioDeviceID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        uid = try container.decode(String.self, forKey: .uid)
        hasInput = try container.decode(Bool.self, forKey: .hasInput)
        hasOutput = try container.decode(Bool.self, forKey: .hasOutput)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(uid, forKey: .uid)
        try container.encode(hasInput, forKey: .hasInput)
        try container.encode(hasOutput, forKey: .hasOutput)
    }
    
    init?(deviceID: AudioDeviceID) {
        self.id = deviceID
        
        // 获取设备名称
        var propertySize = UInt32(MemoryLayout<CFString>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyName,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var deviceName = "" as CFString
        let nameStatus = AudioObjectGetPropertyData(
            deviceID,
            &address,
            0,
            nil,
            &propertySize,
            &deviceName
        )
        
        if nameStatus != noErr {
            print("获取设备名称失败: \(nameStatus)")
            return nil
        }
        
        // 获取设备 UID
        address.mSelector = kAudioDevicePropertyDeviceUID
        var deviceUID = "" as CFString
        let uidStatus = AudioObjectGetPropertyData(
            deviceID,
            &address,
            0,
            nil,
            &propertySize,
            &deviceUID
        )
        
        if uidStatus != noErr {
            print("获取设备 UID 失败: \(uidStatus)")
            return nil
        }
        
        self.name = deviceName as String
        self.uid = deviceUID as String
        
        // 检查输入/输出能力
        self.hasInput = Self.hasDeviceCapability(deviceID: deviceID, scope: kAudioObjectPropertyScopeInput)
        self.hasOutput = Self.hasDeviceCapability(deviceID: deviceID, scope: kAudioObjectPropertyScopeOutput)
    }
    
    private static func hasDeviceCapability(deviceID: AudioDeviceID, scope: AudioObjectPropertyScope) -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreamConfiguration,
            mScope: scope,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var propertySize: UInt32 = 0
        let status = AudioObjectGetPropertyDataSize(
            deviceID,
            &address,
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
            &address,
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
    
    private func hasVolumeControl(scope: AudioObjectPropertyScope) -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: scope,
            mElement: kAudioObjectPropertyElementMain
        )
        
        return AudioObjectHasProperty(id, &address)
    }
    
    private func getVolume() -> Float {
        let scope = hasInput ? kAudioDevicePropertyScopeInput : kAudioDevicePropertyScopeOutput
        
        // 检查是否支持音量控制
        if !hasVolumeControl(scope: scope) {
            return 1.0
        }
        
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: scope,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var volume: Float = 0.0
        var propertySize = UInt32(MemoryLayout<Float>.size)
        
        let status = AudioObjectGetPropertyData(
            id,
            &address,
            0,
            nil,
            &propertySize,
            &volume
        )
        
        if status != noErr {
            print("获取音量失败: \(status)")
            return 1.0
        }
        
        return volume
    }
    
    func setVolume(_ volume: Float) {
        let scope = hasInput ? kAudioDevicePropertyScopeInput : kAudioDevicePropertyScopeOutput
        
        // 检查是否支持音量控制
        if !hasVolumeControl(scope: scope) {
            return
        }
        
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: scope,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var volumeValue = volume
        let status = AudioObjectSetPropertyData(
            id,
            &address,
            0,
            nil,
            UInt32(MemoryLayout<Float>.size),
            &volumeValue
        )
        
        if status != noErr {
            print("设置音量失败: \(status)")
        }
    }
} 