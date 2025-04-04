import SwiftUI
import Views
import AppKit

// 确保导入 DictationView 和相关模型
@_exported import struct Views.DictationView

// 重复声明，已在 DictationSettingsView.swift 中定义
// extension DictationManager: DictationManagerProtocol {}

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
            HStack(spacing: 10) {
                // 设备图标 - 根据设备类型显示不同图标
                deviceIcon
                    .font(.system(size: 13))
                    .foregroundColor(isSelected ? Color.white : Color.white.opacity(0.6))
                    .frame(width: 16)
                
                // 设备名称
                Text(device.name)
                    .font(.system(size: 13))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Spacer()
                
                // 选中标记
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11))
                        .foregroundColor(.white)
                        .frame(width: 16)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .background(isSelected ? Color.white.opacity(0.1) : Color.clear)
        .cornerRadius(4)
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
        // 基础宽度（包含边距和图标空间）- 增加基础宽度
        let baseWidth: CGFloat = 350
        
        // 计算最长设备名称的宽度
        let maxDeviceNameWidth = devices.map { device in
            let font = NSFont.systemFont(ofSize: 13)
            let attributes = [NSAttributedString.Key.font: font]
            return device.name.size(withAttributes: attributes).width
        }.max() ?? 0
        
        // 考虑图标、checkmark和边距的额外宽度
        let extraWidth: CGFloat = 80
        
        // 返回至少为baseWidth，但如果有更长的设备名称则可能更大
        return max(baseWidth, maxDeviceNameWidth + extraWidth)
    }
    
    // 计算列表内容的精确高度
    private var exactContentHeight: CGFloat {
        // 单个项目高度
        let itemHeight: CGFloat = 36
        // 设备数量
        let count = CGFloat(devices.count)
        // 总高度 = 所有设备项目高度
        return count * itemHeight
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 直接显示设备列表，移除标题栏
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(devices) { device in
                        DeviceMenuItem(
                            device: device,
                            isSelected: device.name == selectedDeviceName,
                            onSelect: { onDeviceSelected(device) }
                        )
                        }
                    }
                .padding(.vertical, 4)
                }
            // 使用计算的内容精确高度，但限制最大高度为屏幕高度的40%
            .frame(height: min(exactContentHeight + 8, NSScreen.main?.frame.height ?? 1000 * 0.4))
        }
        .frame(width: minWidth) // 使用动态计算的宽度
        .background(
            ZStack {
                VisualEffectView(material: .popover, blendingMode: .behindWindow)
                Color.white.opacity(0.05)
            }
        )
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 3) // 添加阴影增强视觉层次
        .fixedSize(horizontal: true, vertical: false) // 强制使用计算的宽度
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
                                    (supportsBalanceControl ? .white : .white.opacity(0.5)) 
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
                                .foregroundColor(.white) // 改为白色
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                .background(selectedDevice?.id == device.id ? Color.white.opacity(0.1) : Color.clear)
                // 移除分隔线
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
    @State private var menuSize: CGSize = CGSize(width: 280, height: 300)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {  // 增加整体间距
            // 标题区域
            HStack {
                Image(systemName: title.contains("Output") ? "speaker.wave.2" : "mic")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                    .frame(width: 24)
                
                Text(title)
                    .font(.system(size: 14, weight: .semibold))  // 减小标题字体大小
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
                    print("\u{001B}[36m[UI]\u{001B}[0m Button clicked - toggle menu")
                    withAnimation(.easeInOut(duration: 0.1)) {
                        showDeviceMenu.toggle()
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.6))
                        .rotationEffect(.degrees(showDeviceMenu ? 90 : 0))
                        .animation(.spring(response: 0.2), value: showDeviceMenu)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 6)
                }
                .buttonStyle(PlainButtonStyle())
                .popover(isPresented: $showDeviceMenu, arrowEdge: .trailing) {
                    // 使用标准SwiftUI popover
                    DeviceMenuList(
                        devices: devices,
                        selectedDeviceName: deviceName,
                        onDeviceSelected: { device in
                            print("\u{001B}[36m[UI]\u{001B}[0m Device selected: \(device.name)")
                            onDeviceSelected(device)
                            showDeviceMenu = false
                        }
                    )
                }
                .id("deviceMenuButton-\(title)")
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 4)  // 减少底部间距
            
            // 设备名称 - 添加提示并处理长文本
            Text(deviceName)
                .font(.system(size: 14))  // 减小设备名称字体大小
                .foregroundColor(.white.opacity(0.9))  // 略微降低不透明度以区分标题
                .lineLimit(1)
                .truncationMode(.tail)
                .help(deviceName)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            
            // 音量滑块
            HStack {
                Slider(value: $volume, in: 0...1)
                    .accentColor(.white.opacity(0.8))
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                VisualEffectView(material: .popover, blendingMode: .behindWindow)
                Color.white.opacity(0.05)
            }
        )
        .cornerRadius(6) // 使用更小的圆角
        // 移除多余的边缘处理
        
        // 保留悬停逻辑
        .onHover { hovering in
            isHovering = hovering
            if hovering && !showDeviceMenu {
                hoverTimer?.invalidate()
                hoverTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: false) { _ in
                    if isHovering {
                        print("\u{001B}[36m[UI]\u{001B}[0m Hover timer triggered - show menu")
                        withAnimation(.easeInOut(duration: 0.1)) {
                            showDeviceMenu = true
                        }
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
                    .foregroundColor(.white)
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
        .background(
            ZStack {
                VisualEffectView(material: .popover, blendingMode: .behindWindow)
                Color.white.opacity(0.05)
            }
        )
        .cornerRadius(6) // 使用更小的圆角
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
                    .onAppear {
                        // 确保在视图出现时自动获得焦点
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.newModeName = "New Mode"
                        }
                    }
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
                .background(newModeName.isEmpty ? Color.gray.opacity(0.2) : Color.white.opacity(0.2))
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

// 添加NSVisualEffectView封装器，用于实现毛玻璃效果
struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
        visualEffectView.state = .active
        return visualEffectView
    }
    
    func updateNSView(_ visualEffectView: NSVisualEffectView, context: Context) {
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
    }
}

