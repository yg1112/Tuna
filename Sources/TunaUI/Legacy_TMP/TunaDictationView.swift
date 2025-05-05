import SwiftUI
import TunaCore
import TunaSpeech
import TunaTypes
import TunaUI

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
                if self.dictationManager.state.state == .recording {
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
                } else if self.dictationManager.state.state == .processing {
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
                   self.dictationManager.transcribedText.isEmpty
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
                            self.dictationManager.state
                                .state == .recording ? "Stop Recording" : "Start Recording"
                        ) {
                            Task {
                                if self.dictationManager.state.state == .recording {
                                    await self.dictationManager.stopRecording()
                                } else {
                                    await self.dictationManager.startRecording()
                                }
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
            }
            .padding(.horizontal, 12)

            // 可视化音频
            if self.dictationManager.state.state == .recording {
                self.visualizerView
            }

            // 底部工具栏
            HStack(spacing: 12) {
                // 播放/暂停按钮
                Button(action: {
                    Task {
                        await self.handlePlayPauseAction()
                    }
                }) {
                    Image(systemName: self.playPauseIconName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(width: 32, height: 32)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(
                                    self.dictationManager.state.state == .recording ?
                                        Color.white.opacity(0.8) : // 录音时显示常亮的珍珠白色边框
                                        Color.white.opacity(self.isBreathingAnimation ? 0.2 : 0.05),
                                    // 非录音时使用呼吸动画
                                    lineWidth: self.dictationManager
                                        .state
                                        .state ==
                                        .recording ? 1.5 :
                                        (
                                            self
                                                .isBreathingAnimation ?
                                                1.2 : 0.8
                                        )
                                )
                                .scaleEffect(
                                    self.dictationManager
                                        .state
                                        .state ==
                                        .recording ? 1.0 :
                                        (
                                            self
                                                .isBreathingAnimation ?
                                                1.01 : 1.0
                                        )
                                )
                        )
                        .animation(
                            self.dictationManager.state.state == .recording ? nil :
                                Animation.easeInOut(duration: 1.5)
                                .repeatForever(autoreverses: true),
                            value: self.isBreathingAnimation
                        )
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(self.dictationManager.state.state == .processing)

                // 状态文本
                Text(self.statusText)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
        }
        .frame(width: 400)
        .background(Color(.windowBackgroundColor))
        .cornerRadius(12)
        .onAppear {
            // 启动呼吸动画
            self.isBreathingAnimation = true
        }
    }

    // 音频可视化视图
    private var visualizerView: some View {
        HStack(spacing: 2) {
            ForEach(0 ..< 15, id: \.self) { index in
                AudioVisualBar(
                    isRecording: self.dictationManager.state.state == .recording,
                    disableAnimations: self.animationsDisabled,
                    fixedTestHeight: self.animationsDisabled ? 5 + CGFloat(index % 5) * 4 : nil
                )
            }
        }
        .frame(height: 32)
        .padding(.horizontal, 12)
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

    // 播放/暂停按钮动作
    private func handlePlayPauseAction() async {
        switch self.dictationManager.state.state {
            case .idle:
                if self.editableText == "This is the live transcription..." || self.editableText
                    .isEmpty
                {
                    self.dictationManager.transcribedText = self.editableText
                }
                await self.dictationManager.startRecording()
            case .recording:
                await self.dictationManager.pauseRecording()
            case .paused:
                print("\u{001B}[36m[DEBUG]\u{001B}[0m 从暂停恢复录音，使用当前编辑文本: \(self.editableText)")
                self.isPlaceholderVisible = self.editableText.isEmpty || self
                    .editableText == "This is the live transcription..."
                await self.dictationManager.startRecording()
            case .processing:
                break
            case .error:
                print("\u{001B}[31m[ERROR]\u{001B}[0m 录音处于错误状态，尝试重置")
                self.dictationManager.state = DictationState(state: .idle)
        }
    }

    // 播放/暂停按钮图标
    private var playPauseIconName: String {
        switch self.dictationManager.state.state {
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
        if self.dictationManager.state.state == .recording {
            return "Listening..."
        } else if !self.dictationManager.progressMessage.isEmpty {
            return self.dictationManager.progressMessage
        } else if self.dictationManager.transcribedText.isEmpty,
                  self.dictationManager.state.state == .idle
        {
            return "No recording files"
        }

        switch self.dictationManager.state.state {
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
}

// 语音转写视图
struct TunaDictationView: View {
    @EnvironmentObject var settings: TunaSettings
    @ObservedObject private var dictationManager = DictationManager.shared
    @State private var isVisualizing = false
    @State private var isPlaceholderVisible = true
    @State private var editableText: String = ""
    @State private var isBreathingAnimation = false
    @State private var cursorPosition: Int = 0
    @State private var isFocused: Bool = false
    @State private var lastTranscribedText: String = ""

    private let animationsDisabled: Bool

    init() {
        self.animationsDisabled = false
    }

    init(animationsDisabled: Bool = false) {
        self.animationsDisabled = animationsDisabled
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 标题部分
            HStack {
                Text("语音转文字")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.primary)

                Spacer()

                // 录音状态指示
                if self.dictationManager.state.state == .recording {
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
                } else if self.dictationManager.state.state == .processing {
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
                   self.dictationManager.transcribedText.isEmpty
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
                            self.dictationManager.state
                                .state == .recording ? "Stop Recording" : "Start Recording"
                        ) {
                            Task {
                                if self.dictationManager.state.state == .recording {
                                    await self.dictationManager.stopRecording()
                                } else {
                                    await self.dictationManager.startRecording()
                                }
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
            }
            .padding(.horizontal, 12)

            // 可视化音频
            if self.dictationManager.state.state == .recording {
                self.visualizerView
            }

            // 底部工具栏
            HStack(spacing: 12) {
                // 播放/暂停按钮
                Button(action: {
                    Task {
                        await self.handlePlayPauseAction()
                    }
                }) {
                    Image(systemName: self.playPauseIconName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(width: 32, height: 32)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(
                                    self.dictationManager.state.state == .recording ?
                                        Color.white.opacity(0.8) : // 录音时显示常亮的珍珠白色边框
                                        Color.white.opacity(self.isBreathingAnimation ? 0.2 : 0.05),
                                    // 非录音时使用呼吸动画
                                    lineWidth: self.dictationManager
                                        .state
                                        .state ==
                                        .recording ? 1.5 :
                                        (
                                            self
                                                .isBreathingAnimation ?
                                                1.2 : 0.8
                                        )
                                )
                                .scaleEffect(
                                    self.dictationManager
                                        .state
                                        .state ==
                                        .recording ? 1.0 :
                                        (
                                            self
                                                .isBreathingAnimation ?
                                                1.01 : 1.0
                                        )
                                )
                        )
                        .animation(
                            self.dictationManager.state.state == .recording ? nil :
                                Animation.easeInOut(duration: 1.5)
                                .repeatForever(autoreverses: true),
                            value: self.isBreathingAnimation
                        )
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(self.dictationManager.state.state == .processing)

                // 状态文本
                Text(self.statusText)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
        }
        .frame(width: 400)
        .background(Color(.windowBackgroundColor))
        .cornerRadius(12)
        .onAppear {
            // 启动呼吸动画
            self.isBreathingAnimation = true
        }
    }

    // 音频可视化视图
    private var visualizerView: some View {
        HStack(spacing: 2) {
            ForEach(0 ..< 15, id: \.self) { index in
                AudioVisualBar(
                    isRecording: self.dictationManager.state.state == .recording,
                    disableAnimations: self.animationsDisabled,
                    fixedTestHeight: self.animationsDisabled ? 5 + CGFloat(index % 5) * 4 : nil
                )
            }
        }
        .frame(height: 32)
        .padding(.horizontal, 12)
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

    // 播放/暂停按钮动作
    private func handlePlayPauseAction() async {
        switch self.dictationManager.state.state {
            case .idle:
                if self.editableText == "This is the live transcription..." || self.editableText
                    .isEmpty
                {
                    self.dictationManager.transcribedText = self.editableText
                }
                await self.dictationManager.startRecording()
            case .recording:
                await self.dictationManager.pauseRecording()
            case .paused:
                print("\u{001B}[36m[DEBUG]\u{001B}[0m 从暂停恢复录音，使用当前编辑文本: \(self.editableText)")
                self.isPlaceholderVisible = self.editableText.isEmpty || self
                    .editableText == "This is the live transcription..."
                await self.dictationManager.startRecording()
            case .processing:
                break
            case .error:
                print("\u{001B}[31m[ERROR]\u{001B}[0m 录音处于错误状态，尝试重置")
                self.dictationManager.state = DictationState(state: .idle)
        }
    }

    // 播放/暂停按钮图标
    private var playPauseIconName: String {
        switch self.dictationManager.state.state {
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
        if self.dictationManager.state.state == .recording {
            return "Listening..."
        } else if !self.dictationManager.progressMessage.isEmpty {
            return self.dictationManager.progressMessage
        } else if self.dictationManager.transcribedText.isEmpty,
                  self.dictationManager.state.state == .idle
        {
            return "No recording files"
        }

        switch self.dictationManager.state.state {
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
                nowProvider.now().timeIntervalSince1970
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
                // 使用await MainActor.run确保UI已完全加载
                Task { @MainActor in
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
