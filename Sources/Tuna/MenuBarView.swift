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

// 修改后的 DeviceMenuItem，支持完整展示设备名称，避免截断，并添加 tooltip
struct DeviceMenuItem: View {
    let device: AudioDevice
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 8) {
                // 设备图标 - 根据设备类型显示不同图标
                deviceIcon
                    .font(.system(size: 13))
                    .foregroundColor(isSelected ? Color(red: 0.4, green: 0.9, blue: 0.6) : .secondary)
                    .frame(width: 18)
                
                // 设备名称
                Text(device.name)
                    .font(.system(size: 13))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Spacer()
                
                // 选中标记
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12))
                        .foregroundColor(Color(red: 0.4, green: 0.9, blue: 0.6))
                        .frame(width: 16)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .background(isSelected ? Color.white.opacity(0.1) : Color.clear)
        .help(device.name) // 添加tooltip提示
    }
    
    // 根据设备名称选择合适的图标
    var deviceIcon: some View {
        let iconName: String
        
        if device.name.contains("MacBook Pro") {
            iconName = device.hasInput ? "laptopcomputer" : "laptopcomputer"
        } else if device.name.contains("HDR") || device.name.contains("Display") {
            iconName = "display"
        } else if device.name.contains("AirPods") || device.name.contains("Headphones") {
            iconName = "airpodspro"
        } else if device.name.contains("iPhone") {
            iconName = "iphone"
        } else {
            iconName = device.hasInput ? "mic" : "speaker.wave.2"
        }
        
        return Image(systemName: iconName)
    }
}

// 设备菜单列表组件
struct DeviceMenuList: View {
    let devices: [AudioDevice]
    let selectedDeviceName: String
    let onDeviceSelected: (AudioDevice) -> Void
    
    // 计算所需的最小宽度以完整显示所有设备名称
    private var minWidth: CGFloat {
        // 基础宽度（包含边距和图标空间）
        let baseWidth: CGFloat = 220
        
        // 计算最长设备名称的宽度
        let maxDeviceNameWidth = devices.map { device in
            let font = NSFont.systemFont(ofSize: 13)
            let attributes = [NSAttributedString.Key.font: font]
            return device.name.size(withAttributes: attributes).width
        }.max() ?? 0
        
        // 考虑图标、checkmark和边距的额外宽度
        let extraWidth: CGFloat = 70
        
        // 返回至少为baseWidth，但如果有更长的设备名称则可能更大
        return max(baseWidth, maxDeviceNameWidth + extraWidth)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题
            Text("Select Device")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.white.opacity(0.8))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.4))
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // 设备列表
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(devices) { device in
                        DeviceMenuItem(
                            device: device,
                            isSelected: device.name == selectedDeviceName,
                            onSelect: { onDeviceSelected(device) }
                        )
                        
                        if device.id != devices.last?.id {
                            Divider()
                                .background(Color.white.opacity(0.2))
                        }
                    }
                }
            }
            .frame(maxHeight: min(CGFloat(devices.count) * 36, 300)) // 限制最大高度，避免菜单过长
        }
        .frame(width: minWidth) // 使用动态计算的宽度
        .background(Color.black.opacity(0.9))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
        )
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
            .accentColor(Color(red: 0.4, green: 0.9, blue: 0.6))
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
            .background(configuration.isPressed ? Color.white.opacity(0.1) : Color.clear)
    }
}

