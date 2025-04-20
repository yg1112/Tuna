import SwiftUI

// import Views -- 已移至 Tuna 模块

// 直接使用 DictationState，不再通过模块导入
// @_exported import struct Tuna.DictationView
// @_exported import enum Tuna.DictationState

// 扩展String添加条件前缀功能 - 文件级别扩展
extension String {
    func addPrefixIfNeeded(_ prefix: String) -> String {
        if isEmpty { return self }
        if hasPrefix(prefix) { return self }
        return prefix + self
    }
}

// 添加QuickDictationView - 专门用于快捷键激活的简化界面
struct QuickDictationView: View {
    @ObservedObject private var dictationManager: DictationManager
    @State private var isVisualizing = false
    @State private var isPlaceholderVisible = true
    @State private var editableText: String = ""
    @State private var isBreathingAnimation = false
    @State private var cursorPosition: Int = 0 // 追踪光标位置
    @State private var isFocused: Bool = false
    @State private var lastTranscribedText: String = "" // 跟踪上一次转录文本

    // 添加用于在测试中禁用动画的标志
    private let animationsDisabled: Bool

    // 默认初始化器 - 用于实际产品
    init() {
        self.dictationManager = DictationManager.shared
        self.animationsDisabled = false
    }

    // 测试初始化器 - 允许注入测试依赖
    init(dictationManager: DictationManager, animationsDisabled: Bool = false) {
        self.dictationManager = dictationManager
        self.animationsDisabled = animationsDisabled
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 标题部分 - 简化版
            HStack {
                Text("语音转文字")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.primary)

                Spacer()

                // 录音状态指示
                if self.dictationManager.state == .recording {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)

                        Text("Recording")
                            .font(.system(size: 13))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(8)
                } else if self.dictationManager.state == .processing {
                    Text("Processing...")
                        .font(.system(size: 13))
                        .foregroundColor(.yellow)
                }
            }
            .padding(.horizontal, 12)

            // 转录文本区域
            ZStack(alignment: .topTrailing) {
                // 占位符文本 - 只在需要时显示
                if self.isPlaceholderVisible, self.editableText.isEmpty,
                   self.dictationManager.transcribedText
                       .isEmpty
                {
                    Text("Transcription will appear here...")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .allowsHitTesting(false) // 允许点击穿透到下面的TextEditor
                }

                // 使用TextEditor允许编辑
                TextEditor(text: self.$editableText)
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
                    .frame(height: 120)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.textBackgroundColor).opacity(0.1))
                    )
                    .onChange(of: self.dictationManager.transcribedText) { newText in
                        // 当转录文本更新时，确保正确地添加到编辑框
                        self.updateEditableText(newText)
                    }
                    .onChange(of: self.editableText) { newText in
                        // 当用户手动编辑文本时，同步回dictationManager
                        if !newText.isEmpty,
                           self.editableText != self.dictationManager.transcribedText
                        {
                            self.dictationManager.transcribedText = newText
                        }
                    }
                    .onAppear {
                        // 初始化编辑文本
                        if !self.dictationManager.transcribedText.isEmpty {
                            self.editableText = self.dictationManager.transcribedText
                            self.isPlaceholderVisible = false
                        }
                    }
                    .contextMenu {
                        Button("Copy") {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(self.editableText, forType: .string)
                        }
                        .disabled(self.editableText.isEmpty)

                        Button("Cut") {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(self.editableText, forType: .string)
                            self.editableText = ""
                            self.dictationManager.transcribedText = ""
                            self.isPlaceholderVisible = true
                        }
                        .disabled(self.editableText.isEmpty)

                        Button("Paste") {
                            if let clipboardContent = NSPasteboard.general
                                .string(forType: .string)
                            {
                                self.editableText = clipboardContent
                                self.dictationManager.transcribedText = clipboardContent
                                self.isPlaceholderVisible = false
                            }
                        }

                        Divider()

                        // 新增语音转写相关功能
                        Button(
                            self.dictationManager
                                .state == .recording ? "Stop Recording" : "Start Recording"
                        ) {
                            if self.dictationManager.state == .recording {
                                self.dictationManager.stopRecording()
                            } else {
                                self.dictationManager.startRecording()
                            }
                        }

                        Button("Clear Text") {
                            self.editableText = ""
                            self.dictationManager.transcribedText = ""
                            self.isPlaceholderVisible = true
                        }
                        .disabled(self.editableText.isEmpty)

                        Divider()

                        // 格式优化选项
                        Button("大写首字母") {
                            if !self.editableText.isEmpty {
                                let firstChar = self.editableText.prefix(1).uppercased()
                                let restOfText = self.editableText.dropFirst()
                                self.editableText = firstChar + restOfText
                                self.dictationManager.transcribedText = self.editableText
                            }
                        }
                        .disabled(self.editableText.isEmpty)

                        Button("按句子优化格式") {
                            if !self.editableText.isEmpty {
                                // 分割句子
                                let sentences = self.editableText.components(separatedBy: ". ")
                                let formattedSentences = sentences.map { sentence -> String in
                                    if sentence.isEmpty { return sentence }
                                    let firstChar = sentence.prefix(1).uppercased()
                                    let restOfSentence = sentence.dropFirst()
                                    return firstChar + restOfSentence
                                }

                                // 重新组合句子
                                self.editableText = formattedSentences.joined(separator: ". ")
                                self.dictationManager.transcribedText = self.editableText
                            }
                        }
                        .disabled(self.editableText.isEmpty)
                    }

                // 清除按钮 - 仅在有内容时显示
                if !self.editableText.isEmpty {
                    Button(action: {
                        self.editableText = ""
                        self.dictationManager.transcribedText = ""
                        self.isPlaceholderVisible = true
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.system(size: 16))
                            .padding(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("清除文本")
                }
            }
            .padding(.horizontal, 12)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        self.dictationManager.state == .recording ?
                            Color.red.opacity(0.7) :
                            Color.gray.opacity(0.3),
                        lineWidth: self.dictationManager.state == .recording ? 1.5 : 0.5
                    )
                    .padding(.horizontal, 12)
            )

            // 编辑提示标签
            HStack {
                Spacer()
                Text("点击文本可以编辑")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .padding(.trailing, 16)
                    .padding(.top, 2)
            }
            .padding(.bottom, 4)

            // 可视化效果 - 仅在录音时显示
            if self.dictationManager.state == .recording {
                HStack(spacing: 2) {
                    ForEach(0 ..< 15, id: \.self) { index in
                        AudioVisualBar(
                            isRecording: true,
                            disableAnimations: self.animationsDisabled,
                            fixedTestHeight: self
                                .animationsDisabled ? 5 + CGFloat(index % 5) * 4 : nil
                        )
                    }
                }
                .frame(height: 20)
                .padding(.horizontal, 12)
            }

            // 控制按钮区
            HStack(spacing: 12) {
                // 录制/暂停按钮
                Button(action: {
                    switch self.dictationManager.state {
                        case .idle:
                            self.dictationManager.startRecording()
                        case .recording:
                            self.dictationManager.pauseRecording()
                        case .paused:
                            self.dictationManager.startRecording()
                        default:
                            break
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(
                            systemName: self.dictationManager.state == .recording ?
                                "pause.circle.fill" :
                                (
                                    self.dictationManager
                                        .state == .paused ? "play.circle.fill" : "mic.circle.fill"
                                )
                        )
                        .font(.system(size: 16))

                        Text(
                            self.dictationManager.state == .recording ?
                                "Pause" :
                                (self.dictationManager.state == .paused ? "Resume" : "Record")
                        )
                        .font(.system(size: 13))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        self.dictationManager.state == .recording ?
                            Color.red.opacity(0.7) :
                            (
                                self.dictationManager.state == .paused ? Color.orange
                                    .opacity(0.7) : Color.blue
                                    .opacity(0.7)
                            )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(self.dictationManager.state == .processing)

                // 停止按钮 - 仅在录音或暂停状态显示
                if self.dictationManager.state == .recording || self.dictationManager
                    .state == .paused
                {
                    Button(action: {
                        self.dictationManager.stopRecording()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "stop.circle.fill")
                                .font(.system(size: 16))

                            Text("Stop")
                                .font(.system(size: 13))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .disabled(self.dictationManager.state == .processing)
                }

                Spacer()

                // 复制按钮
                Button(action: {
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(self.dictationManager.transcribedText, forType: .string)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 16))
                        Text("Copy")
                            .font(.system(size: 13))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(self.dictationManager.transcribedText.isEmpty)

                // 保存按钮
                Button(action: {
                    self.saveTranscription()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 16))
                        Text("Save")
                            .font(.system(size: 13))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(self.dictationManager.transcribedText.isEmpty)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
        }
        .padding(.vertical, 8)
        .frame(width: 400)
        .background(VisualEffectView(material: .hudWindow, blendingMode: .behindWindow))
        .cornerRadius(12)
        .onAppear {
            // 启动音频可视化效果
            self.startVisualizing()
        }
        .onDisappear {
            // 停止音频可视化效果
            self.stopVisualizing()
        }
    }

    // 更新可编辑文本的函数
    private func updateEditableText(_ newText: String) {
        // 如果新转录文本为空，不做任何处理
        if newText.isEmpty { return }

        // 如果当前编辑文本为空或是占位符，直接使用新转录文本
        if self.editableText.isEmpty || self.isPlaceholderVisible {
            self.editableText = newText
            self.isPlaceholderVisible = false
            self.lastTranscribedText = newText
            return
        }

        // 检测新增内容并在合适位置插入
        if newText.count > self.lastTranscribedText.count,
           newText.hasPrefix(self.lastTranscribedText)
        {
            // 新文本是在旧文本基础上添加的
            let newContentStartIndex = newText.index(
                newText.startIndex,
                offsetBy: self.lastTranscribedText.count
            )
            let newContent = String(newText[newContentStartIndex...])

            // 将新内容追加到当前编辑文本
            self.editableText += newContent
            self.lastTranscribedText = newText
        } else if newText != self.lastTranscribedText {
            // 如果不是简单的追加，可能是完全新的文本或部分更新
            // 在这种情况下，可以选择保留用户编辑的内容，也可以选择使用新的转录文本
            // 这里我们选择保留用户编辑的内容，只在确认用户没有编辑时才更新
            if self.editableText == self.lastTranscribedText {
                self.editableText = newText
            }
            self.lastTranscribedText = newText
        }
    }

    // 保存转录到文件
    private func saveTranscription() {
        // 创建保存面板
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.text]
        savePanel.canCreateDirectories = true
        savePanel.isExtensionHidden = false
        savePanel.title = "Save Transcription"
        savePanel.message = "Choose a location to save the transcription"
        savePanel
            .nameFieldStringValue =
            "Transcription-\(Date().formatted(.dateTime.year().month().day().hour().minute()))"

        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                do {
                    try self.dictationManager.transcribedText.write(
                        to: url,
                        atomically: true,
                        encoding: .utf8
                    )

                    // 显示成功消息
                    self.dictationManager.progressMessage = "Saved to \(url.lastPathComponent)"
                } catch {
                    // 显示错误消息
                    self.dictationManager
                        .progressMessage = "Failed to save: \(error.localizedDescription)"
                }
            }
        }
    }

    // 启动/停止可视化效果
    private func startVisualizing() {
        self.isVisualizing = true
    }

    private func stopVisualizing() {
        self.isVisualizing = false
    }
}

