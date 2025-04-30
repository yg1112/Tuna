import AVFoundation
import Combine
import CoreAudio
import Foundation
import SwiftUI

public class AudioManager: ObservableObject {
    public static let shared = AudioManager()

    @Published public private(set) var outputDevices: [AudioDevice] = []
    @Published public private(set) var inputDevices: [AudioDevice] = []
    @Published public private(set) var selectedOutputDevice: AudioDevice?
    @Published public private(set) var selectedInputDevice: AudioDevice?
    @Published public private(set) var outputVolume: Float = 0.0
    @Published public private(set) var inputVolume: Float = 0.0
    @Published private(set) var outputBalance: Float = 0.0
    @Published private(set) var inputBalance: Float = 0.0
    @Published public var historicalOutputDevices: [AudioDevice] = []
    @Published public var historicalInputDevices: [AudioDevice] = []
    // 保留输出设备平衡锁定功能，删除输入设备平衡锁定
    @Published var isOutputBalanceLocked: Bool = false
    // 移除输入设备平衡锁定状态
    // @Published var isInputBalanceLocked: Bool = false
    // 存储锁定的平衡值
    private var lockedOutputBalance: Float = 0.0
    // 移除输入设备锁定平衡值
    // private var lockedInputBalance: Float = 0.0

    private var deviceListenerID: AudioObjectPropertyListenerProc?
    private var defaultInputListenerID: AudioObjectPropertyListenerProc?
    private var defaultOutputListenerID: AudioObjectPropertyListenerProc?
    private var inputVolumeListenerID: AudioObjectPropertyListenerProc?
    private var outputVolumeListenerID: AudioObjectPropertyListenerProc?
    private let settings = TunaSettings.shared

    private var userSelectedOutputUID: String?
    private var userSelectedInputUID: String?

    private var deviceListenerQueue = DispatchQueue(label: "com.tuna.deviceListener")
    private var deviceListener: AudioObjectPropertyListenerBlock?

    // 蓝牙设备音量轮询定时器
    private var volumePollingTimer: Timer?
    private var lastBluetoothOutputVolume: Float = -1
    private var lastBluetoothInputVolume: Float = -1
    private var isPollingForVolumeChanges = false

    // 输入设备音量变化回调
    private let inputVolumeChanged: AudioObjectPropertyListenerProc =
        { inObjectID, inNumberAddresses, inAddresses, inClientData in
            guard let clientData = inClientData else { return noErr }
            let manager = Unmanaged<AudioManager>.fromOpaque(clientData).takeUnretainedValue()

            // 只在当前输入设备ID匹配时处理
            DispatchQueue.main.async {
                if let device = manager.selectedInputDevice, device.id == inObjectID {
                    let oldVolume = manager.inputVolume
                    let newVolume = device.getVolume()
                    Swift.print("输入设备 \(device.name) 音量更新为: \(newVolume) (原音量: \(oldVolume))")

                    // 检查音量变化是否显著（避免微小波动导致的循环更新）
                    if abs(oldVolume - newVolume) > 0.001 {
                        manager.inputVolume = newVolume

                        // 如果是蓝牙设备，可能需要特殊处理
                        if device.uid.lowercased().contains("bluetooth") {
                            print("蓝牙设备音量变化更新: \(device.name)")
                            // 某些蓝牙设备在音量变化时可能需要刷新平衡值
                            let balance = device.getBalance()
                            if balance != manager.inputBalance {
                                manager.inputBalance = balance
                                print("蓝牙设备 \(device.name) 平衡更新为: \(balance)")
                            }

                            // 更新轮询基准值
                            manager.lastBluetoothInputVolume = newVolume
                        }
                    }
                }
            }

            return noErr
        }

    // 输出设备音量变化回调
    private let outputVolumeChanged: AudioObjectPropertyListenerProc =
        { inObjectID, inNumberAddresses, inAddresses, inClientData in
            guard let clientData = inClientData else { return noErr }
            let manager = Unmanaged<AudioManager>.fromOpaque(clientData).takeUnretainedValue()

            // 只在当前输出设备ID匹配时处理
            DispatchQueue.main.async {
                if let device = manager.selectedOutputDevice, device.id == inObjectID {
                    let oldVolume = manager.outputVolume
                    let newVolume = device.getVolume()
                    print("输出设备 \(device.name) 音量更新为: \(newVolume) (原音量: \(oldVolume))")

                    // 检查音量变化是否显著（避免微小波动导致的循环更新）
                    if abs(oldVolume - newVolume) > 0.001 {
                        manager.outputVolume = newVolume

                        // 如果是蓝牙设备，可能需要特殊处理
                        if device.uid.lowercased().contains("bluetooth") {
                            print("蓝牙设备音量变化更新: \(device.name)")
                            // 某些蓝牙设备在音量变化时可能需要刷新平衡值
                            let balance = device.getBalance()
                            if balance != manager.outputBalance {
                                manager.outputBalance = balance
                                print("蓝牙设备 \(device.name) 平衡更新为: \(balance)")
                            }

                            // 更新轮询基准值
                            manager.lastBluetoothOutputVolume = newVolume
                        }
                    }
                }
            }

            return noErr
        }

    private init() {
        print("===== 初始化 AudioManager =====")

        // 首先获取设备信息和音量，确保音量初始值的准确性
        self.loadHistoricalDevices() // 先加载历史设备
        self.setupDeviceListeners() // 设置监听器
        self.updateDevices() // 更新当前设备列表

        // 强制使用系统API初始化音量值 (关键步骤)
        self.initialSystemVolumeSync()

        // 应用默认设备设置 - 确保在所有设备加载完成后应用设置
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.applyDefaultDeviceSettings() // 应用默认音频设备
            print("\u{001B}[32m[初始化]\u{001B}[0m 应用默认音频设备设置完成")

            // 检查是否启用了Smart Swaps，如果是则应用首选设备设置
            let smartSwapsEnabled = UserDefaults.standard.bool(forKey: "enableSmartDeviceSwapping")
            if smartSwapsEnabled {
                print("\u{001B}[32m[初始化]\u{001B}[0m Smart Swaps已启用，正在应用首选设备设置")
                self.forceApplySmartDeviceSwapping()
            }

            fflush(stdout)
        }