// 新增：NSPopover 包装器，用于精确控制弹出窗口位置
struct CustomPopover<Content: View>: NSViewRepresentable {
    @Binding var isPresented: Bool
    let content: Content
    let arrowEdge: NSRectEdge
    var contentSize: CGSize = CGSize(width: 300, height: 300)
    let buttonBounds: CGRect
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        // 移除之前的观察者以避免重复
        NotificationCenter.default.removeObserver(context.coordinator)
        
        if isPresented && context.coordinator.popover == nil {
            print("\u{001B}[36m[UI]\u{001B}[0m Creating popover with size: \(contentSize)")
            
            // 创建新的popover
            let popover = NSPopover()
            let hostingView = NSHostingView(rootView: content)
            hostingView.frame = NSRect(origin: .zero, size: contentSize)
            
            popover.contentViewController = NSViewController()
            popover.contentViewController?.view = hostingView
            popover.contentSize = contentSize
            popover.behavior = .transient
            popover.animates = true
            
            // 调整弹出窗口的外观
            if let appearance = NSAppearance(named: .darkAqua) {
                popover.appearance = appearance
            }
            
            // 移除边框
            popover.contentViewController?.view.layer?.borderWidth = 0
            
            // 记录弹出窗口引用
            context.coordinator.popover = popover
            
            // 监听弹出窗口关闭
            NotificationCenter.default.addObserver(
                context.coordinator,
                selector: #selector(Coordinator.popoverDidClose),
                name: NSPopover.didCloseNotification,
                object: popover
            )
            
            // 显示弹出窗口
            if let containerView = nsView.window?.contentView {
                print("\u{001B}[36m[UI]\u{001B}[0m Found container view, bounds: \(buttonBounds)")
                
                // 计算相对于窗口的位置
                var adjustedRect = NSRect(
                    x: buttonBounds.origin.x,
                    y: buttonBounds.origin.y,
                    width: max(buttonBounds.size.width, 4),
                    height: max(buttonBounds.size.height, 4)
                )
                
                // 调整位置，确保弹窗位于按钮右侧
                if arrowEdge == .maxX {
                    adjustedRect.origin.x = nsView.window!.frame.maxX - 2
                }
                
                print("\u{001B}[36m[UI]\u{001B}[0m Showing popover at: \(adjustedRect)")
                
                // 显示弹出窗口，箭头指向按钮位置
                popover.show(
                    relativeTo: adjustedRect,
                    of: containerView,
                    preferredEdge: arrowEdge
                )
            } else {
                print("\u{001B}[31m[ERROR]\u{001B}[0m No container view found")
            }
        } else if !isPresented && context.coordinator.popover != nil {
            // 关闭弹出窗口
            print("\u{001B}[36m[UI]\u{001B}[0m Closing popover")
            context.coordinator.popover?.close()
            context.coordinator.popover = nil
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(isPresented: $isPresented)
    }
    
    class Coordinator: NSObject {
        var popover: NSPopover?
        var isPresented: Binding<Bool>
        