struct DeviceSelectionInfo {
    let device: AudioDevice
    let isInput: Bool
}

 
// 修改后的 DeviceSelectionPopover：完整显示设备名并支持 tooltip
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
                        // 显示设备名称 + tooltip
                        Text(device.name)
                            .font(.system(size: 13))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .help(device.name) // 悬停显示完整设备名

                        Spacer()

                        // 显示选中标记
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

                // 分隔线（非最后一个）
                if device.id != devices.last?.id {
                    Divider()
                        .background(Color.white.opacity(0.2))
                }
            }
        }
        .fixedSize(horizontal: true, vertical: false) // 自动根据内容宽度调整
        .background(Color.black.opacity(0.9))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
        .padding(.horizontal, 4)
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
    var currentDevice: AudioDevice? = nil
    
    @State private var isHovering = false
    @State private var hoverTimer: Timer? = nil
    @State private var anchorPoint = CGPoint.zero
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 标题区域
            HStack {
                Image(systemName: title.contains("Output") ? "speaker.wave.2" : "mic")
                    .font(.system(size: 18))
                    .foregroundColor(Color(red: 0.4, green: 0.9, blue: 0.6))
                    .frame(width: 24)
                
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .textCase(.uppercase)
                    .foregroundColor(.white)
                
                Spacer()
                
                // 显示音量百分比
                Text("\(Int(volume * 100))%")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.trailing, 4)
                
                // 设备选择按钮
                Button(action: {
                    showDeviceMenu.toggle()
                }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.6))
                        .rotationEffect(.degrees(showDeviceMenu ? 90 : 0))
                        .animation(.spring(), value: showDeviceMenu)
                }
                .buttonStyle(PlainButtonStyle())
                .background(GeometryReader { geo -> Color in
                    DispatchQueue.main.async {
                        let rect = geo.frame(in: .global)
                        anchorPoint = CGPoint(x: rect.midX, y: rect.midY)
                    }
                    return Color.clear
                })
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)
            
            // 设备名称 - 添加提示并处理长文本
            Text(deviceName)
                .font(.system(size: 16))
                .foregroundColor(Color(red: 0.4, green: 0.9, blue: 0.6))
                .lineLimit(1)
                .truncationMode(.tail)
                .help(deviceName) // 添加tooltip提示
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            
            // 音量滑块
            HStack {
                Slider(value: $volume, in: 0...1)
                    .accentColor(Color(red: 0.4, green: 0.9, blue: 0.6))
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.2))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.05), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
        // 使用自定义位置的popover
        .background(
            EmptyView()
                .frame(width: 0, height: 0)
                .allowsHitTesting(false)
                .popover(isPresented: $showDeviceMenu, arrowEdge: .trailing) {
                    DeviceMenuList(
                        devices: devices,
                        selectedDeviceName: deviceName,
                        onDeviceSelected: { device in
                            onDeviceSelected(device)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                // 选择设备后延迟关闭菜单
                                showDeviceMenu = false
                            }
                        }
                    )
                }
        )
        // 混合悬停和点击交互
        .onHover { hovering in
            isHovering = hovering
            if hovering {
                // 可选：增加悬停效果
                hoverTimer?.invalidate()
                hoverTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: false) { _ in
                    if isHovering && !showDeviceMenu {
                        showDeviceMenu = true
                    }
                }
            } else {
                hoverTimer?.invalidate()
            }
        }
    }
}

// 模式选择卡片
struct ModeCard: View {
    @StateObject private var modeManager = AudioModeManager.shared
    @State private var isAddingNewMode = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 标题区域
            HStack {
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 18))
                    .foregroundColor(Color(red: 0.4, green: 0.9, blue: 0.6))
                    .frame(width: 24)
                
                Text("MODE")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("Automatic")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.leading, 4)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.2))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.05), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
        .sheet(isPresented: $isAddingNewMode) {
            AddModeView(isPresented: $isAddingNewMode)
        }
    }
}

