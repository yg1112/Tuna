import AVFoundation
import Combine
import Foundation
import os.log
import SwiftUI
import TunaAudio
import TunaTypes

/// Manages audio dictation and transcription
@MainActor
public class DictationManager: NSObject, DictationManagerProtocol {
    @MainActor public static let shared = DictationManager(
        providerType: WhisperProvider.self,
        secureStore: SecureStore.shared,
        notifierType: Notifier.self
    )

    // 允许替换单例以便测试
    #if DEBUG
    public static func createForTesting(nowProvider: NowProvider = RealNowProvider())
    -> DictationManager {
        let manager = DictationManager(nowProvider: nowProvider)
        return manager
    }

    // 用于测试的重置方法
    public func reset() {
        self._state = DictationState()
        self._progressMessage = ""
        self._transcribedText = ""
        self.recordingParts = []
        self.processedSegments = []
    }
    #endif

    // MARK: - Dependencies
    public let providerType: SpeechProviderProtocol.Type
    public let secureStore: any SecureStoreProtocol
    public let notifierType: any NotifierProtocol.Type

    // MARK: - Init
    public init(
        providerType: SpeechProviderProtocol.Type = WhisperProvider.self,
        secureStore: any SecureStoreProtocol = SecureStore.shared,
        notifierType: any NotifierProtocol.Type = Notifier.self,
        nowProvider: NowProvider = RealNowProvider(),
        uuidProvider: UUIDProvider = RealUUIDProvider()
    ) {
        self.providerType = providerType
        self.secureStore = secureStore
        self.notifierType = notifierType
        self.nowProvider = nowProvider
        self.uuidProvider = uuidProvider
        super.init()
        self.setupRecordingSession()
    }

    // MARK: - Protocol Properties
    @Published private var _state = DictationState()
    @Published private var _progressMessage: String = ""
    @Published private var _transcribedText: String = ""

    public var state: DictationState {
        get {
            self._state
        }
        set {
            self._state = newValue
        }
    }

    public var progressMessage: String {
        get {
            self._progressMessage
        }
        set {
            self._progressMessage = newValue
        }
    }

    public var transcribedText: String {
        get {
            self._transcribedText
        }
        set {
            self._transcribedText = newValue
        }
    }

    public var isRecording: Bool {
        self._state.isRecording
    }

    public var isPaused: Bool {
        self._state.isPaused
    }

    public var breathingAnimation: Bool {
        self._state.breathingAnimation
    }

