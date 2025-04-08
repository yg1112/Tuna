import Foundation
import CoreAudio
import CoreAudio.AudioHardware

// 定义一些可能不在CoreAudio中定义的常量
// VirtualMainVolume常量，用于蓝牙设备音量控制
let kAudioDevicePropertyVirtualMasterVolume: AudioObjectPropertySelector = 1886680930 // 'vmvc'
// 左右声道平衡属性
let kAudioDevicePropertyVirtualMasterBalance: AudioObjectPropertySelector = 1886680946 // 'vmba'
// 立体声平衡属性
let kAudioDevicePropertyStereoPan: AudioObjectPropertySelector = 1920233065 // 'span'
// 硬件服务虚拟主音量属性
let kAudioHardwareServiceDeviceProperty_VirtualMasterVolume: AudioObjectPropertySelector = 1936880500 // 'vmvc'

// AudioHardwareService函数声明（用于蓝牙设备）
@_silgen_name("AudioHardwareServiceSetPropertyData")
func AudioHardwareServiceSetPropertyData(_ inObjectID: AudioObjectID,
                                        _ inAddress: UnsafePointer<AudioObjectPropertyAddress>,
                                        _ inQualifierDataSize: UInt32,
                                        _ inQualifierData: UnsafeRawPointer?,
                                        _ inDataSize: UInt32,
                                        _ inData: UnsafeRawPointer) -> OSStatus

enum AudioScope {
    case input
    case output
}

public struct AudioDevice: Identifiable, Hashable, Codable {
    public let id: AudioDeviceID
    public let name: String
    public let uid: String
    public let hasInput: Bool
    public let hasOutput: Bool
    public var isDefault: Bool = false  // 标记设备是否在当前可用列表中
    public var supportsBalanceControl: Bool = false  // 是否支持平衡控制
    public var balanceLocked: Bool = false  // 是否锁定左右声道平衡
    
    public var volume: Float {
        get {
            getVolume()
        }
    }
    
    public var balance: Float {
        get {
            getBalance()
        }
    }
    
    // Hashable implementation
    public func hash(into hasher: inout Hasher) {
        hasher.combine(uid)
    }
    
    public static func == (lhs: AudioDevice, rhs: AudioDevice) -> Bool {
        return lhs.uid == rhs.uid
    }
    
    // Codable implementation
    public enum CodingKeys: String, CodingKey {
        case id
        case name
        case uid
        case hasInput
        case hasOutput
        case supportsBalanceControl
        case balanceLocked
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(AudioDeviceID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        uid = try container.decode(String.self, forKey: .uid)
        hasInput = try container.decode(Bool.self, forKey: .hasInput)
        hasOutput = try container.decode(Bool.self, forKey: .hasOutput)
        supportsBalanceControl = try container.decodeIfPresent(Bool.self, forKey: .supportsBalanceControl) ?? false
        balanceLocked = try container.decodeIfPresent(Bool.self, forKey: .balanceLocked) ?? false
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(uid, forKey: .uid)
        try container.encode(hasInput, forKey: .hasInput)
        try container.encode(hasOutput, forKey: .hasOutput)
        try container.encode(supportsBalanceControl, forKey: .supportsBalanceControl)
        try container.encode(balanceLocked, forKey: .balanceLocked)
    }
    
    public init?(deviceID: AudioDeviceID) {
        self.id = deviceID
        
        // 获取设备名称
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
            print("获取设备名称失败: \(nameStatus)")
            return nil
        }
        
        // 获取设备 UID
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
            print("获取设备 UID 失败: \(uidStatus)")
            return nil
        }
        
        self.name = deviceNameRef! as String
        self.uid = deviceUIDRef! as String
        
        // 检查输入/输出能力
        self.hasInput = Self.hasDeviceCapability(deviceID: deviceID, scope: kAudioObjectPropertyScopeInput)
        self.hasOutput = Self.hasDeviceCapability(deviceID: deviceID, scope: kAudioObjectPropertyScopeOutput)
        
        // 初始化时检测是否支持平衡控制
        let scope = self.hasInput ? kAudioDevicePropertyScopeInput : kAudioDevicePropertyScopeOutput
        