// 语音转写视图
struct TunaDictationView: View {
    @ObservedObject private var dictationManager = DictationManager.shared
    @State private var isVisualizing = false
    @State private var isPlaceholderVisible = true
    @State private var editableText: String = ""
    @State private var showEditHint: Bool = false
    @State private var isFocused: Bool = false
    @State private var cursorPosition: Int = 0 // 追踪光标位置
    @State private var isBreathingAnimation = false
    @State private var showSavePanel = false

    // 添加动画禁用标志，用于测试
    private let animationsDisabled: Bool

    // 默认初始化器
    init() {
        self.animationsDisabled = false
    }

    // 测试初始化器
    init(animationsDisabled: Bool = false) {
        self.animationsDisabled = animationsDisabled
    }

    // 计算显示的文本 - 如果有转录内容则显示实际转录，否则显示占位符
    private var displayText: String {
        if !self.dictationManager.transcribedText.isEmpty {
            self.dictationManager.transcribedText
        } else if self.isPlaceholderVisible {
            "This is the live transcription..."
        } else {
            ""
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 标题部分
            self.titleView

            // 状态信息
            self.statusView

            // 可视化音频
            if self.dictationManager.state == .recording {
                self.visualizerView
            }

            // 文字输出框
            self.transcriptionTextView

            // 控制按钮
            self.buttonRowView
        }
        .padding(.vertical, 12)
        .background(
            ZStack {
                // 使用毛玻璃效果作为背景
                VisualEffectView(material: .popover, blendingMode: .behindWindow)

                // 添加浅色渐变叠加层
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.95, green: 0.95, blue: 0.97).opacity(0.2),
                        Color(red: 0.9, green: 0.9, blue: 0.92).opacity(0.1),
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .opacity(0.1)
            }
        )
        .cornerRadius(12)
        .onAppear {
            // 启动音频可视化效果定时器
            self.startVisualizing()
            // 启动呼吸动画
            self.isBreathingAnimation = true
        }
        .onDisappear {
            // 停止音频可视化效果定时器
            self.stopVisualizing()
        }
    }

    // 标题部分
    private var titleView: some View {
        HStack {
            Image(systemName: "bubble.and.pencil")
                .font(.system(size: 18))
                .foregroundColor(.primary)
            Text("DICTATION")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)

            Spacer()

            // 移除右侧箭头
        }
        .padding(.horizontal, 12)
    }

    // 状态信息
    private var statusView: some View {
        Text(self.statusText)
            .font(.system(size: 14))
            .foregroundColor(.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 2)
    }

    // 可视化效果
    private var visualizerView: some View {
        HStack {
            Spacer()
            self.audioVisualizerView
            Spacer()
        }
        .frame(height: 30)
        .padding(.vertical, 2)
    }

    // 文本框
    private var transcriptionTextView: some View {
        VStack(spacing: 2) {
            TranscriptionTextBoxView(
                editableText: self.$editableText,
                isPlaceholderVisible: self.$isPlaceholderVisible,
                isFocused: self.$isFocused,
                cursorPosition: self.$cursorPosition, // 传递光标位置
                dictationManager: self.dictationManager,
                onTextFieldFocus: {
                    self.isFocused = true
                    print("\u{001B}[36m[DEBUG]\u{001B}[0m Text field focused")
                },
                onTranscriptionTextChange: { newText in
                    if !newText.isEmpty {
                        self.isPlaceholderVisible = false
                        self.editableText = newText
                    }
                }
            )
            .frame(height: 78)
            .background(
                ZStack {
                    // 使用轻微的半透明背景
                    VisualEffectView(material: .popover, blendingMode: .behindWindow)

                    // 添加细微渐变增强深度感
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.9, green: 0.9, blue: 0.93).opacity(0.1),
                            Color(red: 0.85, green: 0.85, blue: 0.88).opacity(0.05),
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .opacity(0.1)
                }
            )
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        self.dictationManager.state == .recording ?
                            Color.white.opacity(0.8) : // 录音时显示常亮的珍珠白色边框
                            Color.white.opacity(self.isBreathingAnimation ? 0.2 : 0.05),
                        // 非录音时使用呼吸动画
                        lineWidth: self.dictationManager
                            .state == .recording ? 1.5 : (self.isBreathingAnimation ? 1.2 : 0.8)
                    )
                    .scaleEffect(
                        self.dictationManager
                            .state == .recording ? 1.0 : (self.isBreathingAnimation ? 1.01 : 1.0)
                    )
            )
            .animation(
                self.dictationManager.state == .recording ? nil :
                    Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                value: self.isBreathingAnimation
            )

            // 编辑提示标签
            HStack {
                Spacer()
                Text("点击文本可以编辑")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .padding(.trailing, 4)
                    .padding(.top, 2)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
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
                if self.isPlaceholderVisible, self.editableText.isEmpty {
                    Text("This is the live transcription...")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 6)
                        .allowsHitTesting(false) // 允许点击穿透到下面的TextEditor
                }

                // 文本编辑器
                TextEditor(text: self.$editableText)
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
                    .modifier(TextEditorBackgroundModifier())
                    .modifier(HideScrollbarModifier()) // 添加滚动条隐藏修饰符
                    .background(Color.clear)
                    .frame(minHeight: 72, maxHeight: .infinity)
                    .padding([.horizontal, .top], 6)
                    .padding(.bottom, 2)
                    .opacity(
                        self.isPlaceholderVisible && self.editableText ==
                            "This is the live transcription..." ? 0 : 1
                    )
                    .onChange(of: self.dictationManager.transcribedText) { newText in
                        // 当dictationManager的转录文本更新时，插入到光标位置
                        self.insertTextAtCursor(newText)
                    }
                    .onChange(of: self.editableText) { newEditedText in
                        if !self.isFocused { return } // 仅在用户焦点时同步，避免循环更新

                        // 如果是占位符文本，不进行同步
                        if newEditedText == "This is the live transcription..." { return }

                        // 当用户手动编辑时，同步到dictationManager，并估计光标位置
                        if !self.isPlaceholderVisible {
                            print("\u{001B}[36m[DEBUG]\u{001B}[0m 用户编辑了文本，同步到dictationManager")
                            self.dictationManager.transcribedText = newEditedText
                            // 更新上次转录文本，避免重复插入
                            self.lastTranscribedText = newEditedText

                            // 尝试使用NSTextView API获取光标位置的简单方法
                            if let firstResponder = NSApp.keyWindow?.firstResponder as? NSTextView {
                                if let range = firstResponder.selectedRanges.first as? NSRange {
                                    self.cursorPosition = range.location
                                    print(
                                        "\u{001B}[36m[DEBUG]\u{001B}[0m 光标位置更新为: \(self.cursorPosition)"
                                    )
                                }
                            }
                        }
                    }
                    .onTapGesture {
                        self.onTextFieldFocus()
                    }
                    .contextMenu {
                        Button("Copy") {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(self.editableText, forType: .string)
                        }
                        .disabled(self.editableText.isEmpty)

                        Button("Cut") {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(self.editableText, forType: .string)
                            self.editableText = ""
                            self.dictationManager.transcribedText = ""
                            self.isPlaceholderVisible = true
                        }
                        .disabled(self.editableText.isEmpty)

                        Button("Paste") {
                            if let clipboardContent = NSPasteboard.general
                                .string(forType: .string)
                            {
                                self.editableText = clipboardContent
                                self.dictationManager.transcribedText = clipboardContent
                                self.isPlaceholderVisible = false
                            }
                        }

                        Divider()

                        // 新增语音转写相关功能
                        Button(
                            self.dictationManager
                                .state == .recording ? "Stop Recording" : "Start Recording"
                        ) {
                            if self.dictationManager.state == .recording {
                                self.dictationManager.stopRecording()
                            } else {
                                self.dictationManager.startRecording()
                            }
                        }

                        Button("Clear Text") {
                            self.editableText = ""
                            self.dictationManager.transcribedText = ""
                            self.isPlaceholderVisible = true
                        }
                        .disabled(self.editableText.isEmpty)

                        Divider()

                        // 格式优化选项
                        Button("大写首字母") {
                            if !self.editableText.isEmpty {
                                let firstChar = self.editableText.prefix(1).uppercased()
                                let restOfText = self.editableText.dropFirst()
                                self.editableText = firstChar + restOfText
                                self.dictationManager.transcribedText = self.editableText
                            }
                        }
                        .disabled(self.editableText.isEmpty)

                        Button("按句子优化格式") {
                            if !self.editableText.isEmpty {
                                // 分割句子
                                let sentences = self.editableText.components(separatedBy: ". ")
                                let formattedSentences = sentences.map { sentence -> String in
                                    if sentence.isEmpty { return sentence }
                                    let firstChar = sentence.prefix(1).uppercased()
                                    let restOfSentence = sentence.dropFirst()
                                    return firstChar + restOfSentence
                                }

                                // 重新组合句子
                                self.editableText = formattedSentences.joined(separator: ". ")
                                self.dictationManager.transcribedText = self.editableText
                            }
                        }
                        .disabled(self.editableText.isEmpty)
                    }
                    .accentColor(Color(red: 0.3, green: 0.9, blue: 0.7))
                    .colorScheme(.dark)
            }
            .onAppear {
                // 初始化上次转录文本
                self.lastTranscribedText = self.dictationManager.transcribedText
            }
        }

        // 在光标位置插入新文本
        private func insertTextAtCursor(_ newText: String) {
            // 调试日志
            print("\u{001B}[36m[DEBUG]\u{001B}[0m 接收到新转录文本: \(newText)")
            print("\u{001B}[36m[DEBUG]\u{001B}[0m 上次转录文本: \(self.lastTranscribedText)")
            print("\u{001B}[36m[DEBUG]\u{001B}[0m 当前编辑框文本: \(self.editableText)")
            print("\u{001B}[36m[DEBUG]\u{001B}[0m 当前光标位置: \(self.cursorPosition)")

            // 如果当前是空文本或占位符，直接替换
            if self.editableText.isEmpty || self
                .editableText == "This is the live transcription..."
            {
                self.editableText = newText
                self.isPlaceholderVisible = false
                self.lastTranscribedText = newText // 更新上次文本
                self.onTranscriptionTextChange(newText)
                return
            }

            // 确保转录文本确实有变化
            if newText.isEmpty || newText == self.lastTranscribedText {
                return
            }

            // 检查光标位置是否有效
            let cursorPos = min(cursorPosition, editableText.count)

            // 获取真正新增的部分 - 使用更精确的差异检测
            if let newlyAddedText = getActualNewContent(from: lastTranscribedText, to: newText) {
                print("\u{001B}[36m[DEBUG]\u{001B}[0m 精确检测到的新增文本: \(newlyAddedText)")

                // 准备在光标位置插入文本
                let startIndex = self.editableText.startIndex
                let cursorIndex = self.editableText.index(startIndex, offsetBy: cursorPos)

                let textBeforeCursor = String(editableText[startIndex ..< cursorIndex])
                let textAfterCursor = String(editableText[cursorIndex...])

                // 在光标位置插入新文本
                self.editableText = textBeforeCursor + newlyAddedText + textAfterCursor
                self.isPlaceholderVisible = false

                // 更新光标位置到新插入内容之后
                self.cursorPosition = cursorPos + newlyAddedText.count

                // 记录这次处理过的文本，避免重复处理
                self.lastTranscribedText = newText

                // 通知外部文本已变更
                self.onTranscriptionTextChange(self.editableText)
            } else {
                // 如果无法确定新增内容，但文本确实变了，仅更新跟踪状态
                print("\u{001B}[36m[DEBUG]\u{001B}[0m 无法确定新增内容，更新跟踪状态")
                self.lastTranscribedText = newText
            }
        }

        // 新的更精确的差异检测函数
        private func getActualNewContent(from oldText: String, to newText: String) -> String? {
            // 情况1: 旧文本为空，则新文本就是全部新增内容
            if oldText.isEmpty {
                return newText
            }

            // 情况2: 新文本是旧文本的完全延续（附加在末尾）
            if newText.hasPrefix(oldText), newText.count > oldText.count {
                let newContentStartIndex = newText.index(
                    newText.startIndex,
                    offsetBy: oldText.count
                )
                return String(newText[newContentStartIndex...])
            }

            // 情况3: 使用词语比较找出差异
            // 首先尝试直接比较两个文本的最后部分，看是否为简单附加
            let oldTextWords = oldText.split(separator: " ")
            let newTextWords = newText.split(separator: " ")

            // 如果新文本比旧文本多几个词，可能是简单附加
            if newTextWords.count > oldTextWords.count {
                // 检查新文本的前部分是否与旧文本相同
                let overlap = min(oldTextWords.count, newTextWords.count)
                var isAppend = true

                for i in 0 ..< overlap {
                    if oldTextWords[i] != newTextWords[i] {
                        isAppend = false
                        break
                    }
                }

                if isAppend {
                    // 是简单附加，取出新增的部分
                    let addedWords = newTextWords[oldTextWords.count...]
                    let newContent = addedWords.joined(separator: " ")
                    return newContent.isEmpty ? nil : " " + newContent
                }
            }

            // 情况4: 检查是否在末尾添加了内容（通过反向查找）
            let oldReversed = String(oldText.reversed())
            let newReversed = String(newText.reversed())
            let commonSuffixLength = newReversed.commonPrefix(with: oldReversed).count

            if commonSuffixLength < newText.count {
                // 从末尾开始有共同部分，前面部分可能有变化
                let diffStart = newText.count - commonSuffixLength
                let diffStartIndex = newText.index(newText.startIndex, offsetBy: diffStart)
                let newStart = newText[newText.startIndex ..< diffStartIndex]

                // 检查这个部分是否是真正的新增内容
                if !oldText.contains(String(newStart)) {
                    let newContent = String(newStart)
                    return newContent.isEmpty ? nil : newContent
                }
            }

            // 情况5: 使用最简单的方法 - 假设新的句子总是附加的
            // 查找最后一个标点符号或空格，认为之后的是新内容
            if let lastSentenceStart = newText
                .lastIndex(where: { $0 == "." || $0 == "?" || $0 == "!" || $0 == "," })
            {
                let afterIndex = newText.index(after: lastSentenceStart)
                let potentialNewContent = String(newText[afterIndex...])
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                // 确认这部分不在旧文本中
                if !oldText.contains(potentialNewContent), !potentialNewContent.isEmpty {
                    return " " + potentialNewContent
                }
            }

            // 如果所有策略都失败，尝试直接取最后一个词
            let lastSpaceIndex = newText.lastIndex(of: " ") ?? newText.startIndex
            let potentialLastWord = String(newText[newText.index(after: lastSpaceIndex)...])

            if !oldText.contains(potentialLastWord), !potentialLastWord.isEmpty {
                return " " + potentialLastWord
            }

            // 无法确定新增内容
            return nil
        }
    }

    // 按钮行
    private var buttonRowView: some View {
        HStack {
            // 使用GeometryReader获取可用宽度
            GeometryReader { geometry in
                HStack(spacing: 12) { // 增加按钮之间的间距
                    Spacer(minLength: 8)

                    // 暂停/播放按钮 - 根据当前状态显示不同提示
                    self.controlButton(
                        icon: self.playPauseIconName,
                        title: self.dictationManager
                            .state == .recording ? "Pause Recording" : "Start Recording",
                        action: self.handlePlayPauseAction,
                        isDisabled: self.dictationManager.state == .processing,
                        width: (geometry.size.width - 80) / 6 // 调整宽度以适应新按钮
                    )

                    // 停止按钮 - 只在录音/暂停状态下激活
                    self.controlButton(
                        icon: "stop.fill",
                        title: "Stop Recording",
                        action: { self.dictationManager.stopRecording() },
                        isDisabled: self.dictationManager.state == .idle || self.dictationManager
                            .state == .processing,
                        width: (geometry.size.width - 80) / 6 // 调整宽度以适应新按钮
                    )

                    // Magic 按钮 - 添加新按钮
                    self.controlButton(
                        icon: "wand.and.stars",
                        title: "Magic Transform",
                        action: {
                            Task { await MagicTransformManager.shared.run(raw: self.editableText) }
                        },
                        isDisabled: !TunaSettings.shared.magicEnabled || self.editableText
                            .isEmpty ||
                            (
                                self.isPlaceholderVisible && self.editableText ==
                                    "This is the live transcription..."
                            ),
                        width: (geometry.size.width - 80) / 6
                    )

                    // 清除按钮 - 放宽禁用条件，当占位符显示时才禁用
                    self.controlButton(
                        icon: "xmark",
                        title: "Clear Text",
                        action: self.clearText,
                        isDisabled: self.isPlaceholderVisible && self.editableText ==
                            "This is the live transcription...",
                        width: (geometry.size.width - 80) / 6 // 调整宽度以适应新按钮
                    )

                    // 复制按钮 - 放宽禁用条件，当占位符显示时才禁用
                    self.controlButton(
                        icon: "doc.on.doc",
                        title: "Copy to Clipboard",
                        action: self.copyToClipboard,
                        isDisabled: self.isPlaceholderVisible && self.editableText ==
                            "This is the live transcription...",
                        width: (geometry.size.width - 80) / 6 // 调整宽度以适应新按钮
                    )

                    // 保存按钮 - 放宽禁用条件，当占位符显示时才禁用
                    self.controlButton(
                        icon: "square.and.arrow.down",
                        title: "Export to File",
                        action: self.saveTranscription,
                        isDisabled: self.isPlaceholderVisible && self.editableText ==
                            "This is the live transcription...",
                        width: (geometry.size.width - 80) / 6 // 调整宽度以适应新按钮
                    )

                    Spacer(minLength: 8)
                }
                .frame(width: geometry.size.width)
            }
            .frame(height: 34)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // 按钮组件
    private func controlButton(
        icon: String,
        title: String,
        action: @escaping () -> Void,
        isDisabled: Bool,
        width: CGFloat
    ) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: icon == "square.and.arrow.down" ? 17 : 16))
                .foregroundColor(.white)
                .frame(width: width, height: 34)
                .offset(y: icon == "square.and.arrow.down" ? -1 : 0) // 调整垂直位置
                .background(
                    ZStack {
                        VisualEffectView(material: .popover, blendingMode: .behindWindow)
                        Color.white.opacity(0.1)
                    }
                )
                .cornerRadius(6)
                .opacity(isDisabled ? 0.6 : 1.0) // 增加不透明度，让禁用状态下的按钮更加可见
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDisabled)
        .help(title) // 显示悬停提示文本
    }

    // 复制到剪贴板
    private func copyToClipboard() {
        // 不复制占位符文本
        if self.isPlaceholderVisible, self.editableText == "This is the live transcription..." {
            return
        }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(self.editableText, forType: .string)

        // 添加复制成功提示
        self.dictationManager.progressMessage = "Text copied to clipboard"
    }

    // 播放/暂停按钮动作
    private func handlePlayPauseAction() {
        switch self.dictationManager.state {
            case .idle:
                // 开始新录音时重置占位符状态，但保留用户可能编辑过的文本
                if self.editableText == "This is the live transcription..." || self.editableText
                    .isEmpty
                {
                    self.isPlaceholderVisible = true
                    self.editableText = "This is the live transcription..."
                } else {
                    // 如果用户已经有文本，保留它
                    self.isPlaceholderVisible = false
                    // 确保dictationManager使用当前编辑框中的文本
                    self.dictationManager.transcribedText = self.editableText
                }
                self.dictationManager.startRecording()
            case .recording:
                self.dictationManager.pauseRecording()
            case .paused:
                // 继续录音时使用当前编辑框中的文本，确保不恢复被删除的内容
                print("\u{001B}[36m[DEBUG]\u{001B}[0m 从暂停恢复录音，使用当前编辑文本: \(self.editableText)")
                // 明确将当前用户编辑的文本设置为转录文本，覆盖任何可能的旧内容
                self.dictationManager.transcribedText = self.editableText
                // 确保占位符状态正确
                self.isPlaceholderVisible = self.editableText
                    .isEmpty || self.editableText == "This is the live transcription..."
                self.dictationManager.startRecording()
            case .processing:
                // 处理中不执行任何操作
                break
            case .error:
                // 错误状态尝试重置
                print("\u{001B}[31m[ERROR]\u{001B}[0m 录音处于错误状态，尝试重置")
                self.dictationManager.state = .idle
        }
    }

    // 播放/暂停按钮图标
    private var playPauseIconName: String {
        switch self.dictationManager.state {
            case .idle, .paused:
                "play.fill"
            case .recording:
                "pause.fill"
            case .processing:
                "hourglass"
            case .error:
                "exclamationmark.triangle"
        }
    }

    // 状态文本
    private var statusText: String {
        if self.dictationManager.state == .recording {
            return "Listening..."
        } else if !self.dictationManager.progressMessage.isEmpty {
            return self.dictationManager.progressMessage
        } else if self.dictationManager.transcribedText.isEmpty,
                  self.dictationManager.state == .idle
        {
            return "No recording files"
        }

        switch self.dictationManager.state {
            case .idle:
                return "Ready to record"
            case .recording:
                return "Listening..."
            case .paused:
                return "Paused"
            case .processing:
                return "Processing..."
            case .error:
                return "Error occurred"
        }
    }

    // 音频可视化效果
    private var audioVisualizerView: some View {
        HStack(alignment: .center, spacing: 2) {
            ForEach(0 ..< 15, id: \.self) { index in
                AudioVisualBar(
                    isRecording: self.dictationManager.state == .recording,
                    disableAnimations: self.animationsDisabled,
                    fixedTestHeight: self.animationsDisabled ? 5 + CGFloat(index % 5) * 4 : nil
                )
            }
        }
    }

    // 启动/停止可视化效果
    private func startVisualizing() {
        self.isVisualizing = true
    }

    private func stopVisualizing() {
        self.isVisualizing = false
    }

    // 保存转录文本到用户设置的路径
    private func saveTranscription() {
        // 不保存占位符文本
        if self.isPlaceholderVisible, self.editableText == "This is the live transcription..." {
            return
        }

        // 使用editableText而不是dictationManager.transcribedText，以便用户的编辑也会被保存
        let text = self.editableText
        let timestamp = DateFormatter.localizedString(
            from: Date(),
            dateStyle: .short,
            timeStyle: .medium
        )
        .replacingOccurrences(of: "/", with: "-")
        .replacingOccurrences(of: ":", with: "-")

        // 获取用户设置的输出目录
        let outputDir = self.dictationManager.getDocumentsDirectory()
        let outputFormat = self.dictationManager.outputFormat
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
            self.dictationManager.progressMessage = "Saved to: \(outputURL.lastPathComponent)"
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(outputURL.path, forType: .string)
            print("Saved successfully: \(outputURL.path)")
        } catch {
            self.dictationManager.progressMessage = "Save failed: \(error.localizedDescription)"
            print("Save failed: \(error.localizedDescription)")
        }
    }

    // 在获得转录结果后显示编辑提示
    private func showEditingHint() {
        // 由于不再需要显示编辑提示，此函数可以为空或完全移除
    }

    // 清除文本
    private func clearText() {
        self.editableText = ""
        self.dictationManager.transcribedText = ""
        self.isPlaceholderVisible = true
        self.editableText = "This is the live transcription..."
        self.dictationManager.progressMessage = "Text cleared"
    }
}