// 添加模式视图
struct AddModeView: View {
    @Binding var isPresented: Bool
    @State private var newModeName = ""
    @StateObject private var modeManager = AudioModeManager.shared
    @StateObject private var audioManager = AudioManager.shared
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Add New Mode")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Mode Name")
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                TextField("Enter mode name", text: $newModeName)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(8)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(6)
                    .foregroundColor(.white)
                    .focused($isTextFieldFocused)
                    .onAppear {
                        // 确保在视图出现时自动获得焦点
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.isTextFieldFocused = true
                        }
                    }
                    // 确保接收按键事件
                    .focusable(true)
                    // 提高对比度使文本更明显
                    .colorScheme(.dark)
            }
            .padding(.horizontal)
            
            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.gray.opacity(0.3))
                .cornerRadius(8)
                
                Spacer()
                
                Button("Add") {
                    // 添加新模式
                    if !newModeName.isEmpty {
                        let outputUID = audioManager.selectedOutputDevice?.uid ?? ""
                        let inputUID = audioManager.selectedInputDevice?.uid ?? ""
                        let outputVolume = audioManager.outputVolume
                        let inputVolume = audioManager.inputVolume
                        
                        let newMode = modeManager.createCustomMode(
                            name: newModeName,
                            outputDeviceUID: outputUID,
                            inputDeviceUID: inputUID,
                            outputVolume: outputVolume,
                            inputVolume: inputVolume
                        )
                        
                        // 自动切换到新模式
                        modeManager.currentModeID = newMode.id
                    }
                    isPresented = false
                }
                .disabled(newModeName.isEmpty)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(newModeName.isEmpty ? Color.gray.opacity(0.2) : Color(red: 0.4, green: 0.9, blue: 0.6))
                .cornerRadius(8)
            }
            .padding()
        }
        .padding()
        .frame(width: 400, height: 200)
        .background(Color(red: 0.0, green: 0.12, blue: 0.06))
        .cornerRadius(12)
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
    @State private var showOutputDeviceMenu = false
    @State private var showInputDeviceMenu = false
    
    var body: some View {
        VStack(spacing: 16) {
            // 标题和图标
            VStack(spacing: 8) {
                Image(systemName: "fish")
                    .font(.system(size: 36))
                    .foregroundColor(Color(red: 0.4, green: 0.9, blue: 0.6))
                
                Text("Tuna")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.top, 16)
            
            VStack(spacing: 12) {
                // 输出设备
                AudioDeviceCard(
                    icon: "speaker.wave.2",
                    title: "Audio Output",
                    deviceName: audioManager.selectedOutputDevice?.name ?? "None",
                    volume: Binding<Float>(
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
                        // 不需要在这里关闭菜单，由悬停逻辑处理
                    },
                    currentDevice: audioManager.selectedOutputDevice
                )
                
                // 输入设备
                AudioDeviceCard(
                    icon: "mic",
                    title: "Audio Input",
                    deviceName: audioManager.selectedInputDevice?.name ?? "None",
                    volume: Binding<Float>(
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
                        // 不需要在这里关闭菜单，由悬停逻辑处理
                    },
                    currentDevice: audioManager.selectedInputDevice
                )
                
                // 听写功能
                DictationCard()
                
                // 模式选择
                ModeCard()
            }
            .padding(.horizontal, 16)
            
            // 底部按钮
            HStack(spacing: 12) {
                // Exit 按钮
                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Text("Exit")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(PlainButtonStyle())
                .background(Color.black.opacity(0.2))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.black.opacity(0.1), lineWidth: 0.5)
                )
                
                // Settings 按钮
                Button {
                    NotificationCenter.default.post(name: NSNotification.Name("showSettings"), object: nil)
                } label: {
                    Text("Settings")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(PlainButtonStyle())
                .background(Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(red: 0.4, green: 0.9, blue: 0.6), lineWidth: 1.5)
                )
                .cornerRadius(12)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .padding(.vertical, 10)
        .frame(width: 300)
        .background(
            ZStack {
                Color(red: 0.0, green: 0.12, blue: 0.06)
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black.opacity(0.0),
                        Color.black.opacity(0.3)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        )
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.05), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

// 听写功能卡片
struct DictationCard: View {
    @State private var isListening = true
    private let animationTimer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    @State private var animationPhase = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 标题区域
            HStack {
                Image(systemName: "text.bubble.fill")
                    .font(.system(size: 18))
                    .foregroundColor(Color(red: 0.4, green: 0.9, blue: 0.6))
                    .frame(width: 24)
                
                Text("DICTATION")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)
            
            // 状态指示和波形图并排
            HStack(alignment: .center) {
                Text("Listening...")
                    .font(.system(size: 16))
                    .foregroundColor(Color(red: 0.4, green: 0.9, blue: 0.6))
                
                Spacer()
                
                // 音频波形可视化
                HStack(spacing: 4) {
                    ForEach(0..<10, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(Color(red: 0.4, green: 0.9, blue: 0.6))
                            .frame(width: 3, height: getBarHeight(index: index))
                    }
                }
                .frame(height: 30)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            .onReceive(animationTimer) { _ in
                animationPhase = (animationPhase + 1) % 100
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.2))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.05), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
    }
    
    private func getBarHeight(index: Int) -> CGFloat {
        let baseHeight: CGFloat = 3
        let maxAdditionalHeight: CGFloat = 25
        
        // 创建看起来随机但有模式的高度变化
        let phaseOffset = (index * 7 + animationPhase) % 100
        let percentage = sin(Double(phaseOffset) / 15.0)
        let height = baseHeight + (abs(percentage) * maxAdditionalHeight)
        
        return height
    }
}

// 添加hoverColorView函数
func hoverColorView(isHovered: Binding<Bool>, isSelected: Bool) -> some View {
    Color(isSelected ? .selectedControlColor : (isHovered.wrappedValue ? .controlBackgroundColor : .clear))
        .opacity(isSelected ? 0.6 : (isHovered.wrappedValue ? 0.3 : 0))
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
                    .foregroundColor(isSelected ? Color(red: 0.4, green: 0.9, blue: 0.6) : .secondary)
                    .frame(width: 18)
                
                Text(device.name)
                    .font(.system(size: 13))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .truncationMode(.middle)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11))
                        .foregroundColor(Color(red: 0.4, green: 0.9, blue: 0.6))
                }
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
        }
        .buttonStyle(DeviceButtonStyle())
        .help(device.name)
    }
}