        // 尝试检测平衡控制支持
        var panPropertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStereoPan,
            mScope: scope,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var balancePropertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVirtualMasterBalance,
            mScope: scope,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var isSettable: DarwinBoolean = false
        
        // 检查是否支持标准立体声平衡
        if AudioObjectHasProperty(deviceID, &panPropertyAddress) {
            let status = AudioObjectIsPropertySettable(deviceID, &panPropertyAddress, &isSettable)
            if status == noErr && isSettable.boolValue {
                self.supportsBalanceControl = true
                print("设备 \(self.name) 支持StereoPan平衡控制")
            }
        }
        
        // 如果不支持标准平衡，检查是否支持虚拟平衡
        if !self.supportsBalanceControl && AudioObjectHasProperty(deviceID, &balancePropertyAddress) {
            let status = AudioObjectIsPropertySettable(deviceID, &balancePropertyAddress, &isSettable)
            if status == noErr && isSettable.boolValue {
                self.supportsBalanceControl = true
                print("设备 \(self.name) 支持VirtualMasterBalance平衡控制")
            }
        }
        
        if !self.supportsBalanceControl {
            print("设备 \(self.name) 不支持平衡控制")
        }
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
    
    func hasVolumeControl() -> Bool {
        print("检查设备 \(name) 是否支持音量控制")
        
        let scope = hasInput ? kAudioDevicePropertyScopeInput : kAudioDevicePropertyScopeOutput
        
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: scope,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let hasVolume = AudioObjectHasProperty(id, &address)
        print("设备 \(name) 音量控制支持状态: \(hasVolume)")
        
        if hasVolume {
            var isSettable: DarwinBoolean = false
            let status = AudioObjectIsPropertySettable(id, &address, &isSettable)
            if status == noErr && isSettable.boolValue {
                print("设备 \(name) 音量可以设置")
                return true
            }
        }
        
        print("设备 \(name) 不支持音量控制")
        return false
    }
    
    // 添加用于获取蓝牙设备音量的专用方法
    func getBluetoothDeviceVolume() -> Float {
        let scope = hasInput ? kAudioDevicePropertyScopeInput : kAudioDevicePropertyScopeOutput
        var volume: Float32 = 0.0
        var size = UInt32(MemoryLayout<Float32>.size)
        
        print("获取蓝牙设备 \(name) (UID: \(uid)) 音量")
        
        // 特别为蓝牙设备使用硬件服务属性
        var hardwareServiceAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMasterVolume,
            mScope: scope,
            mElement: kAudioObjectPropertyElementMain
        )
        
        if AudioObjectHasProperty(id, &hardwareServiceAddress) {
            let status = AudioObjectGetPropertyData(id, &hardwareServiceAddress, 0, nil, &size, &volume)
            if status == noErr {
                print("使用硬件服务属性获取蓝牙设备 \(name) 音量: \(volume)")
                return volume
            } else {
                print("硬件服务属性获取蓝牙设备 \(name) 音量失败: \(status)")
            }
        }
        
        // 尝试其他属性
        let volumeProperties: [AudioObjectPropertySelector] = [
            kAudioDevicePropertyVirtualMasterVolume,
            kAudioDevicePropertyVolumeScalar
        ]
        
        for property in volumeProperties {
            for element in [kAudioObjectPropertyElementMain, 1] as [UInt32] {
                var address = AudioObjectPropertyAddress(
                    mSelector: property,
                    mScope: scope,
                    mElement: element
                )
                
                if AudioObjectHasProperty(id, &address) {
                    let status = AudioObjectGetPropertyData(id, &address, 0, nil, &size, &volume)
                    if status == noErr {
                        print("使用属性 \(property) (元素: \(element)) 获取蓝牙设备 \(name) 音量: \(volume)")
                        return volume
                    }
                }
            }
        }
        
