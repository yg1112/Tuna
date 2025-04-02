import SwiftUI
import Views

// 导入DictationState
@_exported import struct Views.DictationView
@_exported import enum Views.DictationState

struct TunaDictationView: View {
    @ObservedObject private var dictationManager = DictationManager.shared
    @State private var isVisualizing = false
    @State private var isPlaceholderVisible = true
    @State private var editableText: String = "This is the live transcription..."
    @State private var showEditHint: Bool = false
    @State private var showCursor: Bool = false
    @State private var cursorTimer: Timer? = nil
    @State private var isFocused: Bool = false
    
    // 计算显示的文本 - 如果有转录内容则显示实际转录，否则显示占位符
    private var displayText: String {
        if !dictationManager.transcribedText.isEmpty {
            return dictationManager.transcribedText
        } else if isPlaceholderVisible {
            return "This is the live transcription..."
        } else {
            return ""
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 标题部分
            titleView
            
            // 状态信息
            statusView
            
            // 可视化音频
            if dictationManager.state == .recording {
                visualizerView
            }
            
            // 文字输出框
            transcriptionTextView
            
            // 控制按钮
            buttonRowView
        }
        .padding(.vertical, 12)
        .background(Color(red: 0.12, green: 0.15, blue: 0.16).opacity(0.6))
        .cornerRadius(12)
        .focusable(false) // 整个视图禁用焦点效果
        .onAppear {
            // 启动音频可视化效果定时器
            startVisualizing()
        }
        .onDisappear {
            // 停止音频可视化效果定时器
            stopVisualizing()
            stopCursorAnimation()
        }
    }
    
    // 标题部分
    private var titleView: some View {
        HStack {
            Image(systemName: "mic")
                .font(.system(size: 18))
                .foregroundColor(.white)
                .focusable(false)
            Text("DICTATION")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .focusable(false)
            
            Spacer()
            
            // 添加右侧箭头
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .focusable(false)
        }
        .padding(.horizontal, 12)
        .focusable(false)
    }
    
