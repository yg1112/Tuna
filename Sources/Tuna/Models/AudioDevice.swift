import Foundation
import CoreAudio

/// 表示一个音频设备
struct AudioDevice: Identifiable, Equatable {
    /// 设备的唯一标识符
    let id: AudioDeviceID
    /// 设备名称
    let name: String
    /// 是否为输入设备
    let isInput: Bool
    /// 是否为输出设备
    let isOutput: Bool
    /// 是否为蓝牙设备
    let isBluetooth: Bool
    /// 电池电量（如果适用）
    let batteryLevel: Int?
    
    static func == (lhs: AudioDevice, rhs: AudioDevice) -> Bool {
        return lhs.id == rhs.id
    }
} 