// 音频可视化条 - 使用mint绿色
struct AudioVisualBar: View {
    let isRecording: Bool
    @State private var height: CGFloat = 5

    // 定时器状态
    @State private var timer: Timer?

    // 测试模式 - 禁用随机动画
    var disableAnimations: Bool = false

    // 允许为测试指定固定高度
    var fixedTestHeight: CGFloat? = nil

    // 时间提供者
    private let nowProvider: NowProvider

    init(
        isRecording: Bool = true,
        disableAnimations: Bool = false,
        fixedTestHeight: CGFloat? = nil,
        nowProvider: NowProvider = RealNowProvider()
    ) {
        self.isRecording = isRecording
        self.disableAnimations = disableAnimations
        self.fixedTestHeight = fixedTestHeight
        self.nowProvider = nowProvider
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(Color(red: 0.3, green: 0.9, blue: 0.7))
            .frame(width: 2, height: self.height)
            .onAppear {
                self.startAnimation()
            }
            .onDisappear {
                self.stopAnimation()
            }
    }

    private func startAnimation() {
        // 停止现有的计时器
        self.stopAnimation()

        // 如果有固定测试高度，使用它
        if let testHeight = fixedTestHeight {
            self.height = testHeight
            return
        }

        // 如果禁用了动画，则使用固定高度
        if self.disableAnimations {
            // 使用确定性的高度模式
            let baseHeights: [CGFloat] = [5, 10, 15, 20, 15, 10, 5, 8, 12, 18, 14, 10, 6, 10, 15]
            let index = Int(
                nowProvider.now.timeIntervalSince1970
                    .truncatingRemainder(dividingBy: 15)
            )
            self.height = baseHeights[index]
            return
        }

        // 根据录制状态设置高度
        if !self.isRecording {
            self.height = 5
            return
        }

        // 为录制状态创建动画
        self.timer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { _ in
            withAnimation(.linear(duration: 0.1)) {
                self.height = CGFloat.random(in: 2 ... 24)
            }
        }

        // 立即触发一次
        withAnimation(.linear(duration: 0.1)) {
            self.height = CGFloat.random(in: 2 ... 24)
        }
    }

    private func stopAnimation() {
        self.timer?.invalidate()
        self.timer = nil

        withAnimation {
            self.height = 5
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

// 添加隐藏滚动条的修饰符
struct HideScrollbarModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onAppear {
                // 使用DispatchQueue.main.async确保UI已完全加载
                DispatchQueue.main.async {
                    // 查找所有NSScrollView并修改滚动条
                    for subview in NSApp.keyWindow?.contentView?.subviews ?? [] {
                        self.modifyScrollViews(in: subview)
                    }
                }
            }
    }

    // 递归查找并修改所有NSScrollView
    private func modifyScrollViews(in view: NSView) {
        // 修改当前视图如果是NSScrollView
        if let scrollView = view as? NSScrollView {
            // 只显示自动滚动条 (当内容超出时)
            scrollView.hasVerticalScroller = true
            scrollView.autohidesScrollers = true

            // 降低滚动条不透明度
            scrollView.verticalScroller?.alphaValue = 0.5

            // 使滚动条更窄
            if let scroller = scrollView.verticalScroller {
                scroller.knobStyle = .light
            }
        }

        // 递归检查子视图
        for subview in view.subviews {
            self.modifyScrollViews(in: subview)
        }
    }
}
