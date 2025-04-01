import SwiftUI
import AppKit

struct DeviceButton: View {
    let device: AudioDevice
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(device.name)
                .foregroundColor(isSelected ? .accentColor : .primary)
        }
        .buttonStyle(.plain)
    }
}

struct DeviceListItem: View {
    let device: AudioDevice
    let isSelected: Bool
    let onTap: () -> Void
    
    var deviceIcon: String {
        if device.name.contains("MacBook Pro") {
            return device.hasInput ? "laptopcomputer" : "laptopcomputer"
        } else if device.name.contains("HDR") || device.name.contains("Display") {
            return "display"
        } else if device.name.contains("AirPods") || device.name.contains("Headphones") {
            return "airpodspro"
        } else if device.name.contains("iPhone") {
            return "iphone"
        } else {
            return device.hasInput ? "mic" : "speaker.wave.2"
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: deviceIcon)
                    .font(.system(size: 13))
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                    .frame(width: 18)
                
                Text(device.name)
                    .font(.system(size: 13))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11))
                        .foregroundColor(.accentColor)
                }
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
        }
        .buttonStyle(DeviceButtonStyle())
    }
}

struct DeviceSection: View {
    let title: String
    let devices: [AudioDevice]
    let selectedDevice: AudioDevice?
    let onDeviceSelected: (AudioDevice) -> Void
    let volumeControl: (() -> VolumeSlider)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
            
            ForEach(devices) { device in
                DeviceListItem(device: device, isSelected: device.id == selectedDevice?.id) {
                    onDeviceSelected(device)
                }
            }
            
            if let volumeControl = volumeControl {
                volumeControl()
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
            }
        }
    }
}

struct VolumeControl: View {
    @ObservedObject var audioManager: AudioManager
    
    var body: some View {
        VStack(spacing: 12) {
            if let outputDevice = audioManager.selectedOutputDevice {
                VolumeSlider(
                    icon: "speaker.wave.2.fill",
                    volume: Binding(
                        get: { audioManager.outputVolume },
                        set: { audioManager.setVolumeForDevice(device: outputDevice, volume: $0, isInput: false) }
                    )
                )
            }
            
            if let inputDevice = audioManager.selectedInputDevice {
                VolumeSlider(
                    icon: "mic.fill",
                    volume: Binding(
                        get: { audioManager.inputVolume },
                        set: { audioManager.setVolumeForDevice(device: inputDevice, volume: $0, isInput: true) }
                    )
                )
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }
}

struct VolumeSlider: View {
    let icon: String
    @Binding var volume: Float
    
    var body: some View {
        Slider(value: $volume, in: 0...1)
            .controlSize(.regular)
            .accentColor(.green)
    }
}

// 修改平衡锁定按钮，使用英文界面并支持设备平衡控制状态提示
struct BalanceLockButton: View {
    @Binding var isLocked: Bool
    let onToggleLock: () -> Void
    let device: AudioDevice?
    
    var supportsBalanceControl: Bool {
        return device?.supportsBalanceControl ?? false
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Lock Balance")
                    .font(.system(size: 13))
                    .foregroundColor(.white)
                
                if isLocked && !supportsBalanceControl {
                    Text("(Device not supported)")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button(action: onToggleLock) {
                Image(systemName: isLocked ? "lock.fill" : "lock.open.fill")
                    .font(.system(size: 14))
                    .foregroundColor(isLocked ? 
                                    (supportsBalanceControl ? .white : .green.opacity(0.5)) 
                                    : .secondary)
            }
            .buttonStyle(PlainButtonStyle())
            .help(isLocked ? "Unlock balance" : "Lock balance")
        }
    }
}

struct SoundSettingsButton: View {
    var body: some View {
        Button(action: {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.sound") {
                NSWorkspace.shared.open(url)
            }
        }) {
            HStack {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                
                Text("Sound Settings...")
                    .font(.system(size: 14))
                
                Spacer()
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .buttonStyle(DeviceButtonStyle())
    }
}

struct QuitButton: View {
    var body: some View {
        Button(action: {
            NSApplication.shared.terminate(nil)
        }) {
            HStack {
                Image(systemName: "power")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                
                Text("Quit")
                    .font(.system(size: 14))
                
                Spacer()
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .buttonStyle(DeviceButtonStyle())
    }
}

struct DeviceButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? (colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.1)) : Color.clear)
    }
}

struct DeviceSelectionInfo {
    let device: AudioDevice
    let isInput: Bool
}

// 创建自定义的设备选择弹出菜单
struct DeviceSelectionPopover: View {
    let devices: [AudioDevice]
    let selectedDevice: AudioDevice?
    let onDeviceSelected: (AudioDevice) -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(devices) { device in
                Button(action: {
                    onDeviceSelected(device)
                    onDismiss()
                }) {
                    HStack {
                        Text(device.name)
                            .font(.system(size: 13))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        if selectedDevice?.id == device.id {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12))
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                .background(selectedDevice?.id == device.id ? Color.white.opacity(0.1) : Color.clear)
                
                if device.id != devices.last?.id {
                    Divider()
                        .background(Color.white.opacity(0.2))
                }
            }
        }
        .frame(width: 220)
        .background(Color.black.opacity(0.9))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
        )
    }
}