        // 设置系统级音量监听器
        self.setupSystemAudioVolumeListener()
    }

    // 设置设备监听器
    private func setupDeviceListeners() {
        print("\u{001B}[34m[初始化]\u{001B}[0m 设置设备变化监听器")

        // 监听设备列表变化
        var devicesAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        AudioObjectAddPropertyListener(
            AudioObjectID(kAudioObjectSystemObject),
            &devicesAddress,
            { _, _, _, clientData in
                let manager = Unmanaged<AudioManager>.fromOpaque(clientData!).takeUnretainedValue()
                DispatchQueue.main.async {
                    manager.updateDevices()

                    // 检查是否启用了Smart Swaps并应用设置
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        let smartSwapsEnabled = UserDefaults.standard
                            .bool(forKey: "enableSmartDeviceSwapping")
                        if smartSwapsEnabled {
                            print("\u{001B}[32m[设备监听]\u{001B}[0m 检测到设备变化，应用Smart Swaps设置")
                            manager.forceApplySmartDeviceSwapping()
                        }
                    }
                }
                return noErr
            },
            Unmanaged.passUnretained(self).toOpaque()
        )

        // 监听默认输出设备变化
        var outputAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        AudioObjectAddPropertyListener(
            AudioObjectID(kAudioObjectSystemObject),
            &outputAddress,
            { _, _, _, clientData in
                let manager = Unmanaged<AudioManager>.fromOpaque(clientData!).takeUnretainedValue()
                DispatchQueue.main.async {
                    manager.updateDefaultDevices()
                }
                return noErr
            },
            Unmanaged.passUnretained(self).toOpaque()
        )

        // 监听默认输入设备变化
        var inputAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        AudioObjectAddPropertyListener(
            AudioObjectID(kAudioObjectSystemObject),
            &inputAddress,
            { _, _, _, clientData in
                let manager = Unmanaged<AudioManager>.fromOpaque(clientData!).takeUnretainedValue()
                DispatchQueue.main.async {
                    manager.updateDefaultDevices()
                }
                return noErr
            },
            Unmanaged.passUnretained(self).toOpaque()
        )
    }

    // 保存设备选择到UserDefaults
    private func saveDeviceSelection() {
        if let outputDevice = selectedOutputDevice {
            UserDefaults.standard.set(outputDevice.uid, forKey: "selectedOutputDeviceUID")
        }

        if let inputDevice = selectedInputDevice {
            UserDefaults.standard.set(inputDevice.uid, forKey: "selectedInputDeviceUID")
        }
    }

    private func getAudioDevices(scope: AudioScope) -> [AudioDevice] {
        var deviceList = [AudioDevice]()

        // 获取所有音频设备
        var propertySize: UInt32 = 0
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        let result = AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &propertySize
        )

        if result != noErr {
            print("获取设备列表大小失败: \(result)")
            return []
        }

        let deviceCount = Int(propertySize) / MemoryLayout<AudioDeviceID>.size
        var deviceIDs = [AudioDeviceID](repeating: 0, count: deviceCount)

        let getDevicesResult = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &propertySize,
            &deviceIDs
        )

        if getDevicesResult != noErr {
            print("获取设备列表失败: \(getDevicesResult)")
            return []
        }

        // 处理每个设备
        for deviceID in deviceIDs {
            if let device = AudioDevice(deviceID: deviceID) {
                switch scope {
                    case .input where device.hasInput:
                        deviceList.append(device)
                    case .output where device.hasOutput:
                        deviceList.append(device)
                    default:
                        break
                }
            }
        }

        return deviceList.sorted { $0.name < $1.name }
    }

    private func updateDeviceList() {
        let currentOutputDevices = self.getAudioDevices(scope: .output)
        let currentInputDevices = self.getAudioDevices(scope: .input)

        // Update current devices
        DispatchQueue.main.async {
            self.outputDevices = currentOutputDevices
            self.inputDevices = currentInputDevices

            // Update historical devices - add new devices to history
            self
                .historicalOutputDevices =
                Array(Set(self.historicalOutputDevices + currentOutputDevices))
                .sorted { $0.name < $1.name }
            self
                .historicalInputDevices =
                Array(Set(self.historicalInputDevices + currentInputDevices))
                .sorted { $0.name < $1.name }

            // Save historical devices to UserDefaults
            self.saveHistoricalDevices()
        }
    }

    private func saveHistoricalDevices() {
        let historicalOutputData = try? JSONEncoder().encode(self.historicalOutputDevices)
        let historicalInputData = try? JSONEncoder().encode(self.historicalInputDevices)

        UserDefaults.standard.set(historicalOutputData, forKey: "historicalOutputDevices")
        UserDefaults.standard.set(historicalInputData, forKey: "historicalInputDevices")
    }

    private func loadHistoricalDevices() {
        if let outputData = UserDefaults.standard.data(forKey: "historicalOutputDevices"),
           let outputDevices = try? JSONDecoder().decode([AudioDevice].self, from: outputData)
        {
            self.historicalOutputDevices = outputDevices
        }

        if let inputData = UserDefaults.standard.data(forKey: "historicalInputDevices"),
           let inputDevices = try? JSONDecoder().decode([AudioDevice].self, from: inputData)
        {
            self.historicalInputDevices = inputDevices
        }
    }

    private func applyDefaultDeviceSettings() {
        print("\u{001B}[34m[初始化]\u{001B}[0m 正在检查默认设备设置")

        // 使用已保存的默认设备设置
        let defaultOutputUID = self.settings.defaultOutputDeviceUID
        let defaultInputUID = self.settings.defaultInputDeviceUID

        if !defaultOutputUID.isEmpty {
            // 尝试在输出设备中查找匹配的设备
            if let device = outputDevices.first(where: { $0.uid == defaultOutputUID }) {
                print("\u{001B}[32m[设备]\u{001B}[0m 应用默认输出设备: \(device.name)")
                self.setDefaultOutputDevice(device)
            } else {
                print("\u{001B}[33m[警告]\u{001B}[0m 默认输出设备未找到: \(defaultOutputUID)")
            }
        }

        if !defaultInputUID.isEmpty {
            // 尝试在输入设备中查找匹配的设备
            if let device = inputDevices.first(where: { $0.uid == defaultInputUID }) {
                print("\u{001B}[32m[设备]\u{001B}[0m 应用默认输入设备: \(device.name)")
                self.setDefaultInputDevice(device)
            } else {
                print("\u{001B}[33m[警告]\u{001B}[0m 默认输入设备未找到: \(defaultInputUID)")
            }
        }
    }

    func updateDevices() {
        print("\u{001B}[34m[AUDIO]\u{001B}[0m Updating audio devices list")

        // Get default input/output device IDs
        var defaultOutputID: AudioDeviceID = 0
        var defaultInputID: AudioDeviceID = 0
        var propsize = UInt32(MemoryLayout<AudioDeviceID>.size)

        var outputAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var inputAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &outputAddress,
            0,
            nil,
            &propsize,
            &defaultOutputID
        )

        AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &inputAddress,
            0,
            nil,
            &propsize,
            &defaultInputID
        )

        // Get all devices using existing method
        let currentOutputDevices = self.getAudioDevices(scope: .output)
        let currentInputDevices = self.getAudioDevices(scope: .input)

        // Find selected devices
        let newOutputDevice = currentOutputDevices.first { $0.id == defaultOutputID }
        let newInputDevice = currentInputDevices.first { $0.id == defaultInputID }

        // Update volumes from selected devices
        if let outputDevice = newOutputDevice {
            self.outputVolume = outputDevice.volume
        }

        if let inputDevice = newInputDevice {
            self.inputVolume = inputDevice.volume
        }

        DispatchQueue.main.async {
            // Update current device lists
            self.outputDevices = currentOutputDevices
            self.inputDevices = currentInputDevices
            self.selectedOutputDevice = newOutputDevice
            self.selectedInputDevice = newInputDevice

            // Update historical devices - add new devices to history
            let newOutputDevicesSet = Set(currentOutputDevices)
            let newInputDevicesSet = Set(currentInputDevices)

            // Merge existing historical devices with new devices
            let updatedHistoricalOutputs = Set(self.historicalOutputDevices)
                .union(newOutputDevicesSet)
            let updatedHistoricalInputs = Set(self.historicalInputDevices).union(newInputDevicesSet)

            // Update historical device lists and sort
            self.historicalOutputDevices = Array(updatedHistoricalOutputs)
                .sorted { $0.name < $1.name }
            self.historicalInputDevices = Array(updatedHistoricalInputs)
                .sorted { $0.name < $1.name }

            // Save historical devices to UserDefaults
            self.saveHistoricalDevices()

            // Apply device settings
            self.applyDefaultDeviceSettings()

            // Notify about devices change
            NotificationCenter.default.post(
                name: NSNotification.Name("audioDevicesChanged"),
                object: nil
            )
        }
    }

    // 设置默认设备
    public func setDefaultDevice(_ device: AudioDevice, forInput: Bool) {
        print(
            "\u{001B}[35m[DEVICE]\u{001B}[0m Setting \(forInput ? "input" : "output") device: \(device.name)"
        )

        let selector = forInput ? kAudioHardwarePropertyDefaultInputDevice :
            kAudioHardwarePropertyDefaultOutputDevice
        var address = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var deviceID = device.id
        let status = AudioObjectSetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            UInt32(MemoryLayout<AudioDeviceID>.size),
            &deviceID
        )

        if status == noErr {
            print(
                "\u{001B}[32m[SUCCESS]\u{001B}[0m Set \(forInput ? "input" : "output") device: \(device.name)"
            )

            // Remove volume listener from current device
            if forInput {
                if let currentDevice = selectedInputDevice {
                    self.removeVolumeListenerForDevice(currentDevice, isInput: true)
                }
                self.selectedInputDevice = device
                self.userSelectedInputUID = device.uid

                // Get and update device volume
                let newVolume = device.getVolume()
                self.inputVolume = newVolume
                print(
                    "\u{001B}[32m[VOLUME]\u{001B}[0m Input device volume: \(Int(self.inputVolume * 100))%"
                )
            } else {
                if let currentDevice = selectedOutputDevice {
                    self.removeVolumeListenerForDevice(currentDevice, isInput: false)
                }
                self.selectedOutputDevice = device
                self.userSelectedOutputUID = device.uid

                // Get and update device volume
                let newVolume = device.getVolume()
                self.outputVolume = newVolume
                print(
                    "\u{001B}[32m[VOLUME]\u{001B}[0m Output device volume: \(Int(self.outputVolume * 100))%"
                )
            }

            // Set up volume listener for new device
            self.setupVolumeListenerForDevice(device, isInput: forInput)

            // Save device selection
            self.saveDeviceSelection()
        } else {
            print(
                "\u{001B}[31m[ERROR]\u{001B}[0m Could not set default \(forInput ? "input" : "output") device: \(status)"
            )
        }
    }

    private func setupDefaultDeviceListeners() {
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        // 设备列表变化监听
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        AudioObjectAddPropertyListener(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            { _, _, _, context in
                let manager = Unmanaged<AudioManager>.fromOpaque(context!).takeUnretainedValue()
                DispatchQueue.main.async {
                    manager.updateDevices()
                }
                return noErr
            },
            selfPtr
        )

        // 默认输入设备变化监听
        var inputPropertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        AudioObjectAddPropertyListener(
            AudioObjectID(kAudioObjectSystemObject),
            &inputPropertyAddress,
            { _, _, _, context in
                let manager = Unmanaged<AudioManager>.fromOpaque(context!).takeUnretainedValue()
                DispatchQueue.main.async {
                    manager.updateSelectedDevices()
                }
                return noErr
            },
            selfPtr
        )

        // 默认输出设备变化监听
        var outputPropertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        AudioObjectAddPropertyListener(
            AudioObjectID(kAudioObjectSystemObject),
            &outputPropertyAddress,
            { _, _, _, context in
                let manager = Unmanaged<AudioManager>.fromOpaque(context!).takeUnretainedValue()
                DispatchQueue.main.async {
                    manager.updateSelectedDevices()
                }
                return noErr
            },
            selfPtr
        )
    }

    private func setupVolumeListeners() {
        // 移除旧的监听器
        self.removeVolumeListeners()

        // 设置输入设备的音量监听器
        if let device = selectedInputDevice {
            let deviceID = device.id
            let scope = kAudioDevicePropertyScopeInput
            let isBluetoothDevice = device.uid.lowercased().contains("bluetooth")

            Swift.print("为\(isBluetoothDevice ? "蓝牙" : "")输入设备 \(device.name) 设置音量监听器")

            // 创建要监听的属性地址列表
            var addresses: [AudioObjectPropertyAddress] = []

            // 添加最重要的音量控制属性 - 虚拟主音量最为可靠
            var virtualMasterAddress = AudioObjectPropertyAddress(
                mSelector: kAudioHardwareServiceDeviceProperty_VirtualMasterVolume,
                mScope: scope,
                mElement: kAudioObjectPropertyElementMain
            )

            if AudioObjectHasProperty(deviceID, &virtualMasterAddress) {
                addresses.append(virtualMasterAddress)
                Swift.print("添加虚拟主音量监听器（输入设备）")
            } else {
                // 备用选项
                var fallbackAddress = AudioObjectPropertyAddress(
                    mSelector: kAudioDevicePropertyVolumeScalar,
                    mScope: scope,
                    mElement: kAudioObjectPropertyElementMain
                )

                if AudioObjectHasProperty(deviceID, &fallbackAddress) {
                    addresses.append(fallbackAddress)
                    Swift.print("添加音量标量监听器（输入设备备用）")
                }
            }

            let selfPtr = Unmanaged.passUnretained(self).toOpaque()

            // 保存回调函数引用
            let inputCallback: AudioObjectPropertyListenerProc = self.inputVolumeChanged
            self.inputVolumeListenerID = inputCallback

            // 为每个地址设置监听器
            for address in addresses {
                var addr = address
                let status = AudioObjectAddPropertyListener(
                    deviceID,
                    &addr,
                    inputCallback,
                    selfPtr
                )

                if status == noErr {
                    Swift.print("已为输入设备 \(device.name) 添加音量监听器 (属性: \(address.mSelector))")
                } else {
                    Swift.print("为输入设备 \(device.name) 添加音量监听器失败: \(status)")
                }
            }
        }

        // 设置输出设备的音量监听器
        if let device = selectedOutputDevice {
            let deviceID = device.id
            let scope = kAudioDevicePropertyScopeOutput
            let isBluetoothDevice = device.uid.lowercased().contains("bluetooth")

            Swift.print("为\(isBluetoothDevice ? "蓝牙" : "")输出设备 \(device.name) 设置音量监听器")

            // 创建要监听的属性地址列表
            var addresses: [AudioObjectPropertyAddress] = []

            // 添加最重要的音量控制属性 - 虚拟主音量最为可靠
            var virtualMasterAddress = AudioObjectPropertyAddress(
                mSelector: kAudioHardwareServiceDeviceProperty_VirtualMasterVolume,
                mScope: scope,
                mElement: kAudioObjectPropertyElementMain
            )

            if AudioObjectHasProperty(deviceID, &virtualMasterAddress) {
                addresses.append(virtualMasterAddress)
                Swift.print("添加虚拟主音量监听器（输出设备）")
            } else {
                // 备用选项
                var fallbackAddress = AudioObjectPropertyAddress(
                    mSelector: kAudioDevicePropertyVolumeScalar,
                    mScope: scope,
                    mElement: kAudioObjectPropertyElementMain
                )

                if AudioObjectHasProperty(deviceID, &fallbackAddress) {
                    addresses.append(fallbackAddress)
                    Swift.print("添加音量标量监听器（输出设备备用）")
                }
            }

            let selfPtr = Unmanaged.passUnretained(self).toOpaque()

            // 保存回调函数引用
            let outputCallback: AudioObjectPropertyListenerProc = self.outputVolumeChanged
            self.outputVolumeListenerID = outputCallback

            // 为每个地址设置监听器
            for address in addresses {
                var addr = address
                let status = AudioObjectAddPropertyListener(
                    deviceID,
                    &addr,
                    outputCallback,
                    selfPtr
                )

                if status == noErr {
                    Swift.print("已为输出设备 \(device.name) 添加音量监听器 (属性: \(address.mSelector))")
                } else {
                    Swift.print("为输出设备 \(device.name) 添加音量监听器失败: \(status)")
                }
            }
        }
    }

    private func removeVolumeListeners() {
        // 移除输入设备音量监听器
        if let device = selectedInputDevice, let listenerID = inputVolumeListenerID {
            let deviceID = device.id
            let scope = kAudioDevicePropertyScopeInput

            // 移除主要监听属性
            var virtualMasterAddress = AudioObjectPropertyAddress(
                mSelector: kAudioHardwareServiceDeviceProperty_VirtualMasterVolume,
                mScope: scope,
                mElement: kAudioObjectPropertyElementMain
            )

            let selfPtr = Unmanaged.passUnretained(self).toOpaque()

            if AudioObjectHasProperty(deviceID, &virtualMasterAddress) {
                AudioObjectRemovePropertyListener(
                    deviceID,
                    &virtualMasterAddress,
                    listenerID,
                    selfPtr
                )
                Swift.print("移除输入设备虚拟主音量监听器")
            }

            // 移除备用监听属性
            var fallbackAddress = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyVolumeScalar,
                mScope: scope,
                mElement: kAudioObjectPropertyElementMain
            )

            if AudioObjectHasProperty(deviceID, &fallbackAddress) {
                AudioObjectRemovePropertyListener(
                    deviceID,
                    &fallbackAddress,
                    listenerID,
                    selfPtr
                )
                Swift.print("移除输入设备音量标量监听器")
            }

            self.inputVolumeListenerID = nil
        }

        // 移除输出设备音量监听器
        if let device = selectedOutputDevice, let listenerID = outputVolumeListenerID {
            let deviceID = device.id
            let scope = kAudioDevicePropertyScopeOutput

            // 移除主要监听属性
            var virtualMasterAddress = AudioObjectPropertyAddress(
                mSelector: kAudioHardwareServiceDeviceProperty_VirtualMasterVolume,
                mScope: scope,
                mElement: kAudioObjectPropertyElementMain
            )

            let selfPtr = Unmanaged.passUnretained(self).toOpaque()

            if AudioObjectHasProperty(deviceID, &virtualMasterAddress) {
                AudioObjectRemovePropertyListener(
                    deviceID,
                    &virtualMasterAddress,
                    listenerID,
                    selfPtr
                )
                Swift.print("移除输出设备虚拟主音量监听器")
            }

            // 移除备用监听属性
            var fallbackAddress = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyVolumeScalar,
                mScope: scope,
                mElement: kAudioObjectPropertyElementMain
            )

            if AudioObjectHasProperty(deviceID, &fallbackAddress) {
                AudioObjectRemovePropertyListener(
                    deviceID,
                    &fallbackAddress,
                    listenerID,
                    selfPtr
                )
                Swift.print("移除输出设备音量标量监听器")
            }

            self.outputVolumeListenerID = nil
        }
    }

    // 添加系统音量监听器 - 针对所有设备类型
    private func setupSystemAudioVolumeListener() {
        print("\u{001B}[34m[初始化]\u{001B}[0m 设置系统音量监听器")

        // 移除现有的监听器
        self.removeVolumeListener()

        // 获取当前设备
        let inputDevice = self.selectedInputDevice
        let outputDevice = self.selectedOutputDevice

        // 为输入设备设置监听器
        if let device = inputDevice {
            self.setupVolumeListenerForDevice(device, isInput: true)
        }

        // 为输出设备设置监听器
        if let device = outputDevice {
            self.setupVolumeListenerForDevice(device, isInput: false)
        }
    }

    // 为特定设备设置音量监听器
    private func setupVolumeListenerForDevice(_ device: AudioDevice, isInput: Bool) {
        let deviceType = isInput ? "输入" : "输出"
        print("\u{001B}[34m[监听]\u{001B}[0m 为\(deviceType)设备 '\(device.name)' 设置音量监听器")

        // 创建音量属性地址
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
            mScope: isInput ? kAudioDevicePropertyScopeInput : kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )

        // 检查设备是否支持此属性
        let supportStatus = AudioObjectHasProperty(device.id, &address)

        if !supportStatus {
            // 尝试使用标准音量属性
            address.mSelector = kAudioDevicePropertyVolumeScalar
            let fallbackStatus = AudioObjectHasProperty(device.id, &address)

            if !fallbackStatus {
                print("\u{001B}[33m[警告]\u{001B}[0m \(deviceType)设备 '\(device.name)' 不支持音量监听")
                return
            } else {
                print(
                    "\u{001B}[34m[信息]\u{001B}[0m 使用VolumeScalar备用属性监听\(deviceType)设备 '\(device.name)'"
                )
            }
        }

        // 使用不可变指针创建一个可变副本，避免编译器警告
        var mutableAddress = address

        // 注册监听器
        let status = AudioObjectAddPropertyListener(
            device.id,
            &mutableAddress,
            self.volumeListenerProc,
            Unmanaged.passUnretained(self).toOpaque()
        )

        if status != noErr {
            print(
                "\u{001B}[31m[错误]\u{001B}[0m 无法为\(deviceType)设备 '\(device.name)' 添加音量监听器: \(status)"
            )
        } else {
            print("\u{001B}[32m[成功]\u{001B}[0m 已为\(deviceType)设备 '\(device.name)' 添加音量监听器")
        }
    }

    // 移除音量监听器
    private func removeVolumeListener() {
        // 为输入设备移除监听器
        if let device = selectedInputDevice {
            self.removeVolumeListenerForDevice(device, isInput: true)
        }

        // 为输出设备移除监听器
        if let device = selectedOutputDevice {
            self.removeVolumeListenerForDevice(device, isInput: false)
        }
    }

    // 为特定设备移除音量监听器
    private func removeVolumeListenerForDevice(_ device: AudioDevice, isInput: Bool) {
        let deviceType = isInput ? "输入" : "输出"
        print("\u{001B}[34m[监听]\u{001B}[0m 移除\(deviceType)设备 '\(device.name)' 的音量监听器")

        // 创建音量属性地址
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
            mScope: isInput ? kAudioDevicePropertyScopeInput : kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )

        // 检查设备是否支持此属性
        let supportStatus = AudioObjectHasProperty(device.id, &address)

        if !supportStatus {
            // 尝试使用标准音量属性
            address.mSelector = kAudioDevicePropertyVolumeScalar
            let fallbackStatus = AudioObjectHasProperty(device.id, &address)

            if !fallbackStatus {
                return // 设备不支持音量监听，无需移除
            }
        }

        // 使用不可变指针创建一个可变副本，避免编译器警告
        var mutableAddress = address

        // 移除监听器
        let status = AudioObjectRemovePropertyListener(
            device.id,
            &mutableAddress,
            self.volumeListenerProc,
            Unmanaged.passUnretained(self).toOpaque()
        )

        if status != noErr, status != kAudioHardwareBadObjectError {
            print(
                "\u{001B}[33m[警告]\u{001B}[0m 无法移除\(deviceType)设备 '\(device.name)' 的音量监听器: \(status)"
            )
        }
    }

    // 音量监听器回调
    private let volumeListenerProc: AudioObjectPropertyListenerProc =
        { inObjectID, inNumberAddresses, inAddresses, inClientData in
            let manager = Unmanaged<AudioManager>.fromOpaque(inClientData!).takeUnretainedValue()
            let address = inAddresses.pointee

            // 检查是哪种设备的音量变化
            let isInput = address.mScope == kAudioDevicePropertyScopeInput
            let deviceType = isInput ? "输入" : "输出"

            var deviceName = "未知设备"
            let isCurrentDevice: Bool

            // 确认这是当前选中的设备
            if isInput, let device = manager.selectedInputDevice {
                isCurrentDevice = device.id == inObjectID
                deviceName = device.name
            } else if !isInput, let device = manager.selectedOutputDevice {
                isCurrentDevice = device.id == inObjectID
                deviceName = device.name
            } else {
                isCurrentDevice = false
            }

            // 只处理当前选中设备的变化
            if !isCurrentDevice {
                return noErr
            }

            // 获取新音量值
            var volume: Float = 0.0
            var size = UInt32(MemoryLayout<Float>.size)
            let status = AudioObjectGetPropertyData(
                inObjectID,
                &UnsafeMutablePointer<AudioObjectPropertyAddress>(mutating: inAddresses).pointee,
                0,
                nil,
                &size,
                &volume
            )

            if status == noErr {
                print("🟡 [VolumeWatch] 系统\(deviceType)音量变了！新值：\(volume)")

                DispatchQueue.main.async {
                    let oldVolume = isInput ? manager.inputVolume : manager.outputVolume

                    // 检查音量变化是否显著
                    if abs(oldVolume - volume) > 0.001 {
                        if isInput {
                            print("🟢 [AudioManager] 更新 inputVolume = \(volume) (原值: \(oldVolume))")
                            manager.inputVolume = volume
                        } else {
                            print("🟢 [AudioManager] 更新 outputVolume = \(volume) (原值: \(oldVolume))")
                            manager.outputVolume = volume
                        }

                        print("🔵 [Facade] 发布 @Published \(deviceType)Volume = \(volume)")
                    } else {
                        print("⚪️ [SKIP] 音量变化微小，不更新UI: \(oldVolume) -> \(volume)")
                    }
                }
            } else {
                print(
                    "\u{001B}[31m[错误]\u{001B}[0m 获取\(deviceType)设备 '\(deviceName)' 音量失败：\(status)"
                )
            }

            return noErr
        }

    // 启动音量轮询定时器 - 对所有设备类型生效
    private func startVolumePollingTimer() {
        print("启动音量轮询定时器")

        // 停止可能正在运行的定时器
        self.volumePollingTimer?.invalidate()
        self.volumePollingTimer = nil

        // 记录初始音量值
        if let outputDevice = selectedOutputDevice {
            self.lastBluetoothOutputVolume = outputDevice.getVolume()
            print("初始输出设备音量: \(self.lastBluetoothOutputVolume)")
        }

        if let inputDevice = selectedInputDevice {
            self.lastBluetoothInputVolume = inputDevice.getVolume()
            print("初始输入设备音量: \(self.lastBluetoothInputVolume)")
        }

        // 创建新的轮询定时器，每0.5秒检查一次
        self.volumePollingTimer = Timer
            .scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
                guard let self else { return }
                self.checkDeviceVolumeChanges()
            }

        self.isPollingForVolumeChanges = true
    }

    // 停止音量轮询
    private func stopVolumePollingTimer() {
        print("停止音量轮询定时器")
        self.volumePollingTimer?.invalidate()
        self.volumePollingTimer = nil
        self.isPollingForVolumeChanges = false
    }

    // 检查所有设备音量变化
    private func checkDeviceVolumeChanges() {
        // 检查输出设备
        if let outputDevice = selectedOutputDevice {
            let currentVolume = outputDevice.getVolume()

            // 如果音量有显著变化 (避免更新循环)
            if abs(currentVolume - self.lastBluetoothOutputVolume) > 0.001,
               abs(currentVolume - self.outputVolume) > 0.001
            {
                print(
                    "检测到输出设备 \(outputDevice.name) 音量变化: \(self.lastBluetoothOutputVolume) -> \(currentVolume)"
                )
                DispatchQueue.main.async {
                    self.outputVolume = currentVolume
                }
                self.lastBluetoothOutputVolume = currentVolume
            }
        }

        // 检查输入设备
        if let inputDevice = selectedInputDevice {
            let currentVolume = inputDevice.getVolume()

            // 如果音量有显著变化
            if abs(currentVolume - self.lastBluetoothInputVolume) > 0.001,
               abs(currentVolume - self.inputVolume) > 0.001
            {
                print(
                    "检测到输入设备 \(inputDevice.name) 音量变化: \(self.lastBluetoothInputVolume) -> \(currentVolume)"
                )
                DispatchQueue.main.async {
                    self.inputVolume = currentVolume
                }
                self.lastBluetoothInputVolume = currentVolume
            }
        }
    }

    // 强制同步所有设备音量 - 最终同步尝试
    private func forceSyncAllDevicesVolume() {
        Swift.print("执行最终音量同步尝试")

        // 对于蓝牙设备，使用专用的同步方法
        let isBluetoothOutput = self.selectedOutputDevice?.uid.lowercased()
            .contains("bluetooth") ?? false
        let isBluetoothInput = self.selectedInputDevice?.uid.lowercased()
            .contains("bluetooth") ?? false

        // 对蓝牙设备使用直接查询方法
        if isBluetoothOutput || isBluetoothInput {
            self.forceBluetoothVolumeSync(highPriority: true)
        }

        // 对于非蓝牙设备，使用常规更新方法
        if !isBluetoothOutput, self.selectedOutputDevice != nil {
            Swift.print("最终同步: 更新普通输出设备音量")
            if let device = selectedOutputDevice {
                let volume = self.directSystemVolumeQuery(device: device, isInput: false)
                DispatchQueue.main.async {
                    self.outputVolume = volume
                }
            }
        }

        if !isBluetoothInput, self.selectedInputDevice != nil {
            Swift.print("最终同步: 更新普通输入设备音量")
            if let device = selectedInputDevice {
                let volume = self.directSystemVolumeQuery(device: device, isInput: true)
                DispatchQueue.main.async {
                    self.inputVolume = volume
                }
            }
        }

        // 记录音量值以便后续对比
        Swift.print("最终同步完成 - 输出音量: \(self.outputVolume), 输入音量: \(self.inputVolume)")
    }

    // 强制更新设备音量 - 确保会更新TUNA中的音量值
    private func forceUpdateDeviceVolumes() {
        Swift.print("强制更新设备音量状态")

        if let outputDevice = selectedOutputDevice {
            Swift.print("获取输出设备 \(outputDevice.name) 的当前音量")

            // 使用直接查询获取更准确的音量值
            let newVolume = self.directSystemVolumeQuery(device: outputDevice, isInput: false)

            // 无条件更新音量值
            Swift.print("输出设备音量已更新: \(self.outputVolume) -> \(newVolume)")
            self.lastBluetoothOutputVolume = newVolume

            DispatchQueue.main.async {
                self.outputVolume = newVolume
            }
        }

        if let inputDevice = selectedInputDevice {
            Swift.print("获取输入设备 \(inputDevice.name) 的当前音量")

            // 使用直接查询获取更准确的音量值
            let newVolume = self.directSystemVolumeQuery(device: inputDevice, isInput: true)

            // 无条件更新音量值
            Swift.print("输入设备音量已更新: \(self.inputVolume) -> \(newVolume)")
            self.lastBluetoothInputVolume = newVolume

            DispatchQueue.main.async {
                self.inputVolume = newVolume
            }
        }
    }

    @objc private func updateSelectedDevices() {
        Swift.print("正在更新当前选中的设备...")

        // 在更新设备之前移除旧的音量监听器
        self.removeVolumeListeners()

        // 保存当前设备UID，用于后续比较
        let previousOutputUID = self.selectedOutputDevice?.uid
        let previousInputUID = self.selectedInputDevice?.uid

        // 获取当前默认输出设备
        var outputDeviceID: AudioDeviceID = 0
        var propertySize = UInt32(MemoryLayout<AudioDeviceID>.size)
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        let outputStatus = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &propertySize,
            &outputDeviceID
        )

        var outputChanged = false

        if outputStatus == noErr {
            // 查找匹配该ID的输出设备
            let matchingDevice = self.outputDevices.first { $0.id == outputDeviceID }

            if let outputDevice = matchingDevice {
                Swift.print("当前默认输出设备: \(outputDevice.name) [ID: \(outputDevice.id)]")

                if self.userSelectedOutputUID == nil || outputDevice.uid == self
                    .userSelectedOutputUID
                {
                    if self.selectedOutputDevice == nil || self.selectedOutputDevice!
                        .id != outputDevice.id
                    {
                        outputChanged = true
                        self.selectedOutputDevice = outputDevice
                        Swift.print("已选择输出设备: \(outputDevice.name)")

                        // 获取输出设备音量
                        let newVolume = self.directSystemVolumeQuery(
                            device: outputDevice,
                            isInput: false
                        )

                        // 检查音量是否与先前的显著不同，如果是，更新显示
                        if abs(self.outputVolume - newVolume) > 0.01 {
                            Swift.print("输出设备音量更新: \(self.outputVolume) -> \(newVolume)")
                            self.outputVolume = newVolume
                        }

                        // 保存蓝牙设备的音量
                        if outputDevice.uid.lowercased().contains("bluetooth") {
                            self.lastBluetoothOutputVolume = newVolume
                        }
                    }
                }
            } else {
                Swift.print("在设备列表中未找到ID为 \(outputDeviceID) 的输出设备")
            }
        } else {
            Swift.print("获取默认输出设备失败: \(outputStatus)")
        }

        // 获取当前默认输入设备
        var inputDeviceID: AudioDeviceID = 0
        propertyAddress.mSelector = kAudioHardwarePropertyDefaultInputDevice

        let inputStatus = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &propertySize,
            &inputDeviceID
        )

        var inputChanged = false

        if inputStatus == noErr {
            // 查找匹配该ID的输入设备
            let matchingDevice = self.inputDevices.first { $0.id == inputDeviceID }

            if let inputDevice = matchingDevice {
                Swift.print("当前默认输入设备: \(inputDevice.name) [ID: \(inputDevice.id)]")

                if self.userSelectedInputUID == nil || inputDevice.uid == self
                    .userSelectedInputUID
                {
                    if self.selectedInputDevice == nil || self.selectedInputDevice!
                        .id != inputDevice.id
                    {
                        inputChanged = true
                        self.selectedInputDevice = inputDevice
                        Swift.print("已选择输入设备: \(inputDevice.name)")

                        // 获取输入设备音量
                        let newVolume = self.directSystemVolumeQuery(
                            device: inputDevice,
                            isInput: true
                        )

                        // 检查音量是否与先前的显著不同，如果是，更新显示
                        if abs(self.inputVolume - newVolume) > 0.01 {
                            Swift.print("输入设备音量更新: \(self.inputVolume) -> \(newVolume)")
                            self.inputVolume = newVolume
                        }

                        // 保存蓝牙设备的音量
                        if inputDevice.uid.lowercased().contains("bluetooth") {
                            self.lastBluetoothInputVolume = newVolume
                        }
                    }
                }
            } else {
                Swift.print("在设备列表中未找到ID为 \(inputDeviceID) 的输入设备")
            }
        } else {
            Swift.print("获取默认输入设备失败: \(inputStatus)")
        }

        // 特殊处理：当输入或输出设备发生变化，且涉及到蓝牙设备
        if inputChanged || outputChanged,
           self.selectedInputDevice != nil || self.selectedOutputDevice != nil
        {
            // 检查是否为同一蓝牙设备用于输入和输出
            let sameBluetoothDevice = self.selectedInputDevice != nil && self
                .selectedOutputDevice != nil &&
                self.selectedInputDevice!.uid == self.selectedOutputDevice!.uid &&
                self.selectedInputDevice!.uid.lowercased().contains("bluetooth")

            Swift
                .print(
                    "输入设备变化: \(inputChanged), 输出设备变化: \(outputChanged), 是否为同一蓝牙设备: \(sameBluetoothDevice)"
                )

            if sameBluetoothDevice {
                Swift.print("检测到同一蓝牙设备用于输入和输出，确保音量设置保持独立")

                // 如果输入设备变化了，确保输出设备音量不受影响
                if inputChanged, previousInputUID != self.selectedInputDevice?.uid {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        let correctOutputVolume = self.directSystemVolumeQuery(
                            device: self.selectedOutputDevice!,
                            isInput: false
                        )
                        if abs(self.outputVolume - correctOutputVolume) > 0.01 {
                            Swift
                                .print("保持输出设备音量不变: \(self.outputVolume) -> \(correctOutputVolume)")
                            self.outputVolume = correctOutputVolume
                            self.lastBluetoothOutputVolume = correctOutputVolume
                        }
                    }
                }

                // 如果输出设备变化了，确保输入设备音量不受影响
                if outputChanged, previousOutputUID != self.selectedOutputDevice?.uid {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        let correctInputVolume = self.directSystemVolumeQuery(
                            device: self.selectedInputDevice!,
                            isInput: true
                        )
                        if abs(self.inputVolume - correctInputVolume) > 0.01 {
                            Swift.print("保持输入设备音量不变: \(self.inputVolume) -> \(correctInputVolume)")
                            self.inputVolume = correctInputVolume
                            self.lastBluetoothInputVolume = correctInputVolume
                        }
                    }
                }
            }

            // 蓝牙设备特殊处理：如果更换为蓝牙设备，使用更精确的音量同步
            if inputChanged, self.selectedInputDevice != nil,
               self.selectedInputDevice!.uid.lowercased()
                   .contains("bluetooth")
            {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.syncBluetoothDeviceVolume(device: self.selectedInputDevice!, isInput: true)
                }
            }

            if outputChanged, self.selectedOutputDevice != nil, self.selectedOutputDevice!.uid
                .lowercased().contains("bluetooth")
            {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.syncBluetoothDeviceVolume(
                        device: self.selectedOutputDevice!,
                        isInput: false
                    )
                }
            }
        }

        // 设置新的音量监听器
        self.setupVolumeListeners()
    }

    private func getDeviceVolume(device: AudioDevice, isInput: Bool) -> Float {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: isInput ? kAudioDevicePropertyScopeInput : kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )

        // 检查设备是否支持音量控制
        if !AudioObjectHasProperty(device.id, &propertyAddress) {
            Swift.print("设备 \(device.name) 不支持音量控制")
            return 1.0
        }

        var volume: Float = 0.0
        var propertySize = UInt32(MemoryLayout<Float>.size)

        let status = AudioObjectGetPropertyData(
            device.id,
            &propertyAddress,
            0,
            nil,
            &propertySize,
            &volume
        )

        if status != noErr {
            Swift.print("获取设备 \(device.name) 音量失败: \(status)")
            return 1.0
        }

        return volume
    }

    deinit {
        // 移除所有监听器
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        if let listenerID = deviceListenerID {
            AudioObjectRemovePropertyListener(
                AudioObjectID(kAudioObjectSystemObject),
                &propertyAddress,
                listenerID,
                selfPtr
            )
        }

        if let listenerID = defaultInputListenerID {
            propertyAddress.mSelector = kAudioHardwarePropertyDefaultInputDevice
            AudioObjectRemovePropertyListener(
                AudioObjectID(kAudioObjectSystemObject),
                &propertyAddress,
                listenerID,
                selfPtr
            )
        }

        if let listenerID = defaultOutputListenerID {
            propertyAddress.mSelector = kAudioHardwarePropertyDefaultOutputDevice
            AudioObjectRemovePropertyListener(
                AudioObjectID(kAudioObjectSystemObject),
                &propertyAddress,
                listenerID,
                selfPtr
            )
        }

        // 移除音量监听器
        removeVolumeListeners()
    }

    public func findDevice(byUID uid: String, isInput: Bool) -> AudioDevice? {
        let devices = isInput ? self.inputDevices : self.outputDevices
        return devices.first { $0.uid == uid }
    }

    public func selectInputDevice(_ device: AudioDevice) {
        self.setDefaultDevice(device, forInput: true)
    }

    public func selectOutputDevice(_ device: AudioDevice) {
        self.setDefaultDevice(device, forInput: false)
    }

    // 新增：获取更准确的系统音量值
    private func getAccurateSystemVolumes() {
        Swift.print("尝试获取系统准确音量值")

        // 处理输出设备
        if let deviceID = getDefaultOutputDeviceID() {
            if let device = AudioDevice(deviceID: deviceID) {
                Swift.print("系统默认输出设备: \(device.name) (ID: \(deviceID))")
                // 尝试使用多种方法获取音量
                let volume = self.getSystemVolumeForDevice(device: device, isInput: false)
                self.outputVolume = volume
                self.lastBluetoothOutputVolume = volume
                Swift.print("获取到默认输出设备音量: \(volume)")

                // 设置设备引用
                if self.selectedOutputDevice == nil || self.selectedOutputDevice!.id != deviceID {
                    self.selectedOutputDevice = device
                }
            }
        }

        // 处理输入设备
        if let deviceID = getDefaultInputDeviceID() {
            if let device = AudioDevice(deviceID: deviceID) {
                Swift.print("系统默认输入设备: \(device.name) (ID: \(deviceID))")
                // 尝试使用多种方法获取音量
                let volume = self.getSystemVolumeForDevice(device: device, isInput: true)
                self.inputVolume = volume
                self.lastBluetoothInputVolume = volume
                Swift.print("获取到默认输入设备音量: \(volume)")

                // 设置设备引用
                if self.selectedInputDevice == nil || self.selectedInputDevice!.id != deviceID {
                    self.selectedInputDevice = device
                }
            }
        }
    }

    // 获取默认输出设备ID
    private func getDefaultOutputDeviceID() -> AudioDeviceID? {
        var propertySize = UInt32(MemoryLayout<AudioDeviceID>.size)
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var deviceID: AudioDeviceID = 0
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &propertySize,
            &deviceID
        )

        if status == noErr, deviceID != 0 {
            return deviceID
        }
        return nil
    }

    // 获取默认输入设备ID
    private func getDefaultInputDeviceID() -> AudioDeviceID? {
        var propertySize = UInt32(MemoryLayout<AudioDeviceID>.size)
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var deviceID: AudioDeviceID = 0
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &propertySize,
            &deviceID
        )

        if status == noErr, deviceID != 0 {
            return deviceID
        }
        return nil
    }

    // 通过多种方法获取系统音量
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
                print("使用硬件服务属性获取设备 \(device.name) 音量: \(volume)")
                return volume
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
                print("使用虚拟主音量属性获取设备 \(device.name) 音量: \(volume)")
                return volume
            }
        }

        // 尝试方法3: 使用标准音量缩放器
        var standardAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: scope,
            mElement: kAudioObjectPropertyElementMain
        )

        if AudioObjectHasProperty(deviceID, &standardAddress) {
            let status = AudioObjectGetPropertyData(
                deviceID,
                &standardAddress,
                0,
                nil,
                &size,
                &volume
            )
            if status == noErr {
                print("使用标准音量属性获取设备 \(device.name) 音量: \(volume)")
                return volume
            }
        }

        // 方法4: 尝试获取第一个通道的音量
        standardAddress.mElement = 1
        if AudioObjectHasProperty(deviceID, &standardAddress) {
            let status = AudioObjectGetPropertyData(
                deviceID,
                &standardAddress,
                0,
                nil,
                &size,
                &volume
            )
            if status == noErr {
                print("使用第一通道音量属性获取设备 \(device.name) 音量: \(volume)")
                return volume
            }
        }

        // 回退到设备自己的getVolume方法
        let deviceVolume = device.getVolume()
        print("回退到设备 \(device.name) 的getVolume获取音量: \(deviceVolume)")
        return deviceVolume
    }

    // 集中优化的蓝牙设备音量同步方法
    private func forceBluetoothVolumeSync(highPriority: Bool = false) {
        // 处理输出设备
        if let device = selectedOutputDevice, device.uid.lowercased().contains("bluetooth") {
            Swift.print("强制同步蓝牙输出设备音量" + (highPriority ? " (高优先级)" : ""))

            // 直接查询设备的当前系统音量 (绕过缓存)
            let systemVolume = self.directSystemVolumeQuery(device: device, isInput: false)

            // 高优先级时无条件更新，或音量差异超过阈值时更新
            let shouldUpdate = highPriority || abs(systemVolume - self.outputVolume) > 0.01

            if shouldUpdate {
                Swift.print("更新蓝牙输出设备音量: \(self.outputVolume) -> \(systemVolume)")
                DispatchQueue.main.async {
                    self.outputVolume = systemVolume
                    self.lastBluetoothOutputVolume = systemVolume
                }
            }
        }

        // 处理输入设备
        if let device = selectedInputDevice, device.uid.lowercased().contains("bluetooth") {
            Swift.print("强制同步蓝牙输入设备音量" + (highPriority ? " (高优先级)" : ""))

            // 直接查询设备的当前系统音量 (绕过缓存)
            let systemVolume = self.directSystemVolumeQuery(device: device, isInput: true)

            // 高优先级时无条件更新，或音量差异超过阈值时更新
            let shouldUpdate = highPriority || abs(systemVolume - self.inputVolume) > 0.01

            if shouldUpdate {
                Swift.print("更新蓝牙输入设备音量: \(self.inputVolume) -> \(systemVolume)")
                DispatchQueue.main.async {
                    self.inputVolume = systemVolume
                    self.lastBluetoothInputVolume = systemVolume
                }
            }
        }
    }

    // 新的初始系统音量同步方法 - 专注于准确获取初始音量
    private func initialSystemVolumeSync() {
        print("\u{001B}[34m[初始化]\u{001B}[0m 同步系统音量到应用")

        // 强制更新默认设备列表，确保设备信息是最新的
        self.updateDefaultDevices()

        // 同步输出设备音量
        if let device = selectedOutputDevice {
            // 检查是否是蓝牙设备
            let isBluetooth = device.uid.lowercased().contains("bluetooth")

            // 使用直接系统查询获取最准确的音量
            let volume = self.directSystemVolumeQuery(device: device, isInput: false)

            // 确保在主线程更新UI相关属性
            DispatchQueue.main.async {
                self.outputVolume = volume
                print(
                    "\u{001B}[32m[音量]\u{001B}[0m 输出设备 '\(device.name)' \(isBluetooth ? "[蓝牙]" : "") 初始音量: \(Int(volume * 100))%"
                )
            }

            // 特别针对蓝牙设备，额外的处理
            if isBluetooth {
                // 记录为轮询比较基准值
                self.lastBluetoothOutputVolume = volume

                // 短延迟后再次强制同步蓝牙设备
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                    guard let self else { return }
                    guard let currentDevice = selectedOutputDevice,
                          currentDevice.id == device.id else { return }

                    // 再次获取系统音量，以确保准确性
                    let updatedVolume = self.directSystemVolumeQuery(
                        device: currentDevice,
                        isInput: false
                    )
                    if abs(updatedVolume - self.outputVolume) > 0.01 {
                        print(
                            "\u{001B}[32m[蓝牙同步]\u{001B}[0m 修正蓝牙输出设备 '\(currentDevice.name)' 初始音量: \(Int(self.outputVolume * 100))% -> \(Int(updatedVolume * 100))%"
                        )
                        self.outputVolume = updatedVolume
                        self.lastBluetoothOutputVolume = updatedVolume
                    }
                }
            }
        }

        // 同步输入设备音量
        if let device = selectedInputDevice {
            // 检查是否是蓝牙设备
            let isBluetooth = device.uid.lowercased().contains("bluetooth")

            // 使用直接系统查询获取最准确的音量
            let volume = self.directSystemVolumeQuery(device: device, isInput: true)

            // 确保在主线程更新UI相关属性
            DispatchQueue.main.async {
                self.inputVolume = volume
                print(
                    "\u{001B}[32m[音量]\u{001B}[0m 输入设备 '\(device.name)' \(isBluetooth ? "[蓝牙]" : "") 初始音量: \(Int(volume * 100))%"
                )
            }

            // 特别针对蓝牙设备，额外的处理
            if isBluetooth {
                // 记录为轮询比较基准值
                self.lastBluetoothInputVolume = volume

                // 短延迟后再次强制同步蓝牙设备
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                    guard let self else { return }
                    guard let currentDevice = selectedInputDevice,
                          currentDevice.id == device.id else { return }

                    // 再次获取系统音量，以确保准确性
                    let updatedVolume = self.directSystemVolumeQuery(
                        device: currentDevice,
                        isInput: true
                    )
                    if abs(updatedVolume - self.inputVolume) > 0.01 {
                        print(
                            "\u{001B}[32m[蓝牙同步]\u{001B}[0m 修正蓝牙输入设备 '\(currentDevice.name)' 初始音量: \(Int(self.inputVolume * 100))% -> \(Int(updatedVolume * 100))%"
                        )
                        self.inputVolume = updatedVolume
                        self.lastBluetoothInputVolume = updatedVolume
                    }
                }
            }
        }

        // 延迟执行多次同步尝试，以处理蓝牙设备的特殊情况
        // 第一次延迟0.5秒
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self else { return }

            // 特别处理蓝牙设备
            self.forceBluetoothVolumeSync(highPriority: true)

            // 第二次延迟1秒
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                guard let self else { return }

                // 再次强制同步蓝牙设备
                self.forceBluetoothVolumeSync(highPriority: true)

                // 第三次延迟2秒
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                    guard let self else { return }

                    // 最后一次强制同步，确保蓝牙设备音量完全同步
                    self.forceBluetoothVolumeSync(highPriority: true)

                    // 启动音量轮询（如果有蓝牙设备）
                    if (
                        self.selectedOutputDevice?.uid.lowercased()
                            .contains("bluetooth") == true
                    ) ||
                        (self.selectedInputDevice?.uid.lowercased().contains("bluetooth") == true)
                    {
                        self.startVolumePollingTimer()
                    }
                }
            }
        }

        // 添加音量轮询兜底机制
        self.setupVolumePollingFallback()
    }

    // 添加新的音量轮询兜底机制
    private func setupVolumePollingFallback() {
        print("\u{001B}[34m[初始化]\u{001B}[0m 设置音量轮询兜底机制")

        // 停止可能已存在的定时器
        self.volumePollingTimer?.invalidate()

        // 创建新的定时器，每1秒检查一次系统音量
        self.volumePollingTimer = Timer
            .scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                guard let self else { return }

                // 检查输出设备
                if let device = selectedOutputDevice {
                    let sysVol = device.getVolume()
                    if abs(sysVol - self.outputVolume) > 0.01 {
                        print("🔁 [Poll] 检测到系统输出音量变化: \(self.outputVolume) -> \(sysVol)")
                        self.outputVolume = sysVol
                    }
                }

                // 检查输入设备
                if let device = selectedInputDevice {
                    let sysVol = device.getVolume()
                    if abs(sysVol - self.inputVolume) > 0.01 {
                        print("🔁 [Poll] 检测到系统输入音量变化: \(self.inputVolume) -> \(sysVol)")
                        self.inputVolume = sysVol
                    }
                }
            }
    }

    // 直接查询系统音量，确保输入输出分离
    private func directSystemVolumeQuery(device: AudioDevice, isInput: Bool) -> Float {
        let deviceID = device.id
        let scope = isInput ? kAudioDevicePropertyScopeInput : kAudioDevicePropertyScopeOutput
        var deviceVolume: Float = 0.0
        var propertySize = UInt32(MemoryLayout<Float32>.size)

        Swift.print("直接查询设备 \(device.name) 的\(isInput ? "输入" : "输出")音量")

        // 首先检查是否为蓝牙设备
        let isBluetoothDevice = device.uid.lowercased().contains("bluetooth")

        // 对于蓝牙设备，尝试使用硬件服务属性获取音量
        if isBluetoothDevice {
            var hardwareServiceAddress = AudioObjectPropertyAddress(
                mSelector: kAudioHardwareServiceDeviceProperty_VirtualMasterVolume,
                mScope: scope,
                mElement: kAudioObjectPropertyElementMain
            )

            if AudioObjectHasProperty(deviceID, &hardwareServiceAddress) {
                var volume: Float32 = 0.0
                // 使用AudioObjectGetPropertyData替代已弃用的AudioHardwareServiceGetPropertyData
                let status = AudioObjectGetPropertyData(
                    deviceID,
                    &hardwareServiceAddress,
                    0,
                    nil,
                    &propertySize,
                    &volume
                )

                if status == noErr {
                    deviceVolume = volume
                    Swift.print("使用硬件服务API获取蓝牙设备\(isInput ? "输入" : "输出")音量: \(deviceVolume)")
                    return deviceVolume
                }
            }
        }

        // 尝试使用虚拟主音量
        var virtualVolumeAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVirtualMasterVolume,
            mScope: scope,
            mElement: kAudioObjectPropertyElementMain
        )

        if AudioObjectHasProperty(deviceID, &virtualVolumeAddress) {
            var volume: Float32 = 0.0
            let status = AudioObjectGetPropertyData(
                deviceID,
                &virtualVolumeAddress,
                0,
                nil,
                &propertySize,
                &volume
            )

            if status == noErr {
                deviceVolume = volume
                Swift.print("使用虚拟主音量属性获取设备\(isInput ? "输入" : "输出")音量: \(deviceVolume)")
                return deviceVolume
            }
        }

        // 尝试使用标准音量属性
        for channel in [UInt32(kAudioObjectPropertyElementMain), 0, 1] {
            var standardAddress = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyVolumeScalar,
                mScope: scope,
                mElement: channel
            )

            if AudioObjectHasProperty(deviceID, &standardAddress) {
                var volume: Float32 = 0.0
                let status = AudioObjectGetPropertyData(
                    deviceID,
                    &standardAddress,
                    0,
                    nil,
                    &propertySize,
                    &volume
                )

                if status == noErr {
                    deviceVolume = volume
                    Swift
                        .print(
                            "使用标准音量属性(通道\(channel))获取设备\(isInput ? "输入" : "输出")音量: \(deviceVolume)"
                        )
                    return deviceVolume
                }
            }
        }

        // 如果上述方法都失败，使用设备的getVolume方法
        deviceVolume = device.getVolume()
        Swift.print("使用设备默认方法获取\(isInput ? "输入" : "输出")音量: \(deviceVolume)")

        return deviceVolume
    }

    // 添加锁定/解锁平衡的方法
    func toggleOutputBalanceLock() {
        self.isOutputBalanceLocked.toggle()
        print("输出设备平衡锁定状态: \(self.isOutputBalanceLocked)")

        if self.isOutputBalanceLocked, let device = selectedOutputDevice {
            self.lockedOutputBalance = device.getBalance()
            print("已锁定输出设备平衡值: \(self.lockedOutputBalance)")
        }
    }

    // 修改确保平衡锁定功能，只对支持平衡控制的设备生效
    private func maintainLockedBalance() {
        if self.isOutputBalanceLocked, let device = selectedOutputDevice {
            // 如果设备不支持平衡控制，不执行平衡锁定维护
            if !device.supportsBalanceControl {
                print("设备不支持平衡控制，不需要平衡锁定维护")
                return
            }

            let currentBalance = device.getBalance()
            if abs(currentBalance - self.lockedOutputBalance) > 0.01 {
                print("检测到输出设备平衡漂移，正在恢复锁定的平衡值: \(self.lockedOutputBalance)")

                // 使用当前音量和锁定的平衡值设置左右声道音量
                let currentVolume = self.outputVolume
                let success = device.setVolumeWithLockedBalance(
                    currentVolume,
                    balance: self.lockedOutputBalance
                )

                if success {
                    print("成功恢复平衡值: \(self.lockedOutputBalance)")
                    self.outputBalance = self.lockedOutputBalance
                } else {
                    // 如果特殊方法失败，尝试直接设置平衡
                    if device.setBalance(self.lockedOutputBalance) {
                        self.outputBalance = self.lockedOutputBalance
                    }
                }
            }
        }
    }

    // 测试平衡锁定的函数 - 替换旧版本
    func testBalanceLock() {
        print("\u{001B}[35m[测试]\u{001B}[0m 测试输出设备平衡锁定功能")

        // 确保当前有输出设备
        guard let outputDevice = selectedOutputDevice else {
            print("\u{001B}[31m[错误]\u{001B}[0m 没有选择输出设备，无法测试平衡锁定")
            return
        }

        // 保存当前音量和平衡值
        let initialVolume = self.outputVolume
        let initialBalance = outputDevice.getBalance()

        print("\u{001B}[34m[测试信息]\u{001B}[0m 当前输出设备: \(outputDevice.name)")
        print(
            "\u{001B}[34m[测试信息]\u{001B}[0m 当前音量: \(Int(initialVolume * 100))%, 平衡值: \(initialBalance)"
        )

        // 尝试修改音量和平衡，然后检查是否保持锁定
        self.setVolumeForDevice(
            device: outputDevice,
            volume: min(0.8, initialVolume + 0.1),
            isInput: false
        )

        // 等待系统处理
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            // 检查平衡值是否保持不变
            let newBalance = outputDevice.getBalance()
            print("\u{001B}[34m[测试结果]\u{001B}[0m 调整音量后的平衡值: \(newBalance)")

            // 恢复原始音量
            self.setVolumeForDevice(device: outputDevice, volume: initialVolume, isInput: false)
        }
    }

    // 在设置设备时初始化平衡控制支持
    private func initializeDeviceBalanceSupport(_ device: AudioDevice) -> AudioDevice {
        var mutableDevice = device
        mutableDevice.supportsBalanceControl = device.checkSupportsBalanceControl()
        return mutableDevice
    }

    // 设置设备音量
    public func setVolumeForDevice(device: AudioDevice, volume: Float, isInput: Bool) {
        print(
            "\u{001B}[36m[音量变化]\u{001B}[0m 设置\(isInput ? "输入" : "输出")设备 '\(device.name)' 音量: \(Int(volume * 100))%"
        )

        // 获取音量地址
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
            mScope: isInput ? kAudioDevicePropertyScopeInput : kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )

        // 尝试设置音量
        var newVolume = volume
        let status = AudioHardwareServiceSetPropertyData(
            device.id,
            &address,
            0,
            nil,
            UInt32(MemoryLayout<Float>.size),
            &newVolume
        )

        if status != noErr {
            print("\u{001B}[31m[错误]\u{001B}[0m 无法设置设备 '\(device.name)' 的音量: \(status)")
        } else {
            if isInput {
                self.inputVolume = volume
            } else {
                self.outputVolume = volume
            }
        }
    }

    // 更新默认设备
    func updateDefaultDevices() {
        print("\u{001B}[34m[更新]\u{001B}[0m 更新默认音频设备")

        // 获取默认输出设备
        var outputAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var outputDeviceID: AudioDeviceID = 0
        var propertySize = UInt32(MemoryLayout<AudioDeviceID>.size)

        let outputStatus = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &outputAddress,
            0,
            nil,
            &propertySize,
            &outputDeviceID
        )

        if outputStatus == noErr, outputDeviceID != 0 {
            if let device = AudioDevice(deviceID: outputDeviceID) {
                let previousDevice = self.selectedOutputDevice

                // 只在设备变化时更新
                if previousDevice?.id != device.id {
                    print("\u{001B}[32m[设备变化]\u{001B}[0m 默认输出设备更改为: \(device.name)")

                    // 如果原来的设备有音量监听器，先移除
                    if let oldDevice = previousDevice {
                        self.removeVolumeListenerForDevice(oldDevice, isInput: false)
                    }

                    // 更新设备并获取音量
                    self.selectedOutputDevice = device
                    self.outputVolume = device.getVolume()

                    // 为新设备设置音量监听器
                    self.setupVolumeListenerForDevice(device, isInput: false)
                }
            }
        }

        // 获取默认输入设备
        var inputAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var inputDeviceID: AudioDeviceID = 0
        propertySize = UInt32(MemoryLayout<AudioDeviceID>.size)

        let inputStatus = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &inputAddress,
            0,
            nil,
            &propertySize,
            &inputDeviceID
        )

        if inputStatus == noErr, inputDeviceID != 0 {
            if let device = AudioDevice(deviceID: inputDeviceID) {
                let previousDevice = self.selectedInputDevice

                // 只在设备变化时更新
                if previousDevice?.id != device.id {
                    print("\u{001B}[32m[设备变化]\u{001B}[0m 默认输入设备更改为: \(device.name)")

                    // 如果原来的设备有音量监听器，先移除
                    if let oldDevice = previousDevice {
                        self.removeVolumeListenerForDevice(oldDevice, isInput: true)
                    }

                    // 更新设备并获取音量
                    self.selectedInputDevice = device
                    self.inputVolume = device.getVolume()

                    // 为新设备设置音量监听器
                    self.setupVolumeListenerForDevice(device, isInput: true)
                }
            }
        }
    }

    // 蓝牙设备音量同步
    func syncBluetoothDeviceVolume(device: AudioDevice, isInput: Bool) {
        // 仅对蓝牙设备执行此操作
        if device.uid.lowercased().contains("bluetooth") {
            print("\u{001B}[34m[蓝牙]\u{001B}[0m 同步蓝牙\(isInput ? "输入" : "输出")设备 '\(device.name)' 音量")

            // 获取设备当前音量
            let deviceVolume = device.getVolume()

            if isInput {
                if abs(self.inputVolume - deviceVolume) > 0.01 {
                    print("\u{001B}[32m[蓝牙同步]\u{001B}[0m 更新输入设备音量: \(Int(deviceVolume * 100))%")
                    self.inputVolume = deviceVolume
                }
            } else {
                if abs(self.outputVolume - deviceVolume) > 0.01 {
                    print("\u{001B}[32m[蓝牙同步]\u{001B}[0m 更新输出设备音量: \(Int(deviceVolume * 100))%")
                    self.outputVolume = deviceVolume
                }
            }
        }
    }

    // 设置默认输出设备
    public func setDefaultOutputDevice(_ device: AudioDevice) {
        // 如果已经是当前设备，则避免重复设置
        if self.selectedOutputDevice?.id == device.id {
            return
        }

        var deviceID = device.id
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        let status = AudioObjectSetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            UInt32(MemoryLayout<AudioDeviceID>.size),
            &deviceID
        )

        if status == noErr {
            print("[DEVICE] Successfully set default output device: \(device.name)")
            self.selectedOutputDevice = device
            // 保存为用户选择的设备
            self.userSelectedOutputUID = device.uid
            // 同时保存到设置中，避免直接使用settings.defaultOutputDeviceUID触发循环
            if self.settings.defaultOutputDeviceUID != device.uid {
                self.settings.defaultOutputDeviceUID = device.uid
            }
        } else {
            print("[ERROR] Failed to set default output device: \(status)")
        }
    }

    // 设置默认输入设备
    public func setDefaultInputDevice(_ device: AudioDevice) {
        // 如果已经是当前设备，则避免重复设置
        if self.selectedInputDevice?.id == device.id {
            return
        }

        var deviceID = device.id
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        let status = AudioObjectSetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            UInt32(MemoryLayout<AudioDeviceID>.size),
            &deviceID
        )

        if status == noErr {
            print("[DEVICE] Successfully set default input device: \(device.name)")
            self.selectedInputDevice = device
            // 保存为用户选择的设备
            self.userSelectedInputUID = device.uid
            // 同时保存到设置中，避免直接使用settings.defaultInputDeviceUID触发循环
            if self.settings.defaultInputDeviceUID != device.uid {
                self.settings.defaultInputDeviceUID = device.uid
            }
        } else {
            print("[ERROR] Failed to set default input device: \(status)")
        }
    }

    // [Cursor AI] Let new UI call forceApplySmartDeviceSwapping
    public func forceApplySmartDeviceSwapping() {
        // 检查 Smart Swaps 是否启用
        let smartSwapsEnabled = UserDefaults.standard.bool(forKey: "enableSmartDeviceSwapping")
        if !smartSwapsEnabled {
            print("\u{001B}[33m[Smart Swaps]\u{001B}[0m 智能切换功能未启用，跳过设备应用")
            return
        }

        print("\u{001B}[32m[Smart Swaps]\u{001B}[0m 正在应用智能设备切换设置...")

        // 获取用户首选的输出设备UID
        let preferredOutputUID = UserDefaults.standard.string(forKey: "backupOutputDeviceUID") ?? ""
        if !preferredOutputUID.isEmpty {
            // 查找匹配的输出设备
            if let outputDevice = outputDevices.first(where: { $0.uid == preferredOutputUID }) {
                print("\u{001B}[32m[Smart Swaps]\u{001B}[0m 应用首选输出设备: \(outputDevice.name)")
                self.setDefaultOutputDevice(outputDevice)
            } else {
                print("\u{001B}[33m[Smart Swaps]\u{001B}[0m 首选输出设备未找到或不可用: \(preferredOutputUID)")
            }
        }

        // 获取用户首选的输入设备UID
        let preferredInputUID = UserDefaults.standard.string(forKey: "backupInputDeviceUID") ?? ""
        if !preferredInputUID.isEmpty {
            // 查找匹配的输入设备
            if let inputDevice = inputDevices.first(where: { $0.uid == preferredInputUID }) {
                print("\u{001B}[32m[Smart Swaps]\u{001B}[0m 应用首选输入设备: \(inputDevice.name)")
                self.setDefaultInputDevice(inputDevice)
            } else {
                print("\u{001B}[33m[Smart Swaps]\u{001B}[0m 首选输入设备未找到或不可用: \(preferredInputUID)")
            }
        }
    }
}