        init(isPresented: Binding<Bool>) {
            self.isPresented = isPresented
        }
        
        @objc func popoverDidClose(_ notification: Notification) {
            // 当弹出窗口关闭时更新状态
            print("\u{001B}[36m[UI]\u{001B}[0m Popover did close")
            if isPresented.wrappedValue {
                self.isPresented.wrappedValue = false
            }
            popover = nil
        }
    }
}

@available(macOS 13.0, *)
struct MenuBarView: View {
    @ObservedObject private var audioManager = AudioManager.shared
    @ObservedObject private var dictationManager = DictationManager.shared
    @State private var showingSettings = false
    @State private var showingDictationSettings = false
    @State private var showingOutputDeviceList = false
    @State private var showingInputDeviceList = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部标题
            HStack {
                Image("TunaIcon") // 使用小图标
                    .resizable()
                    .frame(width: 24, height: 24)
                    .padding(.trailing, 4)
                
                Text("Tuna")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                    .alignmentGuide(.leading) { d in d[.leading] }
                
                Spacer()
            }
            .padding(.bottom, 16)
            
            // 设备控制部分
            VStack(spacing: 16) {
                // 输出设备部分
                audioDeviceSection(isInput: false)
                
                // 输入设备部分
                audioDeviceSection(isInput: true)
                
                // Dictation 部分
                TunaDictationView()
            }
            
