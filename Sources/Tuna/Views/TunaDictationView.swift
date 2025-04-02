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
    @State private var blinkState: Bool = false // 控制光标闪烁状态
    @State private var cursorTimer: Timer? = nil
    @State private var isFocused: Bool = false {
        didSet {
            // 当焦点状态变化时，强制更新UI
            if isFocused {
                // 当获得焦点时，确保停止自定义光标
                stopCursorAnimation()
            } else {
                // 当失去焦点时，恢复自定义光标
                startCursorAnimation()
            }
        }
    }
    
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
        .onAppear {
            // 启动音频可视化效果定时器
            startVisualizing()
            // 直接在这里也启动光标动画，确保视图出现时就显示
            startCursorAnimation()
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
            Text("DICTATION")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
            
            Spacer()
            
            // 添加右侧箭头
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 12)
    }
    
    // 状态信息
    private var statusView: some View {
        Text(statusText)
            .font(.system(size: 14))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 2)
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
    }
    
    // 文本框
    private var transcriptionTextView: some View {
        TranscriptionTextBoxView(
            editableText: $editableText,
            isPlaceholderVisible: isPlaceholderVisible,
            isFocused: $isFocused,
            blinkState: blinkState,
            dictationManager: dictationManager,
            onTextFieldFocus: {
                isFocused = true
                print("Text field focused")
            },
            onTranscriptionTextChange: { newText in
                if !newText.isEmpty {
                    isPlaceholderVisible = false
                    editableText = newText
                    if !isFocused {
                        startCursorAnimation()
                    }
                }
            }
        )
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
        .onAppear {
            // 启动光标闪烁动画
            startCursorAnimation()
            print("Transcription text view appeared")
        }
        .onDisappear {
            stopCursorAnimation()
        }
    }
    
    // 创建独立的转录文本框视图组件
    struct TranscriptionTextBoxView: View {
        @Binding var editableText: String
        let isPlaceholderVisible: Bool
        @Binding var isFocused: Bool
        let blinkState: Bool
        let dictationManager: DictationManager
        let onTextFieldFocus: () -> Void
        let onTranscriptionTextChange: (String) -> Void
        
        var body: some View {
            ZStack(alignment: .topLeading) {
                // 背景和占位符
                if isPlaceholderVisible && editableText.isEmpty {
                    Text("This is the live transcription...")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 6)
                }
                
                // 文本编辑器 - 不要包含在ScrollView中，TextEditor已有滚动功能
                TextEditor(text: $editableText)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .background(Color.clear)
                    .frame(minHeight: 72, maxHeight: .infinity)
                    .padding(4)
                    .opacity(isPlaceholderVisible && editableText == "This is the live transcription..." ? 0 : 1)
                    .onChange(of: dictationManager.transcribedText) { newText in
                        onTranscriptionTextChange(newText)
                    }
                    .onTapGesture {
                        // 当用户点击文本框时，标记为聚焦状态
                        onTextFieldFocus()
                    }
                    // 添加选择文本高亮颜色 - 使用更明显的颜色
                    .accentColor(Color(red: 0.0, green: 0.9, blue: 0.7).opacity(0.7)) // 更明显的mint绿色作为选择高亮色
                    .colorScheme(.dark) // 使用深色模式以确保文本选择高亮可见
                
                // 使用条件渲染来简化光标逻辑
                CursorView(
                    editableText: editableText,
                    isPlaceholderVisible: isPlaceholderVisible,
                    isFocused: isFocused,
                    blinkState: blinkState
                )
            }
        }
    }
    
    // 提取光标视图为单独的组件
    struct CursorView: View {
        let editableText: String
        let isPlaceholderVisible: Bool
        let isFocused: Bool
        let blinkState: Bool
        
        var body: some View {
            Group {
                // 只在未聚焦且有文本时显示一个跟随光标
                if !isFocused && !editableText.isEmpty && editableText != "This is the live transcription..." {
                    // 显示跟随文本末尾的光标
                    FollowingCursorView(text: editableText, isBlinking: blinkState)
                        .padding(6)
                        .id("following-cursor") // 添加ID确保视图刷新
                }
                // 只在未聚焦且无文本或仅有占位符时显示起始光标
                else if !isFocused && (isPlaceholderVisible || editableText.isEmpty) {
                    // 使用绿色光标，与应用的其他部分一致
                    Rectangle()
                        .fill(Color(red: 0.3, green: 0.9, blue: 0.7)) // 使用相同的mint绿色
                        .frame(width: 2, height: 18)
                        .opacity(blinkState ? 1.0 : 0.0) // 根据闪烁状态切换不透明度
                        .padding(.leading, 6)
                        .padding(.top, 6)
                        .id("start-cursor") // 添加ID确保视图刷新
                }
            }
        }
    }
    
    // 跟随文本末尾的光标视图
    private struct FollowingCursorView: View {
        let text: String
        let isBlinking: Bool
        
        var body: some View {
            ZStack(alignment: .topLeading) {
                // 使用透明的Text来计算文本位置
                Text(text)
                    .font(.system(size: 14))
                    .foregroundColor(.clear)
                    .layoutPriority(1)
                    .background(GeometryReader { geometry in
                        // 在文本末尾放置闪烁光标
                        Rectangle()
                            .fill(Color(red: 0.3, green: 0.9, blue: 0.7)) // 使用相同的mint绿色
                            .frame(width: 2, height: 18)
                            .opacity(isBlinking ? 1.0 : 0.0) // 根据闪烁状态切换不透明度
                            .position(x: min(geometry.size.width, max(2, geometry.size.width)), 
                                     y: geometry.size.height - 12)
                            .animation(.easeInOut(duration: 0.2), value: isBlinking)
                    })
            }
        }
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
            return "No recording files"
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
            }
        }
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
            dictationManager.progressMessage = "Saved to: \(outputURL.lastPathComponent)"
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(outputURL.path, forType: .string)
            print("Saved successfully: \(outputURL.path)")
        } catch {
            dictationManager.progressMessage = "Save failed: \(error.localizedDescription)"
            print("Save failed: \(error.localizedDescription)")
        }
    }
    
    // 在获得转录结果后显示编辑提示
    private func showEditingHint() {
        // 由于不再需要显示编辑提示，此函数可以为空或完全移除
    }
    
    // 启动光标动画
    private func startCursorAnimation() {
        // 确保先停止现有动画
        stopCursorAnimation()
        
        // 创建真正的闪烁计时器，每0.6秒切换一次状态
        cursorTimer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { _ in
            // 使用MainActor确保在主线程更新UI
            Task { @MainActor in
                withAnimation(.easeInOut(duration: 0.2)) {
                    self.blinkState.toggle() // 切换闪烁状态
                }
            }
        }
        
        // 立即开始第一个闪烁周期
        blinkState = true
        
        // 确保计时器被添加到RunLoop
        RunLoop.current.add(cursorTimer!, forMode: .common)
        
        print("Cursor animation started with timer")
    }
    
    // 停止光标动画
    private func stopCursorAnimation() {
        cursorTimer?.invalidate()
        cursorTimer = nil
        blinkState = false
        print("Cursor animation stopped")
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