        print("无法获取蓝牙设备 \(name) 音量，使用默认值1.0")
        return 1.0
    }
    
    // 修改getVolume方法，检测蓝牙设备并调用专用方法
    public func getVolume() -> Float {
        // 检查是否为蓝牙设备
        let isBluetoothDevice = uid.lowercased().contains("bluetooth")
        if isBluetoothDevice {
            return getBluetoothDeviceVolume()
        }
        
        let scope = hasInput ? kAudioDevicePropertyScopeInput : kAudioDevicePropertyScopeOutput
        var volume: Float32 = 0.0
        var size = UInt32(MemoryLayout<Float32>.size)
        
        // 定义多种可能的音量属性
        let volumeProperties: [AudioObjectPropertySelector] = [
            kAudioDevicePropertyVirtualMasterVolume,          // 虚拟主音量
            kAudioHardwareServiceDeviceProperty_VirtualMasterVolume, // 硬件服务虚拟主音量
            kAudioDevicePropertyVolumeScalar,                // 标准音量
        ]
        
        // 尝试每种属性
        for property in volumeProperties {
            var address = AudioObjectPropertyAddress(
                mSelector: property,
                mScope: scope,
                mElement: kAudioObjectPropertyElementMain
            )
            
            if AudioObjectHasProperty(id, &address) {
                let status = AudioObjectGetPropertyData(id, &address, 0, nil, &size, &volume)
                if status == noErr {
                    print("使用属性 \(property) 获取设备 \(name) 音量: \(volume)")
                    return volume
                }
            }
        }
        
        // 尝试第一个通道
        for property in volumeProperties {
            var address = AudioObjectPropertyAddress(
                mSelector: property,
                mScope: scope,
                mElement: 1  // 第一个通道
            )
            
            if AudioObjectHasProperty(id, &address) {
                let status = AudioObjectGetPropertyData(id, &address, 0, nil, &size, &volume)
                if status == noErr {
                    print("使用属性 \(property) (通道1) 获取设备 \(name) 音量: \(volume)")
                    return volume
                }
            }
        }
        
        print("获取设备 \(name) 音量失败，使用默认值1.0")
        return 1.0
    }
    
    // 获取左右声道平衡，返回-1到1之间的值，-1为左声道，0为居中，1为右声道
    public func getBalance() -> Float {
        let scope = hasInput ? kAudioDevicePropertyScopeInput : kAudioDevicePropertyScopeOutput
        var balance: Float32 = 0.0 // 默认居中
        var size = UInt32(MemoryLayout<Float32>.size)
        
        // 首先尝试VirtualMasterBalance
        var virtualAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVirtualMasterBalance,
            mScope: scope,
            mElement: kAudioObjectPropertyElementMain
        )
        
        if AudioObjectHasProperty(id, &virtualAddress) {
            let status = AudioObjectGetPropertyData(id, &virtualAddress, 0, nil, &size, &balance)
            if status == noErr {
                print("使用VirtualMasterBalance获取设备 \(name) 平衡: \(balance)")
                return balance
            }
        }
        
        // 尝试标准Balance属性
        var balanceAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStereoPan,
            mScope: scope,
            mElement: kAudioObjectPropertyElementMain
        )
        
        if AudioObjectHasProperty(id, &balanceAddress) {
            let status = AudioObjectGetPropertyData(id, &balanceAddress, 0, nil, &size, &balance)
            if status == noErr {
                print("获取设备 \(name) 平衡: \(balance)")
                return balance
            }
        }
        
        // 如果设备不支持平衡控制，默认为居中
        print("设备 \(name) 不支持平衡控制，使用默认值0.0（居中）")
        return 0.0
    }
    
    // 设置左右声道平衡
    func setBalance(_ balance: Float) -> Bool {
        let scope = hasInput ? kAudioDevicePropertyScopeInput : kAudioDevicePropertyScopeOutput
        // 确保平衡值在-1到1之间
        var newBalance = max(-1.0, min(1.0, balance))
        
        print("尝试设置设备 \(name) (UID: \(uid)) 的平衡为 \(newBalance)")
        
        // 首先尝试VirtualMasterBalance
        var virtualAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVirtualMasterBalance,
            mScope: scope,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var success = false
        
        if AudioObjectHasProperty(id, &virtualAddress) {
            var isSettable: DarwinBoolean = false
            var status = AudioObjectIsPropertySettable(id, &virtualAddress, &isSettable)
            
            print("设备 \(name) VirtualMasterBalance属性可设置状态: \(isSettable.boolValue), 状态码: \(status)")
            
            if status == noErr && isSettable.boolValue {
                status = AudioObjectSetPropertyData(
                    id,
                    &virtualAddress,
                    0,
                    nil,
                    UInt32(MemoryLayout<Float32>.size),
                    &newBalance
                )
                
                if status == noErr {
                    print("使用VirtualMasterBalance成功设置设备 \(name) 平衡: \(newBalance)")
                    success = true
                } else {
                    print("使用VirtualMasterBalance设置设备 \(name) 平衡失败: \(status)")
                }
            }
        }
        
        // 如果VirtualMasterBalance失败，尝试标准的平衡属性
        if !success {
            var balanceAddress = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyStereoPan,
                mScope: scope,
                mElement: kAudioObjectPropertyElementMain
            )
            
            if AudioObjectHasProperty(id, &balanceAddress) {
                var isSettable: DarwinBoolean = false
                var status = AudioObjectIsPropertySettable(id, &balanceAddress, &isSettable)
                
                if status == noErr && isSettable.boolValue {
                    status = AudioObjectSetPropertyData(
                        id,
                        &balanceAddress,
                        0,
                        nil,
                        UInt32(MemoryLayout<Float32>.size),
                        &newBalance
                    )
                    
                    if status == noErr {
                        print("成功设置设备 \(name) 平衡: \(newBalance)")
                        success = true
                    } else {
                        print("设置设备 \(name) 平衡失败: \(status)")
                    }
                }
            }
        }
        
        return success
    }
    
    // 重置左右声道平衡到中间位置
    func resetBalance() -> Bool {
        return setBalance(0.0)
    }
    
    func setVolume(_ volume: Float) -> Bool {
        let scope = hasInput ? kAudioDevicePropertyScopeInput : kAudioDevicePropertyScopeOutput
        var newVolume = max(0.0, min(1.0, volume))
        
        print("尝试设置设备 \(name) (UID: \(uid)) 的音量为 \(newVolume)")
        
        // 记录当前平衡，以便在设置音量后恢复
        let currentBalance = getBalance()
        
        // 如果平衡已锁定，使用专用方法按照锁定的平衡值设置音量
        if balanceLocked && supportsBalanceControl {
            print("平衡已锁定，使用锁定的平衡值 \(currentBalance) 设置音量")
            return setVolumeWithLockedBalance(newVolume, balance: currentBalance)
        }
        
        // 检查是否为蓝牙设备
        let isBluetoothDevice = uid.lowercased().contains("bluetooth")
        if isBluetoothDevice {
            print("检测到蓝牙设备，使用专用方法设置音量")
            return setBluetoothDeviceVolume(newVolume, currentBalance: currentBalance)
        }
        
        // 定义多种可能的音量属性
        let volumeProperties: [AudioObjectPropertySelector] = [
            kAudioDevicePropertyVirtualMasterVolume,           // 虚拟主音量
            kAudioHardwareServiceDeviceProperty_VirtualMasterVolume,  // 硬件服务虚拟主音量
            kAudioDevicePropertyVolumeScalar,                 // 标准音量
        ]
        
        // 尝试多个元素
        let elements: [UInt32] = [kAudioObjectPropertyElementMain, 1] // 主元素和第一个通道
        
        var success = false
        
        // 尝试每种属性
        for property in volumeProperties {
            for element in elements {
                var address = AudioObjectPropertyAddress(
                    mSelector: property,
                    mScope: scope,
                    mElement: element
                )
                
                if AudioObjectHasProperty(id, &address) {
                    var isSettable: DarwinBoolean = false
                    var status = AudioObjectIsPropertySettable(id, &address, &isSettable)
                    
                    print("设备 \(name) 属性 \(property) (元素: \(element)) 可设置状态: \(isSettable.boolValue), 状态码: \(status)")
                    
                    if status == noErr && isSettable.boolValue {
                        status = AudioObjectSetPropertyData(
                            id,
                            &address,
                            0,
                            nil,
                            UInt32(MemoryLayout<Float32>.size),
                            &newVolume
                        )
                        
                        if status == noErr {
                            print("使用属性 \(property) (元素: \(element)) 成功设置设备 \(name) 音量: \(newVolume)")
                            success = true
                            break
                        } else {
                            print("使用属性 \(property) (元素: \(element)) 设置设备 \(name) 音量失败: \(status)")
                        }
                    }
                }
            }
            
            if success {
                break
            }
        }
        
        if success {
            print("成功设置设备 \(name) 音量")
            // 如果平衡不是居中位置，尝试恢复平衡
            if currentBalance != 0.0 {
                print("恢复设备 \(name) 的平衡值: \(currentBalance)")
                _ = setBalance(currentBalance)
            }
        } else {
            print("所有方法均无法设置设备 \(name) 音量")
        }
        
        return success
    }
    
    // 专门为蓝牙设备设置音量的方法
    private func setBluetoothDeviceVolume(_ volume: Float, currentBalance: Float) -> Bool {
        let scope = hasInput ? kAudioDevicePropertyScopeInput : kAudioDevicePropertyScopeOutput
        var newVolume = volume
        
        // 如果平衡已锁定，并且设备支持平衡控制，使用专用方法保持平衡
        if balanceLocked && supportsBalanceControl {
            print("蓝牙设备平衡已锁定，使用锁定的平衡值 \(currentBalance) 设置音量")
            return setVolumeWithLockedBalance(newVolume, balance: currentBalance)
        }
        
        // 首先尝试使用AudioHardwareService
        var virtualAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMasterVolume,
            mScope: scope,
            mElement: kAudioObjectPropertyElementMain
        )
        
        if AudioObjectHasProperty(id, &virtualAddress) {
            let status = AudioHardwareServiceSetPropertyData(
                id,
                &virtualAddress,
                0,
                nil,
                UInt32(MemoryLayout<Float32>.size),
                &newVolume
            )
            
            if status == noErr {
                print("使用AudioHardwareService成功设置蓝牙设备 \(name) 音量: \(newVolume)")
                
                // 如果平衡不是居中位置，尝试恢复平衡
                if currentBalance != 0.0 {
                    print("恢复蓝牙设备 \(name) 的平衡值: \(currentBalance)")
                    _ = setBalance(currentBalance)
                }
                
                return true
            } else {
                print("使用AudioHardwareService设置蓝牙设备 \(name) 音量失败: \(status)")
            }
        }
        
        // 然后尝试标准的设置方法（对某些蓝牙设备有效）
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVirtualMasterVolume,
            mScope: scope,
            mElement: kAudioObjectPropertyElementMain
        )
        
        if AudioObjectHasProperty(id, &address) {
            var isSettable: DarwinBoolean = false
            let checkStatus = AudioObjectIsPropertySettable(id, &address, &isSettable)
            
            if checkStatus == noErr && isSettable.boolValue {
                let status = AudioObjectSetPropertyData(
                    id,
                    &address,
                    0,
                    nil,
                    UInt32(MemoryLayout<Float32>.size),
                    &newVolume
                )
                
                if status == noErr {
                    print("使用VirtualMasterVolume成功设置蓝牙设备 \(name) 音量: \(newVolume)")
                    
                    // 如果平衡不是居中位置，尝试恢复平衡
                    if currentBalance != 0.0 {
                        print("恢复蓝牙设备 \(name) 的平衡值: \(currentBalance)")
                        _ = setBalance(currentBalance)
                    }
                    
                    return true
                } else {
                    print("使用VirtualMasterVolume设置蓝牙设备 \(name) 音量失败: \(status)")
                }
            }
        }
        
        // 最后尝试在左右声道上分别设置音量
        let channelSelectors: [AudioObjectPropertySelector] = [
            kAudioDevicePropertyVolumeScalar,
            kAudioDevicePropertyVirtualMasterVolume
        ]
        
        var success = false
        for selector in channelSelectors {
            var leftAddress = AudioObjectPropertyAddress(
                mSelector: selector,
                mScope: scope,
                mElement: 1  // 左声道
            )
            
            var rightAddress = AudioObjectPropertyAddress(
                mSelector: selector,
                mScope: scope,
                mElement: 2  // 右声道
            )
            
            if AudioObjectHasProperty(id, &leftAddress) && AudioObjectHasProperty(id, &rightAddress) {
                let leftStatus = AudioObjectSetPropertyData(
                    id,
                    &leftAddress,
                    0,
                    nil,
                    UInt32(MemoryLayout<Float32>.size),
                    &newVolume
                )
                
                let rightStatus = AudioObjectSetPropertyData(
                    id,
                    &rightAddress,
                    0,
                    nil,
                    UInt32(MemoryLayout<Float32>.size),
                    &newVolume
                )
                
                if leftStatus == noErr && rightStatus == noErr {
                    print("成功分别设置蓝牙设备 \(name) 左右声道音量: \(newVolume)")
                    success = true
                    break
                }
            }
        }
        
        if success {
            // 如果平衡不是居中位置，尝试恢复平衡
            if currentBalance != 0.0 {
                print("恢复蓝牙设备 \(name) 的平衡值: \(currentBalance)")
                _ = setBalance(currentBalance)
            }
            return true
        }
        
        print("无法设置蓝牙设备 \(name) 的音量")
        return false
    }
    
    // 新增: 设置左声道的音量
    func setLeftChannelVolume(_ volume: Float) -> Bool {
        let scope = hasInput ? kAudioDevicePropertyScopeInput : kAudioDevicePropertyScopeOutput
        var newVolume = max(0.0, min(1.0, volume))
        
        print("尝试设置设备 \(name) 左声道音量为 \(newVolume)")
        
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: scope,
            mElement: 1  // 左声道
        )
        
        if AudioObjectHasProperty(id, &address) {
            let status = AudioObjectSetPropertyData(
                id,
                &address,
                0,
                nil,
                UInt32(MemoryLayout<Float32>.size),
                &newVolume
            )
            
            if status == noErr {
                print("成功设置左声道音量: \(newVolume)")
                return true
            } else {
                print("设置左声道音量失败: \(status)")
            }
        }
        
        print("设备不支持单独设置左声道音量")
        return false
    }
    
    // 新增: 设置右声道的音量
    func setRightChannelVolume(_ volume: Float) -> Bool {
        let scope = hasInput ? kAudioDevicePropertyScopeInput : kAudioDevicePropertyScopeOutput
        var newVolume = max(0.0, min(1.0, volume))
        
        print("尝试设置设备 \(name) 右声道音量为 \(newVolume)")
        
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: scope,
            mElement: 2  // 右声道
        )
        
        if AudioObjectHasProperty(id, &address) {
            let status = AudioObjectSetPropertyData(
                id,
                &address,
                0,
                nil,
                UInt32(MemoryLayout<Float32>.size),
                &newVolume
            )
            
            if status == noErr {
                print("成功设置右声道音量: \(newVolume)")
                return true
            } else {
                print("设置右声道音量失败: \(status)")
            }
        }
        
        print("设备不支持单独设置右声道音量")
        return false
    }
    
    // 新增: 获取左声道的音量
    func getLeftChannelVolume() -> Float {
        let scope = hasInput ? kAudioDevicePropertyScopeInput : kAudioDevicePropertyScopeOutput
        var volume: Float32 = 0.0
        var size = UInt32(MemoryLayout<Float32>.size)
        
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: scope,
            mElement: 1  // 左声道
        )
        
        if AudioObjectHasProperty(id, &address) {
            let status = AudioObjectGetPropertyData(id, &address, 0, nil, &size, &volume)
            if status == noErr {
                print("获取设备 \(name) 左声道音量: \(volume)")
                return volume
            }
        }
        
        print("无法获取左声道音量，使用主音量代替")
        return getVolume()
    }
    
    // 新增: 获取右声道的音量
    func getRightChannelVolume() -> Float {
        let scope = hasInput ? kAudioDevicePropertyScopeInput : kAudioDevicePropertyScopeOutput
        var volume: Float32 = 0.0
        var size = UInt32(MemoryLayout<Float32>.size)
        
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: scope,
            mElement: 2  // 右声道
        )
        
        if AudioObjectHasProperty(id, &address) {
            let status = AudioObjectGetPropertyData(id, &address, 0, nil, &size, &volume)
            if status == noErr {
                print("获取设备 \(name) 右声道音量: \(volume)")
                return volume
            }
        }
        
        print("无法获取右声道音量，使用主音量代替")
        return getVolume()
    }
    
    // 使用锁定平衡值设置音量的增强方法
    func setVolumeWithLockedBalance(_ volume: Float, balance: Float) -> Bool {
        let scope = hasInput ? kAudioDevicePropertyScopeInput : kAudioDevicePropertyScopeOutput
        let newVolume = max(0.0, min(1.0, volume))
        
        print("使用锁定的平衡值 \(balance) 设置设备 \(name) 音量: \(newVolume)")
        
        // 检查是否为蓝牙设备
        let isBluetoothDevice = uid.lowercased().contains("bluetooth")
        
        // 对于蓝牙设备，首先尝试使用左右声道单独设置的方式
        if isBluetoothDevice {
            // 尝试使用左右声道单独设置的方式
            let result = trySetVolumeWithLockedBalanceUsingChannels(newVolume, balance: balance)
            if result {
                return true
            }
            
            // 否则尝试使用主音量设置然后立即恢复平衡
            return trySetVolumeWithLockedBalanceUsingMainVolume(newVolume, balance: balance)
        }
        
        // 对于非蓝牙设备，尝试直接使用左右声道设置
        if trySetVolumeWithLockedBalanceUsingChannels(newVolume, balance: balance) {
            return true
        }
        
        // 如果左右声道设置失败，尝试主音量设置然后恢复平衡
        return trySetVolumeWithLockedBalanceUsingMainVolume(newVolume, balance: balance)
    }
    
    // 使用左右声道分别设置来实现平衡锁定
    private func trySetVolumeWithLockedBalanceUsingChannels(_ volume: Float, balance: Float) -> Bool {
        let newVolume = max(0.0, min(1.0, volume))
        
        // 根据平衡值计算左右声道的音量
        // balance范围: -1.0(完全左)到1.0(完全右)
        var leftVolume = newVolume
        var rightVolume = newVolume
        
        if balance < 0 {  // 偏左
            rightVolume = newVolume * (1 + balance)
        } else if balance > 0 {  // 偏右
            leftVolume = newVolume * (1 - balance)
        }
        
        print("计算后的左声道音量: \(leftVolume), 右声道音量: \(rightVolume)")
        
        // 设置左右声道音量
        let leftSuccess = setLeftChannelVolume(leftVolume)
        let rightSuccess = setRightChannelVolume(rightVolume)
        
        return leftSuccess && rightSuccess
    }
    
    // 使用主音量设置然后恢复平衡的方式实现平衡锁定
    private func trySetVolumeWithLockedBalanceUsingMainVolume(_ volume: Float, balance: Float) -> Bool {
        let scope = hasInput ? kAudioDevicePropertyScopeInput : kAudioDevicePropertyScopeOutput
        let newVolume = max(0.0, min(1.0, volume))
        
        // 先保存当前平衡状态，防止被覆盖
        let savedBalance = balance
        
        // 定义多种可能的音量属性
        let volumeProperties: [AudioObjectPropertySelector] = [
            kAudioDevicePropertyVirtualMasterVolume,           // 虚拟主音量
            kAudioHardwareServiceDeviceProperty_VirtualMasterVolume,  // 硬件服务虚拟主音量
            kAudioDevicePropertyVolumeScalar,                 // 标准音量
        ]
        
        // 尝试多个元素
        let elements: [UInt32] = [kAudioObjectPropertyElementMain, 1] // 主元素和第一个通道
        
        var success = false
        
        // 尝试每种属性
        for property in volumeProperties {
            for element in elements {
                var address = AudioObjectPropertyAddress(
                    mSelector: property,
                    mScope: scope,
                    mElement: element
                )
                
                if AudioObjectHasProperty(id, &address) {
                    var isSettable: DarwinBoolean = false
                    var status = AudioObjectIsPropertySettable(id, &address, &isSettable)
                    
                    if status == noErr && isSettable.boolValue {
                        var volumeCopy = newVolume
                        status = AudioObjectSetPropertyData(
                            id,
                            &address,
                            0,
                            nil,
                            UInt32(MemoryLayout<Float32>.size),
                            &volumeCopy
                        )
                        
                        if status == noErr {
                            print("成功设置设备 \(name) 主音量: \(newVolume)")
                            success = true
                            break
                        }
                    }
                }
            }
            
            if success {
                break
            }
        }
        
        // 如果蓝牙设备，尝试使用AudioHardwareService
        if !success && uid.lowercased().contains("bluetooth") {
            var virtualAddress = AudioObjectPropertyAddress(
                mSelector: kAudioHardwareServiceDeviceProperty_VirtualMasterVolume,
                mScope: scope,
                mElement: kAudioObjectPropertyElementMain
            )
            
            if AudioObjectHasProperty(id, &virtualAddress) {
                var volumeCopy = newVolume
                let status = AudioHardwareServiceSetPropertyData(
                    id,
                    &virtualAddress,
                    0,
                    nil,
                    UInt32(MemoryLayout<Float32>.size),
                    &volumeCopy
                )
                
                if status == noErr {
                    print("使用AudioHardwareService成功设置蓝牙设备 \(name) 音量: \(newVolume)")
                    success = true
                }
            }
        }
        
        // 如果成功设置主音量，立即恢复平衡
        if success {
            print("恢复设备 \(name) 平衡值: \(savedBalance)")
            _ = setBalance(savedBalance)
            
            // 再次检查当前平衡，确保已恢复
            let currentBalance = getBalance()
            if abs(currentBalance - savedBalance) > 0.01 {
                print("平衡值未正确恢复，再次尝试 (当前: \(currentBalance), 目标: \(savedBalance))")
                _ = setBalance(savedBalance)
            }
        }
        
        return success
    }
    
    // 添加检测设备类型的方法
    var isBuiltInSpeaker: Bool {
        return name.contains("Built-in") || 
               name.contains("MacBook") || 
               name.contains("Internal") || 
               uid.contains("BuildIn") ||
               uid.contains("MacBook")
    }
    
    // 添加检测设备是否支持平衡控制的辅助方法
    func checkSupportsBalanceControl() -> Bool {
        let scope = hasInput ? kAudioDevicePropertyScopeInput : kAudioDevicePropertyScopeOutput
        
        // 尝试检测平衡控制支持
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStereoPan,
            mScope: scope,
            mElement: kAudioObjectPropertyElementMain
        )
        
        if AudioObjectHasProperty(id, &propertyAddress) {
            var isSettable: DarwinBoolean = false
            let status = AudioObjectIsPropertySettable(id, &propertyAddress, &isSettable)
            if status == noErr && isSettable.boolValue {
                return true
            }
        }
        
        // 尝试检测虚拟平衡控制支持
        propertyAddress.mSelector = kAudioDevicePropertyVirtualMasterBalance
        if AudioObjectHasProperty(id, &propertyAddress) {
            var isSettable: DarwinBoolean = false
            let status = AudioObjectIsPropertySettable(id, &propertyAddress, &isSettable)
            if status == noErr && isSettable.boolValue {
                return true
            }
        }
        
        return false
    }
    
    // 添加锁定或解锁平衡的方法
    mutating func toggleBalanceLock() -> Bool {
        if supportsBalanceControl {
            balanceLocked = !balanceLocked
            print("\(balanceLocked ? "锁定" : "解锁")设备 \(name) 的平衡值: \(getBalance())")
            return true
        } else {
            print("设备 \(name) 不支持平衡控制，无法\(balanceLocked ? "锁定" : "解锁")平衡")
            return false
        }
    }
    
    // 设置平衡锁定状态
    mutating func setBalanceLock(_ locked: Bool) -> Bool {
        if supportsBalanceControl {
            balanceLocked = locked
            print("\(balanceLocked ? "锁定" : "解锁")设备 \(name) 的平衡值: \(getBalance())")
            return true
        } else {
            print("设备 \(name) 不支持平衡控制，无法\(locked ? "锁定" : "解锁")平衡")
            return false
        }
    }
    
    // 获取平衡锁定状态
    func isBalanceLocked() -> Bool {
        return balanceLocked
    }
} 