    // MARK: - Private Properties
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: "DictationManager"
    )
    private let tunaSettings = TunaSettings.shared
    private let nowProvider: NowProvider
    private let uuidProvider: UUIDProvider
    private var tempDirectory: URL?

    // 添加启动失败回调
    public var onStartFailure: (() -> Void)?

    // 录音相关
    private var audioRecorder: AVAudioRecorder?
    private var recordingURL: URL?
    private var recordingParts: [URL] = []
    private var processedSegments: Set<URL> = []

    // 修改API密钥获取方式，使用SecureStore
    private var apiKey: String {
        do {
            if let data = try secureStore.load(
                key: SecureStore.defaultAccount,
                account: SecureStore.defaultAccount
            ),
                let str = String(data: Data(data.utf8), encoding: .utf8)
            {
                return str
            }
            return ""
        } catch {
            self.logger
                .error("Failed to get API key from Keychain: \(error.localizedDescription)")
            return ""
        }
    }

    // MARK: - Public Methods

    // 添加toggle方法，根据当前状态切换录音状态
    public func toggle() async {
        let state = self.state.state
        switch state {
            case .idle:
                await self.startRecording()
            case .recording:
                await self.pauseRecording()
            case .paused:
                await self.continueRecording()
            case .processing:
                self.logger.notice("Cannot toggle - processing")
            case .error:
                self.logger.notice("Cannot toggle - error")
        }
    }

    public func resumeRecording() async {
        let state = self.state.state
        if state == .paused {
            await self.continueRecording()
        }
    }

    public func startRecording() async {
        self.logger.notice("开始录音...")

        // 如果已经在录音，直接返回
        if self.isRecording {
            self.logger.notice("已经在录音中，忽略请求")
            return
        }

        // 设置状态消息
        self.progressMessage = "准备录音..."
        print("🎙 DictationManager.startRecording() 被调用，当前状态: \(self.state)")

        // 确保音频会话已设置
        self.setupRecordingSession()

        // 实际启动录音逻辑
        await self.continueRecording()
    }

    private func continueRecording() async {
        Logger(subsystem: "ai.tuna", category: "Shortcut")
            .notice("[R] startRecording() actually called")
        self.sendDebugNotification(message: "开始执行录音流程")

        // 确保我们处于正确的状态
        let state = self.state.state
        guard state == .idle || state == .paused else {
            self.logger.warning("Cannot start recording - wrong state")
            self.sendDebugNotification(message: "无法开始录音 - 状态错误: \(self.state)")
            return
        }

        // 如果处于暂停状态，创建新的录音片段
        if state == .paused, self.audioRecorder != nil {
            // 保存已有的audioRecorder用于清理
            let oldRecorder = self.audioRecorder

            // 创建新的录音文件
            let fileName = "dictation_\(nowProvider.now().timeIntervalSince1970).wav"
            recordingURL = self.tempDirectory?.appendingPathComponent(fileName)

            guard let recordingURL else {
                self.logger.error("Failed to create recording URL")
                self.progressMessage = "⚠️ 无法创建录音文件"
                self.onStartFailure?()
                return
            }

            // 设置录音参数 - 使用更简单的WAV格式，更容易被Whisper API处理
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatLinearPCM), // 使用无损PCM格式
                AVSampleRateKey: 16000.0, // 16kHz采样率，Whisper模型接受这个采样率
                AVNumberOfChannelsKey: 1, // 单声道
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
                AVLinearPCMBitDepthKey: 16, // 16位
                AVLinearPCMIsBigEndianKey: false,
                AVLinearPCMIsFloatKey: false,
            ]

            do {
                self.audioRecorder = try AVAudioRecorder(url: recordingURL, settings: settings)
                self.audioRecorder?.delegate = nil
                self.audioRecorder?.record()

                // 添加到录音部分列表
                self.recordingParts.append(recordingURL)

                // 停止并释放旧的录音器
                oldRecorder?.stop()

                // 更新状态
                var newState = self.state
                newState.state = .recording
                self.state = newState
                self.progressMessage = "🎙 正在录音..."

                // 触发UI更新
                let current = self.transcribedText
                self.transcribedText = ""
                self.transcribedText = current

                self.logger.debug("Created new recording segment at \(recordingURL.path)")
                self.logger.notice("state -> recording (continue)")
            } catch {
                self.logger.error("Failed to continue recording: \(error.localizedDescription)")
                self.progressMessage = "⚠️ 录音失败: \(error.localizedDescription)"

                // 恢复旧的录音器状态
                self.audioRecorder = oldRecorder
                self.onStartFailure?()
            }

            return
        }

        // 如果不是从暂停状态继续，则清除已有的转录内容并开始新录音
        if state == .idle {
            // 清除转录文本以开始新录音
            self.transcribedText = ""
            self.recordingParts = []
            self.processedSegments = [] // 重置已处理片段记录
        }

        // 创建新的录音文件
        let fileName = "dictation_\(nowProvider.now().timeIntervalSince1970).wav"
        recordingURL = self.tempDirectory?.appendingPathComponent(fileName)

        guard let recordingURL else {
            self.logger.error("Failed to create recording URL")
            self.progressMessage = "⚠️ 无法创建录音文件"
            self.onStartFailure?()
            return
        }

        // 设置录音参数
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16000.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false,
        ]

        do {
            self.audioRecorder = try AVAudioRecorder(url: recordingURL, settings: settings)
            self.audioRecorder?.delegate = nil
            self.audioRecorder?.record()

            // 添加到录音部分列表
            self.recordingParts.append(recordingURL)

            var newState = self.state
            newState.state = .recording
            self.state = newState
            self.progressMessage = "🎙 正在录音..."
            self.logger.debug("Started new recording at \(recordingURL.path)")
            self.logger.notice("state -> recording (new)")
        } catch {
            self.logger.error("Failed to start recording: \(error.localizedDescription)")
            self.progressMessage = "⚠️ 录音失败: \(error.localizedDescription)"
            self.onStartFailure?()
        }
    }

    public func pauseRecording() async {
        guard self.state.state == .recording, let audioRecorder else {
            self.logger.warning("Cannot pause - not recording or recorder is nil")
            return
        }

        // 暂停录音并确保文件被正确写入
        audioRecorder.pause()

        // 重要：等待一小段时间确保文件被正确写入
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 500_000_000)
            self.notifierType.post(NSNotification.Name.fileSelectionEnded, object: nil)
        }

        var newState = self.state
        newState.state = .paused
        self.state = newState
        self.progressMessage = "Recording paused, processing..."
        self.logger.debug("Recording paused, preparing to transcribe current segment")

        // 获取当前录音文件并转录
        if let currentRecordingURL = recordingURL,
           FileManager.default.fileExists(atPath: currentRecordingURL.path)
        {
            // 验证文件大小
            do {
                let fileAttributes = try FileManager.default
                    .attributesOfItem(atPath: currentRecordingURL.path)
                if let fileSize = fileAttributes[.size] as? Int {
                    let fileSizeKB = Double(fileSize) / 1024.0
                    self.logger.debug("Recording file size when paused: \(fileSizeKB) KB")

                    if fileSize < 500 { // 少于500字节可能不是有效音频
                        self.progressMessage =
                            "Recording paused (segment too short to transcribe)"
                        self.logger
                            .warning("Recording segment too short, skipping transcription")
                        return
                    }
                }
            } catch {
                self.logger.error("Cannot get file attributes: \(error.localizedDescription)")
            }

            // 临时保存当前URL以便继续录音
            let currentURL = self.recordingURL

            // 转录当前片段
            await self.transcribeCurrentSegment(currentURL!)
        }
    }

    public func stopRecording() async {
        let state = self.state.state
        guard state == .recording || state == .paused, let audioRecorder else {
            self.logger.warning("Cannot stop - not recording/paused or recorder is nil")
            return
        }

        audioRecorder.stop()
        var newState = self.state
        newState.state = .processing
        self.state = newState

        // 检查是否所有片段都已处理
        let unprocessedParts = self.recordingParts.filter { !self.processedSegments.contains($0) }

        if unprocessedParts.isEmpty {
            self.logger.debug("Recording stopped - all segments already transcribed")
            self.progressMessage = "Processing complete, all content transcribed"
            await self.finalizeTranscription()

            // 清理
            self.recordingParts = []
            self.audioRecorder = nil
            return
        }

        self.progressMessage = "Processing recording..."
        self.logger
            .debug(
                "Processing \(unprocessedParts.count) untranscribed segments, out of \(self.recordingParts.count) total segments"
            )

        // 处理录音
        await self.processRecordings()
    }

    public func setOutputDirectory(_ url: URL) {
        self.tunaSettings.transcriptionOutputDirectory = url
        self.logger.debug("Set output directory to \(url.path)")
    }

    public func setOutputFormat(_ format: String) {
        self.tunaSettings.transcriptionFormat = format
        self.logger.debug("Set output format to \(format)")
    }

    public func setApiKey(_ key: String) async {
        // 保存密钥到Keychain
        do {
            try self.secureStore.set(
                value: key.data(using: .utf8)!,
                forKey: SecureStore.defaultAccount,
                account: SecureStore.defaultAccount
            )
            self.logger.debug("API key updated and securely stored in Keychain")
            // 刷新UI状态
            self.notifierType.post(NSNotification.Name.dictationAPIKeyUpdated, object: nil)
        } catch {
            self.logger.error("Failed to save API key to Keychain: \(error.localizedDescription)")
            self.notifierType.post(NSNotification.Name.dictationAPIKeyMissing, object: nil)
        }
    }

    public func getDocumentsDirectory() -> URL {
        self.tunaSettings.transcriptionOutputDirectory ?? FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]
    }

    // 添加获取当前转录内容的方法，用于在用户编辑后比较差异
    public func getPreviousTranscription() async -> String? {
        await Task { @MainActor in self._transcribedText }.value
    }

    // MARK: - 获取当前设置

    // 获取当前输出格式
    public var outputFormat: String {
        self.tunaSettings.transcriptionFormat
    }

    // 获取当前输出目录
    public var outputDirectory: URL? {
        self.tunaSettings.transcriptionOutputDirectory
    }

    // MARK: - Private Methods

    private func setupRecordingSession() {
        #if os(iOS)
        // iOS版本 - 使用AVAudioSession
        // 检查麦克风权限
        let audioSession = AVAudioSession.sharedInstance()
        audioSession.requestRecordPermission { [weak self] allowed in
            guard let self else { return }

            Task { @MainActor in
                if !allowed {
                    self._progressMessage = "麦克风访问权限被拒绝"
                    self.logger.error("麦克风访问权限被拒绝")
                    return
                }

                self.logger.debug("麦克风访问权限已授予")
            }
        }
        #else
        // macOS版本 - 使用AVCaptureDevice
        if #available(macOS 10.14, *) {
            AVCaptureDevice.requestAccess(for: .audio) { [weak self] allowed in
                guard let self else { return }

                Task { @MainActor in
                    if !allowed {
                        self._progressMessage = "麦克风访问权限被拒绝"
                        self.logger.error("麦克风访问权限被拒绝")
                        return
                    }

                    self.logger.debug("麦克风访问权限已授予")
                }
            }
        } else {
            // 旧版macOS默认有权限
            self.logger.debug("macOS 10.14以下版本无法检查麦克风权限，默认继续")
        }
        #endif
    }

    private func processRecordings() async {
        guard !self.recordingParts.isEmpty else {
            var newState = self.state
            newState.state = .idle
            self.state = newState
            self.progressMessage = "No recording files"
            self.logger.warning("No recordings to process")
            return
        }

        // 过滤出未处理的片段
        let unprocessedParts = self.recordingParts.filter { !self.processedSegments.contains($0) }

        if unprocessedParts.isEmpty {
            // 所有片段都已转录，直接完成
            self.logger.debug("All segments already transcribed, skipping duplicate processing")
            await self.finalizeTranscription()

            // 清理
            self.recordingParts = []
            self.audioRecorder = nil
            return
        }

        self.logger
            .debug(
                "Processing \(unprocessedParts.count) untranscribed segments, out of \(self.recordingParts.count) total segments"
            )
        self.progressMessage = "Processing new recording parts..."

        // 如果只有一个未处理的片段，直接使用它
        if unprocessedParts.count == 1, let audioURL = unprocessedParts.first {
            await self.transcribeAudio(audioURL)
            return
        }

        // 使用递归函数处理未转录的片段
        await self.transcribeSegmentsSequentially(
            unprocessedParts,
            currentIndex: 0,
            accumulator: self.transcribedText
        )
    }

    // 依次处理多个录音片段
    private func transcribeSegmentsSequentially(
        _ segments: [URL],
        currentIndex: Int,
        accumulator: String
    ) async {
        // 基础情况：所有片段都已处理
        if currentIndex >= segments.count {
            // 全部处理完成，更新状态
            self.transcribedText = accumulator
            await self.finalizeTranscription()

            // 清理
            self.recordingParts = []
            self.audioRecorder = nil
            return
        }

        // 获取当前片段
        let currentSegment = segments[currentIndex]

        // 如果该片段已经被处理过，直接跳到下一个
        if self.processedSegments.contains(currentSegment) {
            self.logger.debug("片段已处理过，跳过: \(currentSegment.path)")
            await self.transcribeSegmentsSequentially(
                segments,
                currentIndex: currentIndex + 1,
                accumulator: accumulator
            )
            return
        }

        self.progressMessage = "Transcribing segment \(currentIndex + 1)/\(segments.count)..."
        self.logger
            .debug(
                "Transcribing segment \(currentIndex + 1)/\(segments.count): \(currentSegment.path)"
            )

        // 转录当前片段
        await self.callWhisperAPI(audioURL: currentSegment) { [weak self] result in
            guard let self else { return }

            Task { @MainActor in
                switch result {
                    case let .success(segmentText):
                        // 将当前片段的转录结果添加到累加器
                        var newAccumulator = accumulator
                        if !newAccumulator.isEmpty, !segmentText.isEmpty {
                            newAccumulator += "\n"
                        }
                        newAccumulator += segmentText

                        // 标记该片段已处理
                        self.processedSegments.insert(currentSegment)

                        // 递归处理下一个片段
                        Task {
                            await self.transcribeSegmentsSequentially(
                                segments,
                                currentIndex: currentIndex + 1,
                                accumulator: newAccumulator
                            )
                        }

                    case let .failure(error):
                        self.logger
                            .error(
                                "Failed to transcribe segment \(currentIndex + 1): \(error.localizedDescription)"
                            )

                        // 即使当前片段失败，也继续处理下一个片段
                        Task {
                            await self.transcribeSegmentsSequentially(
                                segments,
                                currentIndex: currentIndex + 1,
                                accumulator: accumulator
                            )
                        }
                }
            }
        }
    }

    @MainActor
    private func transcribeAudio(_ audioURL: URL) async {
        // 检查API密钥是否存在
        guard !self.apiKey.isEmpty else {
            self._state.state = .error(DictationError.noAPIKey)
            self._progressMessage = "Please set API key in settings"
            self.logger.error("API key not set")
            self.notifierType.post(NSNotification.Name.dictationAPIKeyMissing, object: nil)
            return
        }

        self._progressMessage = "Transcribing audio..."
        self.logger.debug("Transcribing audio from \(audioURL.path)")

        // 检查音频文件是否可读
        guard FileManager.default.fileExists(atPath: audioURL.path) else {
            self._state.state = .error(DictationError.audioFileReadError)
            self._progressMessage = "Cannot read audio file"
            self.logger.error("Failed to read audio file")
            return
        }

        // 调用Whisper API进行转录
        self.callWhisperAPI(audioURL: audioURL) { [weak self] result in
            guard let self else { return }

            Task { @MainActor in
                switch result {
                    case let .success(transcribedText):
                        // 设置转录文本，使用API返回的实际内容
                        self._transcribedText = transcribedText

                        // 标记该文件已处理
                        self.processedSegments.insert(audioURL)

                        // 继续处理下一个片段
                        await self.processRecordings()

                    case let .failure(error):
                        self
                            ._progressMessage =
                            "Transcription failed: \(error.localizedDescription)"
                        self.logger.error("Transcription failed: \(error.localizedDescription)")
                        self._state.state = .error(DictationError.transcriptionFailed(error))
                        self.notifierType.post(NSNotification.Name.dictationError, object: error)
                }
            }
        }
    }

    // 转录当前录音片段，但保持录音状态
    private func transcribeCurrentSegment(_ audioURL: URL) {
        // 检查API密钥是否存在
        guard !self.apiKey.isEmpty else {
            self._progressMessage = "Please set API key in settings"
            self.logger.error("API key not set")
            self._state.state = .error(DictationError.noAPIKey)

            // 发送通知，表示缺少API密钥
            Task { @MainActor in
                self.notifierType.post(NSNotification.Name.dictationAPIKeyMissing, object: nil)
            }
            return
        }

        self._progressMessage = "Transcribing current segment..."
        self.logger.debug("Transcribing current segment from \(audioURL.path)")

        // 检查音频文件是否可读
        guard FileManager.default.fileExists(atPath: audioURL.path) else {
            self._progressMessage = "Cannot read audio file"
            self.logger.error("Failed to read audio file")
            self._state.state = .error(DictationError.audioFileReadError)
            return
        }

        // 调用Whisper API转录当前片段
        self.callWhisperAPI(audioURL: audioURL) { [weak self] result in
            guard let self else { return }

            Task { @MainActor in
                switch result {
                    case let .success(segmentText):
                        // 追加转录文本，而不是替换
                        if self.transcribedText.isEmpty {
                            self.transcribedText = segmentText
                        } else {
                            // 先备份当前值，然后设置新值以确保UI更新
                            let newText = self.transcribedText + "\n" + segmentText
                            self.transcribedText = ""
                            self.transcribedText = newText
                        }

                        // 标记此片段已处理
                        self.processedSegments.insert(audioURL)

                        // 更新状态消息
                        self._progressMessage = "Paused - partial content transcribed"
                        self.logger.debug("Current segment transcribed successfully")

                        // 检查是否启用了自动复制功能，如果是则复制当前转录文本到剪贴板
                        if self.tunaSettings.autoCopyTranscriptionToClipboard {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(self.transcribedText, forType: .string)
                            self.logger.debug("Auto-copied transcription to clipboard")
                            self
                                ._progressMessage =
                                "Transcription completed and copied to clipboard"
                        }

                    case let .failure(error):
                        self
                            ._progressMessage =
                            "Partial transcription failed: \(error.localizedDescription)"
                        self.logger
                            .error("Segment transcription failed: \(error.localizedDescription)")
                        self._state.state = .error(DictationError.transcriptionFailed(error))
                        self.notifierType.post(NSNotification.Name.dictationError, object: error)
                }
            }
        }
    }

    // 调用OpenAI Whisper API
    private func callWhisperAPI(
        audioURL: URL,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        // 检查API密钥是否存在
        guard !self.apiKey.isEmpty else {
            completion(.failure(DictationError.noAPIKey))
            return
        }

        // 检查音频文件并获取文件大小
        guard let audioData = try? Data(contentsOf: audioURL) else {
            completion(.failure(DictationError.audioFileReadError))
            return
        }

        // 记录音频文件大小，用于调试
        let fileSizeBytes = audioData.count
        let fileSizeKB = Double(fileSizeBytes) / 1024.0
        self.logger.debug("Audio file size: \(fileSizeKB) KB")

        // 检查文件大小 - Whisper API对文件大小有限制
        if fileSizeBytes < 1024 { // 少于1KB，可能太小
            self.logger.warning("Audio file may be too small (\(fileSizeKB) KB)")
            // 仍然尝试发送，但记录警告
        }

        if fileSizeBytes > 25 * 1024 * 1024 { // 大于25MB
            completion(.failure(NSError(
                domain: "com.tuna.error",
                code: 413,
                userInfo: [
                    NSLocalizedDescriptionKey: "Audio file too large: \(fileSizeKB) KB, exceeds API limit",
                ]
            )))
            return
        }

        // 创建boundary用于multipart请求
        let boundary = "Boundary-\(UUID().uuidString)"

        // 设置API URL
        guard let url = URL(string: "https://api.openai.com/v1/audio/transcriptions") else {
            completion(.failure(NSError(
                domain: "com.tuna.error",
                code: 500,
                userInfo: [NSLocalizedDescriptionKey: "Invalid API URL"]
            )))
            return
        }

        // 创建请求
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(self.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue(
            "multipart/form-data; boundary=\(boundary)",
            forHTTPHeaderField: "Content-Type"
        )

        // 创建multipart请求体
        var body = Data()

        // 添加文件
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body
            .append(
                "Content-Disposition: form-data; name=\"file\"; filename=\"audio.wav\"\r\n"
                    .data(using: .utf8)!
            )
        body.append("Content-Type: audio/wav\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)

        // 添加模型参数
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("whisper-1\r\n".data(using: .utf8)!)

        // 添加语言参数（如果设置了）
        if !self.tunaSettings.transcriptionLanguage.isEmpty {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body
                .append(
                    "Content-Disposition: form-data; name=\"language\"\r\n\r\n"
                        .data(using: .utf8)!
                )
            body.append("\(self.tunaSettings.transcriptionLanguage)\r\n".data(using: .utf8)!)
        }

        // 添加格式参数
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body
            .append(
                "Content-Disposition: form-data; name=\"response_format\"\r\n\r\n"
                    .data(using: .utf8)!
            )
        body.append("text\r\n".data(using: .utf8)!)

        // 结束boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        // 创建任务
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self else { return }

            if let error {
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NSError(
                    domain: "com.tuna.error",
                    code: 500,
                    userInfo: [NSLocalizedDescriptionKey: "Invalid response type"]
                )))
                return
            }

            guard (200 ... 299).contains(httpResponse.statusCode) else {
                completion(.failure(NSError(
                    domain: "com.tuna.error",
                    code: httpResponse.statusCode,
                    userInfo: [
                        NSLocalizedDescriptionKey: "API request failed with status code: \(httpResponse.statusCode)",
                    ]
                )))
                return
            }

            guard let data else {
                completion(.failure(NSError(
                    domain: "com.tuna.error",
                    code: 500,
                    userInfo: [NSLocalizedDescriptionKey: "No data received"]
                )))
                return
            }

            // 解析响应
            if let transcribedText = String(data: data, encoding: .utf8) {
                completion(.success(
                    transcribedText
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                ))
            } else {
                completion(.failure(NSError(
                    domain: "com.tuna.error",
                    code: 500,
                    userInfo: [NSLocalizedDescriptionKey: "Failed to decode response"]
                )))
            }
        }

        task.resume()
    }

    // 计算文本中的单词数
    private func countWords(in text: String) -> Int {
        text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .count
    }

    // 替换原有的finalizeTranscription方法
    @MainActor
    func finalizeTranscription() async {
        self._state.state = .idle

        // 计算单词数
        let wordCount = self.countWords(in: self._transcribedText)

        // 发送完成通知，包含词数信息
        self.notifierType.post(NSNotification.Name.dictationFinished, object: nil)

        if self.transcribedText.isEmpty {
            self._progressMessage = "Transcription failed, no text result"
        } else {
            // 添加词数信息到进度消息
            self._progressMessage =
                "Transcription completed (\(wordCount) words) - click Save to save"

            // 检查是否启用了自动复制功能，如果是则复制到剪贴板
            if self.tunaSettings.autoCopyTranscriptionToClipboard {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(self.transcribedText, forType: .string)
                self.logger.debug("Auto-copied transcription to clipboard")
                self._progressMessage = "Transcription completed and copied to clipboard"
            }
        }

        self._state.breathingAnimation = false
        self.logger.debug("Completed transcription. Word count: \(wordCount)")
    }

    // 添加一个实用工具方法，用于发送通知
    private func sendDebugNotification(message: String) {
        print("📣 [DEBUG] DictationManager: \(message)")
        Task { @MainActor in
            self.notifierType.post(NSNotification.Name.dictationDebugMessage, object: nil)
        }
    }

    // 更新API密钥
    public func updateAPIKey(_ key: String) async {
        do {
            try self.secureStore.set(
                value: key.data(using: .utf8)!,
                forKey: SecureStore.defaultAccount,
                account: SecureStore.defaultAccount
            )
            self.notifierType.post(NSNotification.Name.dictationAPIKeyUpdated, object: nil)
        } catch {
            self.logger.error("Failed to save API key to Keychain: \(error.localizedDescription)")
            self.notifierType.post(NSNotification.Name.dictationAPIKeyMissing, object: nil)
        }
    }

    public func updateState(_ newState: DictationState) {
        self._state = newState
    }

    public func updateProgressMessage(_ message: String) {
        self._progressMessage = message
    }

    public func updateTranscribedText(_ text: String) {
        self._transcribedText = text
    }

    private func handlePlayPauseAction() async {
        let state = self.state.state
        switch state {
            case .idle:
                await self.startRecording()
            case .recording:
                await self.pauseRecording()
            case .paused:
                await self.continueRecording()
            case .processing:
                self.logger.notice("Cannot toggle - processing")
            case .error:
                print("\u{001B}[31m[ERROR]\u{001B}[0m 录音处于错误状态，尝试重置")
                var newState = self.state
                newState.state = .idle
                self.state = newState
        }
    }

    // 播放/暂停按钮图标
    public nonisolated var playPauseIconName: String {
        get async {
            await withCheckedContinuation { continuation in
                Task { @MainActor in
                    let icon = switch self._state.state {
                        case .idle, .paused:
                            "play.fill"
                        case .recording:
                            "pause.fill"
                        case .processing:
                            "hourglass"
                        case .error:
                            "exclamationmark.triangle.fill"
                    }
                    continuation.resume(returning: icon)
                }
            }
        }
    }

    // 状态文本
    public nonisolated var statusText: String {
        get async {
            await withCheckedContinuation { continuation in
                Task { @MainActor in
                    let text: String = if self._state.state == .recording {
                        "Listening..."
                    } else if !self._progressMessage.isEmpty {
                        self._progressMessage
                    } else if self._transcribedText.isEmpty,
                              self._state.state == .idle
                    {
                        "No recording files"
                    } else {
                        switch self._state.state {
                            case .idle:
                                "Ready to record"
                            case .recording:
                                "Recording..."
                            case .paused:
                                "Paused"
                            case .processing:
                                "Processing..."
                            case .error:
                                "Error"
                        }
                    }
                    continuation.resume(returning: text)
                }
            }
        }
    }

    public func startDictation() async {
        var newState = self.state
        newState.state = .recording
        self.state = newState
        // TODO: Implement actual dictation
    }

    public func stopDictation() async {
        var newState = self.state
        newState.state = .idle
        self.state = newState
        // TODO: Implement actual dictation stop
    }

    public func toggleDictation() async {
        if self.isRecording {
            await self.stopDictation()
        } else {
            await self.startDictation()
        }
    }

    public func showDictationWindow() async {
        // TODO: Implement window showing logic
        // This will be handled by the UI layer
    }
}

extension DictationManager: AVAudioRecorderDelegate {
    public nonisolated func audioRecorderDidFinishRecording(
        _ recorder: AVAudioRecorder,
        successfully flag: Bool
    ) {
        Task { @MainActor in
            if !flag {
                self.logger.error("Recording failed")
                self._state.state = .error(DictationError.recordingFailed)
                self.onStartFailure?()
            }
        }
    }

    public nonisolated func audioRecorderEncodeErrorDidOccur(
        _ recorder: AVAudioRecorder,
        error: Error?
    ) {
        Task { @MainActor in
            if let error {
                self.logger.error("Recording encode error: \(error.localizedDescription)")
                self._state.state = .error(DictationError.recordingFailed)
                self.onStartFailure?()
            }
        }
    }
}