            // 底部按钮区，修改为使用统一样式，Quit在左侧，Settings在右侧
            bottomButtons
        }
        .padding(16)
        .background(
            ZStack {
                // 使用毛玻璃效果作为背景，改用更浅的material
                VisualEffectView(material: .popover, blendingMode: .behindWindow)
                
                // 添加浅色渐变叠加层
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.95, green: 0.95, blue: 0.97).opacity(0.3),
                        Color(red: 0.9, green: 0.9, blue: 0.92).opacity(0.2)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .opacity(0.1)
            }
            .edgesIgnoringSafeArea(.all)
        )
        .cornerRadius(10)
        .frame(width: 350)
    }
    
    // 音频设备区域视图（显示设备名称和音量滑块）
    private func audioDeviceSection(isInput: Bool) -> some View {
        ZStack(alignment: .top) {
            // 主视图内容
            VStack(alignment: .leading, spacing: 8) {
                // 标题行
                Button(action: {
                    // 点击时切换设备列表显示状态
                    if isInput {
                        print("\u{001B}[36m[DEBUG]\u{001B}[0m 点击输入设备按钮")
                        showingInputDeviceList.toggle()
                        showingOutputDeviceList = false
                    } else {
                        print("\u{001B}[36m[DEBUG]\u{001B}[0m 点击输出设备按钮")
                        showingOutputDeviceList.toggle()
                        showingInputDeviceList = false
                    }
                }) {
                    HStack {
                        Image(systemName: isInput ? "mic.fill" : "headphones")
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                            .frame(width: 20)
                        
                        Text(isInput ? "AUDIO INPUT" : "AUDIO OUTPUT")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        // 箭头图标，根据展开状态旋转
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .rotationEffect(.degrees(isInput ? 
                                                   (showingInputDeviceList ? 90 : 0) : 
                                                   (showingOutputDeviceList ? 90 : 0)))
                            .padding(.trailing, 4)
                    }
                    .contentShape(Rectangle())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        ZStack {
                            VisualEffectView(material: .popover, blendingMode: .behindWindow)
                            Color.white.opacity(0.05)
                        }
                    )
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                
                // 设备名称行
                HStack {
                    Text(isInput ? 
                        (audioManager.selectedInputDevice?.name ?? "No Input Device") : 
                        (audioManager.selectedOutputDevice?.name ?? "No Output Device"))
                        .font(.system(size: 15))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
                
                // 音量滑块
                volumeSlider(isInput: isInput)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
            }
            .background(
                ZStack {
                    // 半透明背景效果
                    VisualEffectView(material: .popover, blendingMode: .behindWindow)
                    
                    // 细微的亮色渐变效果
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.95, green: 0.95, blue: 0.97).opacity(0.2),
                            Color(red: 0.9, green: 0.9, blue: 0.92).opacity(0.1)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .opacity(0.1)
                }
            )
            .cornerRadius(12)
            
            // 条件性地在底部显示设备列表
            if isInput ? showingInputDeviceList : showingOutputDeviceList {
                let devices = isInput ? audioManager.inputDevices : audioManager.outputDevices
                let selectedDevice = isInput ? audioManager.selectedInputDevice : audioManager.selectedOutputDevice
                
                VStack {
                    Spacer()
                        .frame(height: 120) // 设备信息块的高度，确保列表在设备块下方
                    
                    DeviceMenuList(
                        devices: devices,
                        selectedDeviceName: selectedDevice?.name ?? "",
                        onDeviceSelected: { device in
                            // 处理设备选择
                            print("\u{001B}[36m[DEBUG]\u{001B}[0m 设备已选择: \(device.name)")
                            audioManager.setDefaultDevice(device, forInput: isInput)
                            
                            // 关闭列表
                            if isInput {
                                showingInputDeviceList = false
                            } else {
                                showingOutputDeviceList = false
                            }
                        }
                    )
                    .frame(width: 350) // 增加宽度以匹配minWidth
                    .background(
                        ZStack {
                            VisualEffectView(material: .popover, blendingMode: .behindWindow)
                            Color.black.opacity(0.1)
                        }
                    )
                    .cornerRadius(8)
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                }
                .transition(.opacity)
                .zIndex(100) // 确保设备列表显示在最前面
            }
        }
    }
    
    // 音量滑块
    private func volumeSlider(isInput: Bool) -> some View {
        let volume = isInput ? 
            Binding(
                get: { audioManager.inputVolume },
                set: { 
                    if let device = audioManager.selectedInputDevice {
                        audioManager.setVolumeForDevice(device: device, volume: $0, isInput: true)
                    } 
                }
            ) :
            Binding(
                get: { audioManager.outputVolume },
                set: { 
                    if let device = audioManager.selectedOutputDevice {
                        audioManager.setVolumeForDevice(device: device, volume: $0, isInput: false)
                    }
                }
            )
        
        return HStack {
            Slider(value: volume, in: 0...1)
                .accentColor(Color(red: 0.3, green: 0.9, blue: 0.7))
                .frame(height: 16)
        }
    }
    
    private func openSettings() {
        // 关闭所有popover
        showingSettings = false
        showingDictationSettings = false
        showingOutputDeviceList = false
        showingInputDeviceList = false
        
        // 关闭主卡片
        if let popover = NSApp.windows.first(where: { $0.className.contains("NSPopover") }) {
            popover.close()
        }
        
        // 使用延迟确保主卡片已关闭
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // 打开设置窗口
            let settingsWindow = SettingsWindowController.createSettingsWindow()
            settingsWindow.showWindow(nil)
            settingsWindow.window?.orderFrontRegardless()
        }
    }
    
    private func openDictationSettings() {
        // 打开听写设置窗口（可能作为设置窗口的一部分）
        let settingsWindow = SettingsWindowController.createSettingsWindow()
        settingsWindow.showWindow(nil)
        settingsWindow.window?.orderFrontRegardless()
        
        // 切换到听写设置选项卡（如果有）
        NotificationCenter.default.post(name: NSNotification.Name("SwitchToSettingsTab"), object: "dictation")
    }
    
    // 底部按钮区，修改为使用统一样式，Quit在左侧，Settings在右侧
    private var bottomButtons: some View {
        HStack {
            // 左侧Quit按钮 - 只显示图标
            iconButton(
                icon: "power",
                action: {
                    NSApplication.shared.terminate(nil)
                }
            )
            
            Spacer() // 添加空间将两个按钮推到两侧
            
            // 右侧Settings按钮 - 只显示图标
            iconButton(
                icon: "gear",
                action: openSettings
            )
        }
        .padding(.top, 8)
    }
    
    // 添加一个只有图标的按钮样式函数
    private func iconButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .frame(width: 34, height: 34)
                .cornerRadius(6)
        }
        .buttonStyle(PlainButtonStyle())
        .help(icon == "power" ? "Quit" : "Settings") // 添加悬停提示
    }
    
    // 保留带文字的按钮样式函数，可能在其他地方被使用
    private func smallButton(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(title)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(.white)
            .frame(height: 34)
            .padding(.horizontal, 12)
            .cornerRadius(6)
        }
        .buttonStyle(PlainButtonStyle())
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
                    .foregroundColor(.white)
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
                    .foregroundColor(.white)
                
                Spacer()
                
                // 音频波形可视化
                HStack(spacing: 4) {
                    ForEach(0..<10, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(.white)
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
        .background(
            ZStack {
                VisualEffectView(material: .popover, blendingMode: .behindWindow)
                Color.white.opacity(0.05)
            }
        )
        .cornerRadius(6) // 使用更小的圆角
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
                    .foregroundColor(isSelected ? Color.white : .secondary)
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
                        .foregroundColor(.white)
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