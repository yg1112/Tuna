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
    @State private var isFocused: Bool = false
    @State private var cursorPosition: Int = 0 // 追踪光标位置
    
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
        }
        .onDisappear {
            // 停止音频可视化效果定时器
            stopVisualizing()
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
            isPlaceholderVisible: $isPlaceholderVisible,
            isFocused: $isFocused,
            cursorPosition: $cursorPosition, // 传递光标位置
            dictationManager: dictationManager,
            onTextFieldFocus: {
                isFocused = true
                print("\u{001B}[36m[DEBUG]\u{001B}[0m Text field focused")
            },
            onTranscriptionTextChange: { newText in
                if !newText.isEmpty {
                    isPlaceholderVisible = false
                    editableText = newText
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
    }
    
    // 创建独立的转录文本框视图组件
    struct TranscriptionTextBoxView: View {
        @Binding var editableText: String
        @Binding var isPlaceholderVisible: Bool
        @Binding var isFocused: Bool
        @Binding var cursorPosition: Int
        let dictationManager: DictationManager
        let onTextFieldFocus: () -> Void
        let onTranscriptionTextChange: (String) -> Void
        
        // 添加一个状态变量来跟踪上一次的转录文本
        @State private var lastTranscribedText: String = ""
        
        // NSTextView代理声明，但不实现复杂功能，只用来准备代码结构
        class TextViewCoordinator: NSObject {
            var parent: TranscriptionTextBoxView
            
            init(_ parent: TranscriptionTextBoxView) {
                self.parent = parent
            }
        }
        
        var body: some View {
            ZStack(alignment: .topLeading) {
                // 背景
                Rectangle()
                    .fill(Color.clear)
                    .frame(minHeight: 72)
                
                // 占位符文本 - 只在需要时显示
                if isPlaceholderVisible && editableText.isEmpty {
                    Text("This is the live transcription...")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 6)
                        .allowsHitTesting(false) // 允许点击穿透到下面的TextEditor
                }
                
                // 文本编辑器
                TextEditor(text: $editableText)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .modifier(TextEditorBackgroundModifier())
                    .background(Color.clear)
                    .frame(minHeight: 72, maxHeight: .infinity)
                    .padding([.horizontal, .top], 6)
                    .padding(.bottom, 2)
                    .opacity(isPlaceholderVisible && editableText == "This is the live transcription..." ? 0 : 1)
                    .onChange(of: dictationManager.transcribedText) { newText in
                        // 当dictationManager的转录文本更新时，插入到光标位置
                        insertTextAtCursor(newText)
                    }
                    .onChange(of: editableText) { newEditedText in
                        if !isFocused { return } // 仅在用户焦点时同步，避免循环更新
                        
                        // 如果是占位符文本，不进行同步
                        if newEditedText == "This is the live transcription..." { return }
                        
                        // 当用户手动编辑时，同步到dictationManager，并估计光标位置
                        if !isPlaceholderVisible {
                            print("\u{001B}[36m[DEBUG]\u{001B}[0m 用户编辑了文本，同步到dictationManager")
                            dictationManager.transcribedText = newEditedText
                            // 更新上次转录文本，避免重复插入
                            lastTranscribedText = newEditedText
                            
                            // 尝试使用NSTextView API获取光标位置的简单方法
                            if let firstResponder = NSApp.keyWindow?.firstResponder as? NSTextView {
                                if let range = firstResponder.selectedRanges.first as? NSRange {
                                    cursorPosition = range.location
                                    print("\u{001B}[36m[DEBUG]\u{001B}[0m 光标位置更新为: \(cursorPosition)")
                                }
                            }
                        }
                    }
                    .onTapGesture {
                        onTextFieldFocus()
                    }
                    .contextMenu {
                        Button("Copy") {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(editableText, forType: .string)
                        }
                        
                        Button("Cut") {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(editableText, forType: .string)
                            editableText = ""
                        }
                        
                        Button("Paste") {
                            if let clipboardContent = NSPasteboard.general.string(forType: .string) {
                                editableText = clipboardContent
                                isPlaceholderVisible = false
                            }
                        }
                        
                        Button("Select All") {
                            onTextFieldFocus()
                        }
                    }
                    .accentColor(Color(red: 0.3, green: 0.9, blue: 0.7))
                    .colorScheme(.dark)
            }
            .onAppear {
                // 初始化上次转录文本
                lastTranscribedText = dictationManager.transcribedText
            }
        }
        
        // 在光标位置插入新文本
        private func insertTextAtCursor(_ newText: String) {
            // 如果当前是空文本或占位符，直接替换
            if editableText.isEmpty || editableText == "This is the live transcription..." {
                editableText = newText
                isPlaceholderVisible = false
                lastTranscribedText = newText // 更新上次文本
                onTranscriptionTextChange(newText)
                return
            }
            
            // 确保转录文本确实有变化
            if newText.isEmpty || newText == lastTranscribedText {
                return
            }
            
            print("\u{001B}[36m[DEBUG]\u{001B}[0m 准备在光标位置(\(cursorPosition))插入新文本")
            
            // 检查光标位置是否有效
            let cursorPos = min(cursorPosition, editableText.count)
            
            // 找出新增的文本部分
            let actualNewContent = findNewContent(from: lastTranscribedText, to: newText)
            
            if !actualNewContent.isEmpty {
                print("\u{001B}[36m[DEBUG]\u{001B}[0m 检测到新增文本: \(actualNewContent)")
                
                // 开始部分和结束部分
                let startIndex = editableText.startIndex
                let cursorIndex = editableText.index(startIndex, offsetBy: cursorPos)
                
                let textBeforeCursor = String(editableText[startIndex..<cursorIndex])
                let textAfterCursor = String(editableText[cursorIndex...])
                
                // 更新文本 - 只在光标位置插入新增文本
                let updatedText = textBeforeCursor + actualNewContent + textAfterCursor
                
                // 更新UI
                editableText = updatedText
                isPlaceholderVisible = false
                
                // 更新上次转录文本
                lastTranscribedText = newText
                
                // 更新光标位置 - 移动到插入内容之后
                cursorPosition = cursorPos + actualNewContent.count
                print("\u{001B}[36m[DEBUG]\u{001B}[0m 更新后的光标位置: \(cursorPosition)")
                
                // 通知变更
                onTranscriptionTextChange(updatedText)
            } else {
                // 如果没有检测到新增内容，则更新上次文本以防止差异检测错误
                lastTranscribedText = newText
            }
        }
        
        // 查找新增的文本部分
        private func findNewContent(from oldText: String, to newText: String) -> String {
            // 如果新文本比旧文本短，可能是因为用户删除了部分内容，这时应该只考虑新增的部分
            if newText.count < oldText.count {
                // 用户可能删除了部分内容，转录又添加了新内容
                // 尝试识别新增的部分
                
                // 首先查看新文本是否包含于旧文本
                if oldText.contains(newText) {
                    // 如果新文本完全是旧文本的子集，说明没有新增内容
                    return ""
                } else {
                    // 新文本不是旧文本的子集，可能有新内容
                    // 查找最长公共前缀
                    let commonPrefix = newText.commonPrefix(with: oldText)
                    
                    // 如果有公共前缀，则新文本剩余部分可能是新增内容
                    if commonPrefix.count < newText.count {
                        let newContentStart = newText.index(newText.startIndex, offsetBy: commonPrefix.count)
                        return String(newText[newContentStart...])
                    } else {
                        // 无法确定新增内容，谨慎起见返回空
                        return ""
                    }
                }
            } else {
                // 新文本更长，查找新增部分
                // 找到公共前缀
                let commonPrefix = oldText.commonPrefix(with: newText)
                
                // 除去公共前缀，剩余部分就是新增内容
                if commonPrefix.count < newText.count {
                    let newContentStart = newText.index(newText.startIndex, offsetBy: commonPrefix.count)
                    return String(newText[newContentStart...])
                } else {
                    // 可能是完全替换或其他情况
                    return ""
                }
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
                        title: "Export",
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
            // 开始新录音时重置占位符状态，但保留用户可能编辑过的文本
            if editableText == "This is the live transcription..." || editableText.isEmpty {
                isPlaceholderVisible = true
                editableText = "This is the live transcription..."
            } else {
                // 如果用户已经有文本，保留它
                isPlaceholderVisible = false
                // 确保dictationManager使用当前编辑框中的文本
                dictationManager.transcribedText = editableText
            }
            dictationManager.startRecording()
        case .recording:
            dictationManager.pauseRecording()
        case .paused:
            // 继续录音时使用当前编辑框中的文本，确保不恢复被删除的内容
            print("\u{001B}[36m[DEBUG]\u{001B}[0m 从暂停恢复录音，使用当前编辑文本: \(editableText)")
            // 明确将当前用户编辑的文本设置为转录文本，覆盖任何可能的旧内容
            dictationManager.transcribedText = editableText
            // 确保占位符状态正确
            isPlaceholderVisible = editableText.isEmpty || editableText == "This is the live transcription..."
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

// 添加兼容性修饰符
struct TextEditorBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 13.0, *) {
            content.scrollContentBackground(.hidden)
        } else {
            content
        }
    }
} 