struct DeviceControlCard: View {
    let icon: String
    let title: String
    let device: AudioDevice?
    let devices: [AudioDevice]
    let onDeviceSelected: (AudioDevice) -> Void
    var volume: Binding<Float>?
    var isBalanceLocked: Binding<Bool>?
    var onToggleBalanceLock: (() -> Void)?
    var showVolume: Bool = true
    var showBalanceLock: Bool = false
    var isDisabled: Bool = false
    
    @State private var showDevicePopover = false
    @State private var popoverAnchor = CGPoint.zero
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                    
                    if let device = device {
                        Text(device.name)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if !devices.isEmpty {
                    Button(action: {
                        showDevicePopover.toggle()
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(width: 20, height: 20)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .background(GeometryReader { geo -> Color in
                        DispatchQueue.main.async {
                            // 获取按钮位置以便正确定位弹出窗口
                            let rect = geo.frame(in: .global)
                            popoverAnchor = CGPoint(x: rect.midX, y: rect.midY)
                        }
                        return Color.clear
                    })
                    .popover(isPresented: $showDevicePopover, arrowEdge: .trailing) {
                        DeviceSelectionPopover(
                            devices: devices,
                            selectedDevice: device,
                            onDeviceSelected: onDeviceSelected,
                            onDismiss: { showDevicePopover = false }
                        )
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            
            // 音量控制
            if showVolume, let volume = volume {
                VolumeSlider(
                    icon: icon,
                    volume: volume
                )
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            
            // 平衡锁定按钮
            if showBalanceLock, let isLocked = isBalanceLocked, let toggleLock = onToggleBalanceLock {
                BalanceLockButton(
                    isLocked: isLocked,
                    onToggleLock: toggleLock,
                    device: device
                )
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
        }
        .background(Color.black.opacity(0.7))
        .cornerRadius(8)
    }
}

struct ModeSelectionCard: View {
    @State private var selectedMode = 0
    let modes = ["自动", "工作", "娱乐", "会议"]
    
    var body: some View {
        VStack(spacing: 8) {
            Text("模式")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.top, 8)
            
            HStack(spacing: 8) {
                ForEach(0..<modes.count, id: \.self) { index in
                    Button(action: { selectedMode = index }) {
                        Text(modes[index])
                            .font(.system(size: 12))
                            .foregroundColor(selectedMode == index ? .white : .primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedMode == index ? Color.accentColor : Color.clear)
                            .cornerRadius(6)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
        .cornerRadius(8)
    }
}

struct AudioVisualizerView: View {
    @State private var levels: [CGFloat] = Array(repeating: 0.2, count: 20)
    let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<levels.count, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.accentColor.opacity(0.8))
                    .frame(width: 3)
                    .frame(height: levels[index] * 40)
            }
        }
        .onReceive(timer) { _ in
            withAnimation(.linear(duration: 0.05)) {
                for i in 0..<levels.count {
                    levels[i] = CGFloat.random(in: 0.1...1.0)
                }
            }
        }
        .padding(.horizontal, 12)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
        .cornerRadius(8)
    }
}

struct VisualEffectView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.blendingMode = .behindWindow
        view.state = .active
        view.material = .hudWindow
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

@available(macOS 13.0, *)
struct MenuBarView: View {
    @StateObject private var audioManager = AudioManager.shared
    @State private var showSettings = false
    @State private var showOutputDeviceMenu = false
    @State private var showInputDeviceMenu = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部Logo
            HStack {
                Image(systemName: "fish.fill")
                    .font(.system(size: 28))
                    .foregroundColor(Color(red: 0.4, green: 0.9, blue: 0.6))
                
                Text("Tuna")
                    .font(.system(size: 42, weight: .medium))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 20)
            .padding(.bottom, 10)
            
            // 内容区域
            VStack(spacing: 1) {
                // 音频输出设备
                AudioDeviceCard(
                    icon: "headphones",
                    title: "Audio Output",
                    deviceName: audioManager.selectedOutputDevice?.name ?? "None",
                    volume: Binding(
                        get: { audioManager.outputVolume },
                        set: { volume in
                            if let device = audioManager.selectedOutputDevice {
                                audioManager.setVolumeForDevice(device: device, volume: volume, isInput: false)
                            }
                        }
                    ),
                    showDeviceMenu: $showOutputDeviceMenu,
                    devices: audioManager.outputDevices,
                    onDeviceSelected: { device in
                        audioManager.setDefaultDevice(device, forInput: false)
                        showOutputDeviceMenu = false
                    },
                    isBalanceLocked: audioManager.isOutputBalanceLocked,
                    onToggleBalanceLock: { audioManager.toggleOutputBalanceLock() },
                    currentDevice: audioManager.selectedOutputDevice
                )
                
                // 音频输入设备
                AudioDeviceCard(
                    icon: "mic.fill",
                    title: "Audio Input",
                    deviceName: audioManager.selectedInputDevice?.name ?? "None",
                    volume: Binding(
                        get: { audioManager.inputVolume },
                        set: { volume in
                            if let device = audioManager.selectedInputDevice {
                                audioManager.setVolumeForDevice(device: device, volume: volume, isInput: true)
                            }
                        }
                    ),
                    showDeviceMenu: $showInputDeviceMenu,
                    devices: audioManager.inputDevices,
                    onDeviceSelected: { device in
                        audioManager.setDefaultDevice(device, forInput: true)
                        showInputDeviceMenu = false
                    }
                )
                
                // 听写功能
                DictationCard()
                
                // 模式选择
                ModeCard()
            }
            .background(Color.black.opacity(0.3))
            .cornerRadius(12)
            .padding(.horizontal, 16)
            
            // 底部按钮
            HStack(spacing: 10) {
                // Exit 按钮
                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Text("Exit")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(PlainButtonStyle())
                .background(Color(red: 0.2, green: 0.5, blue: 0.4))
                .cornerRadius(8)
                
                // System Settings 按钮
                Button {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.sound") {
                        NSWorkspace.shared.open(url)
                    }
                } label: {
                    Text("System Settings")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(PlainButtonStyle())
                .background(Color(red: 0.2, green: 0.3, blue: 0.3))
                .cornerRadius(8)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        .frame(width: 320)
        .background(Color(red: 0.08, green: 0.25, blue: 0.2))
    }
}

// 音频设备卡片视图
struct AudioDeviceCard: View {
    let icon: String
    let title: String
    let deviceName: String
    @Binding var volume: Float
    @Binding var showDeviceMenu: Bool
    let devices: [AudioDevice]
    let onDeviceSelected: (AudioDevice) -> Void
    var isBalanceLocked: Bool? = nil
    var onToggleBalanceLock: (() -> Void)? = nil
    var currentDevice: AudioDevice? = nil
    
    var supportsBalanceControl: Bool {
        return currentDevice?.supportsBalanceControl ?? false
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 标题区域
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                    .frame(width: 24)
                
                Text(title)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: { showDeviceMenu.toggle() }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                }
                .buttonStyle(PlainButtonStyle())
                .popover(isPresented: $showDeviceMenu, arrowEdge: .trailing) {
                    VStack(spacing: 0) {
                        ForEach(devices) { device in
                            Button(action: {
                                onDeviceSelected(device)
                            }) {
                                HStack {
                                    Text(device.name)
                                        .font(.system(size: 13))
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                    
                                    Spacer()
                                    
                                    if device.name == deviceName {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 12))
                                            .foregroundColor(Color(red: 0.4, green: 0.9, blue: 0.6))
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(PlainButtonStyle())
                            .background(device.name == deviceName ? Color.white.opacity(0.1) : Color.clear)
                            
                            if device.id != devices.last?.id {
                                Divider()
                                    .background(Color.white.opacity(0.2))
                            }
                        }
                    }
                    .frame(width: 220)
                    .background(Color(red: 0.1, green: 0.3, blue: 0.25))
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)
            .padding(.bottom, 4)
            
            // 设备名称
            Text(deviceName)
                .font(.system(size: 18))
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
            
            // 音量滑块
            HStack {
                Slider(value: $volume, in: 0...1)
                    .accentColor(Color(red: 0.4, green: 0.9, blue: 0.6))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            
            // 平衡锁定按钮 (仅适用于音频输出)
            if let isLocked = isBalanceLocked, let toggleLock = onToggleBalanceLock {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Lock Balance")
                            .font(.system(size: 13))
                            .foregroundColor(.white)
                        
                        if isLocked && !supportsBalanceControl {
                            Text("(Device not supported)")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: toggleLock) {
                        Image(systemName: isLocked ? "lock.fill" : "lock.open.fill")
                            .font(.system(size: 14))
                            .foregroundColor(isLocked ? 
                                            (supportsBalanceControl ? .white : Color(red: 0.4, green: 0.9, blue: 0.6).opacity(0.5)) 
                                            : .secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help(isLocked ? "Unlock balance" : "Lock balance")
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 10)
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.2))
    }
}

// 听写功能卡片
struct DictationCard: View {
    @State private var visualizerLevels = Array(repeating: CGFloat.random(in: 0.1...0.9), count: 20)
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 标题区域
            HStack {
                Image(systemName: "text.bubble.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                    .frame(width: 24)
                
                Text("Dictation")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)
            .padding(.bottom, 4)
            
            // 状态文本
            Text("Listening...")
                .font(.system(size: 18))
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
            
            // 音频可视化
            HStack(spacing: 3) {
                ForEach(0..<visualizerLevels.count, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(Color(red: 0.4, green: 0.9, blue: 0.6))
                        .frame(width: 3, height: visualizerLevels[index] * 40)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .onReceive(timer) { _ in
                withAnimation(.easeInOut(duration: 0.1)) {
                    for i in 0..<visualizerLevels.count {
                        visualizerLevels[i] = CGFloat.random(in: 0.1...0.9)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.2))
    }
}

// 模式选择卡片
struct ModeCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 标题区域
            HStack {
                Image(systemName: "waveform.path")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                    .frame(width: 24)
                
                Text("Mode")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {}) {
                    HStack {
                        Text("Automatic")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 16)
        }
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.2))
    }
}