    // 状态信息
    private var statusView: some View {
        Text(statusText)
            .font(.system(size: 14))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 2)
            .focusable(false)
    }
    
    // 可视化效果
    private var visualizerView: some View {
        HStack {
            Spacer()
            audioVisualizerView
            Spacer()
        }
        .frame(height: 30)
        .padding(.vertical, 2)
        .focusable(false)
    }
    
    // 文本框
    private var transcriptionTextView: some View {
        ScrollView {
            ZStack(alignment: .leading) {
                // 背景和占位符
                if isPlaceholderVisible && editableText.isEmpty {
                    Text("This is the live transcription...")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 6)
                        .focusable(false)
                }
                
                // 文本编辑器
                TextEditor(text: $editableText)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .background(Color.clear)
                    .frame(height: 72)
                    .padding(2)
                    .overlay(
                        // 添加边框效果，在有文本时更明显
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.white.opacity(!dictationManager.transcribedText.isEmpty ? 0.3 : 0.1), 
                                    lineWidth: !dictationManager.transcribedText.isEmpty ? 1.5 : 1)
                            .animation(.easeInOut(duration: 0.3), value: dictationManager.transcribedText.isEmpty)
                    )
                    .opacity(isPlaceholderVisible && editableText == "This is the live transcription..." ? 0 : 1)
                    .onChange(of: dictationManager.transcribedText) { newText in
                        if !newText.isEmpty {
                            isPlaceholderVisible = false
                            // 始终更新可编辑文本，而不是仅在首次接收时更新
                            editableText = newText
                            
                            // 当获得新转录文本时，显示编辑提示和光标动画
                            showEditingHint()
                            startCursorAnimation()
                        }
                    }
                    .onHover { hovering in
                        // 当鼠标悬停在文本框上时显示光标
                        if hovering && !isFocused && !dictationManager.transcribedText.isEmpty {
                            startCursorAnimation()
                        } else if !hovering && !isFocused {
                            stopCursorAnimation()
                        }
                    }
                    .onTapGesture {
                        // 当用户点击文本框时，标记为聚焦状态
                        isFocused = true
                        // 停止光标动画（因为真实光标会显示）
                        stopCursorAnimation()
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .colorScheme(.dark)
                    .focusable(true)
                
                // 编辑提示指示器 - 仅当有转录文本且处于非录音状态时显示
                if !dictationManager.transcribedText.isEmpty && dictationManager.state != .recording {
                    HStack {
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("可编辑")
                                .font(.system(size: 10))
                                .foregroundColor(Color.white.opacity(0.6))
                                .padding(4)
                                .background(Color.black.opacity(0.4))
                                .cornerRadius(4)
                                .opacity(showEditHint ? 1 : 0)
                                .animation(.easeInOut(duration: 0.6).repeatCount(3), value: showEditHint)
                        }
                        .padding(4)
                    }
                }
                
                // 闪烁的光标
                if showCursor && !dictationManager.transcribedText.isEmpty && !isFocused {
                    HStack {
                        Text(editableText)
                            .font(.system(size: 14))
                            .foregroundColor(.clear)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 6)
                        
                        Rectangle()
                            .fill(Color.white.opacity(0.7))
                            .frame(width: 1.5, height: 14)
                            .opacity(showCursor ? 1 : 0)
                            .animation(Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: showCursor)
                            .offset(y: 2)
                    }
                    .padding(2)
                }
            }
        }
        .frame(height: 78)
        .background(Color.black.opacity(0.3))
        .cornerRadius(8)
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(!dictationManager.transcribedText.isEmpty ? 0.2 : 0.1), lineWidth: 1)
                .animation(.easeInOut(duration: 0.3), value: dictationManager.transcribedText.isEmpty)
        )
        .focusable(false)
    }
    
    // 按钮行
    private var buttonRowView: some View {
        HStack {
            // 使用GeometryReader获取可用宽度
            GeometryReader { geometry in
                HStack(spacing: 8) {
                    // 暂停/播放按钮
                    controlButton(
                        icon: playPauseIconName,
                        title: dictationManager.state == .recording ? "Pause" : "Start",
                        action: handlePlayPauseAction,
                        isDisabled: dictationManager.state == .processing,
                        width: geometry.size.width / 4 - 6
                    )
                    
                    // 停止按钮
                    controlButton(
                        icon: "stop.fill",
                        title: "Stop",
                        action: { dictationManager.stopRecording() },
                        isDisabled: dictationManager.state == .idle || dictationManager.state == .processing,
                        width: geometry.size.width / 4 - 6
                    )
                    
                    // 复制按钮
                    controlButton(
                        icon: "doc.on.doc",
                        title: "Copy",
                        action: copyToClipboard,
                        isDisabled: dictationManager.transcribedText.isEmpty,
                        width: geometry.size.width / 4 - 6
                    )
                    
                    // 保存按钮
                    controlButton(
                        icon: "arrow.down.doc.fill",
                        title: "Save",
                        action: saveTranscription,
                        isDisabled: dictationManager.transcribedText.isEmpty,
                        width: geometry.size.width / 4 - 6
                    )
                }
                .frame(width: geometry.size.width)
            }
            .frame(height: 38)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
    
    // 按钮组件
    private func controlButton(icon: String, title: String, action: @escaping () -> Void, isDisabled: Bool, width: CGFloat) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(title)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(.white)
            .frame(width: width, height: 34)
            .background(Color.black.opacity(0.7))
            .cornerRadius(6)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDisabled)
        .focusable(false)
    }
    
    // 复制到剪贴板
    private func copyToClipboard() {
        if isPlaceholderVisible && dictationManager.transcribedText.isEmpty {
            return
        }
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(editableText, forType: .string)
    }
    
    // 播放/暂停按钮动作
    private func handlePlayPauseAction() {
        switch dictationManager.state {
        case .idle:
            // 开始新录音时重置占位符状态
            isPlaceholderVisible = true
            editableText = "This is the live transcription..."
            dictationManager.startRecording()
        case .recording:
            dictationManager.pauseRecording()
        case .paused:
            // 继续录音时不重置文本框
            dictationManager.startRecording()
        case .processing:
            // 处理中不执行任何操作
            break
        }
    }
    
    // 播放/暂停按钮图标
    private var playPauseIconName: String {
        switch dictationManager.state {
        case .idle, .paused:
            return "play.fill"
        case .recording:
            return "pause.fill"
        case .processing:
            return "hourglass"
        }
    }
    
    // 状态文本
    private var statusText: String {
        if dictationManager.state == .recording {
            return "Listening..."
        } else if !dictationManager.progressMessage.isEmpty {
            return dictationManager.progressMessage
        } else if dictationManager.transcribedText.isEmpty && dictationManager.state == .idle {
            return "没有录音文件"
        }
        
        switch dictationManager.state {
        case .idle:
            return "Ready to record"
        case .recording:
            return "Listening..."
        case .paused:
            return "Paused"
        case .processing:
            return "Processing..."
        }
    }
    
    // 音频可视化效果
    private var audioVisualizerView: some View {
        HStack(alignment: .center, spacing: 2) {
            ForEach(0..<15, id: \.self) { index in
                AudioVisualizerBar(isRecording: dictationManager.state == .recording)
                    .focusable(false)
            }
        }
        .focusable(false)
    }
    
    // 启动/停止可视化效果
    private func startVisualizing() {
        isVisualizing = true
    }
    
    private func stopVisualizing() {
        isVisualizing = false
    }
    
    // 保存转录文本到用户设置的路径
    private func saveTranscription() {
        guard !dictationManager.transcribedText.isEmpty else { return }
        
        // 使用editableText而不是dictationManager.transcribedText，以便用户的编辑也会被保存
        let text = editableText
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .medium)
                .replacingOccurrences(of: "/", with: "-")
                .replacingOccurrences(of: ":", with: "-")
        
        // 获取用户设置的输出目录
        let outputDir = dictationManager.getDocumentsDirectory()
        let outputFormat = dictationManager.outputFormat
        let outputFileName = "dictation_\(timestamp).\(outputFormat)"
        let outputURL = outputDir.appendingPathComponent(outputFileName)
        
        do {
            // 根据输出格式生成不同格式的文件
            switch outputFormat {
            case "txt":
                try text.write(to: outputURL, atomically: true, encoding: .utf8)
            case "json":
                let json = """
                {
                    "text": "\(text.replacingOccurrences(of: "\"", with: "\\\""))",
                    "timestamp": "\(timestamp)",
                    "duration": 0
                }
                """
                try json.write(to: outputURL, atomically: true, encoding: .utf8)
            default:
                try text.write(to: outputURL, atomically: true, encoding: .utf8)
            }
            
            // 更新状态消息和剪贴板
            dictationManager.progressMessage = "已保存到: \(outputURL.lastPathComponent)"
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(outputURL.path, forType: .string)
            print("保存成功: \(outputURL.path)")
        } catch {
            dictationManager.progressMessage = "保存失败: \(error.localizedDescription)"
            print("保存失败: \(error.localizedDescription)")
        }
    }
    
    // 在获得转录结果后显示编辑提示
    private func showEditingHint() {
        // 设置短暂延迟，让用户先看到结果
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showEditHint = true
            
            // 3秒后隐藏提示
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                showEditHint = false
            }
        }
    }
    
    // 启动光标动画
    private func startCursorAnimation() {
        // 确保先停止现有动画
        stopCursorAnimation()
        
        // 只在有文本时才显示光标
        if dictationManager.transcribedText.isEmpty {
            return
        }
        
        // 显示光标
        showCursor = true
        
        // 5秒后自动隐藏光标
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            if !isFocused {
                stopCursorAnimation()
            }
        }
    }
    
    // 停止光标动画
    private func stopCursorAnimation() {
        showCursor = false
    }
}

// 音频可视化条 - 使用mint绿色
struct AudioVisualizerBar: View {
    let isRecording: Bool
    @State private var height: CGFloat = 5
    
    // 定时器状态
    @State private var timer: Timer?
    
    var body: some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(Color(red: 0.3, green: 0.9, blue: 0.7))
            .frame(width: 2, height: height)
            .onAppear {
                startAnimation()
            }
            .onDisappear {
                stopAnimation()
            }
    }
    
    private func startAnimation() {
        // 停止现有的计时器
        stopAnimation()
        
        // 根据录制状态设置高度
        if !isRecording {
            height = 5
            return
        }
        
        // 为录制状态创建动画
        timer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { _ in
            withAnimation(.linear(duration: 0.1)) {
                height = CGFloat.random(in: 2...24)
            }
        }
        
        // 立即触发一次
        withAnimation(.linear(duration: 0.1)) {
            height = CGFloat.random(in: 2...24)
        }
    }
    
    private func stopAnimation() {
        timer?.invalidate()
        timer = nil
        
        withAnimation {
            height = 5
        }
    }
} 