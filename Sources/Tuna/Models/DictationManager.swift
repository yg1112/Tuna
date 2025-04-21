import AVFoundation
import Combine
import Foundation
import os.log
import SwiftUI
import Speech

// import Views -- 已移至 Tuna 模块

// MARK: - DictationError
enum DictationError: LocalizedError {
    case invalidState(String)
    case recordingError(String)
    case transcriptionError(String)
    case audioSessionError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidState(let message): return "Invalid state: \(message)"
        case .recordingError(let message): return "Recording error: \(message)"
        case .transcriptionError(let message): return "Transcription error: \(message)"
        case .audioSessionError(let message): return "Audio session error: \(message)"
        }
    }
}

// 添加通知名称扩展
extension Notification.Name {
    static let dictationAPIKeyMissing = Notification.Name("dictationAPIKeyMissing")
    static let dictationAPIKeyUpdated = Notification.Name("dictationAPIKeyUpdated")
    static let dictationStarted = Notification.Name("dictationStarted")
    static let dictationStopped = Notification.Name("dictationStopped")
    static let dictationPaused = Notification.Name("dictationPaused")
    static let dictationResumed = Notification.Name("dictationResumed")
    static let dictationError = Notification.Name("dictationError")
    static let dictationCancelled = Notification.Name("dictationCancelled")
    static let dictationStateChanged = Notification.Name("dictationStateChanged")
}

// MARK: - DictationState
enum DictationState: Equatable {
    case idle
    case recording
    case paused
    case transcribing
    case error(String)
    
    static func == (lhs: DictationState, rhs: DictationState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle),
             (.recording, .recording),
             (.paused, .paused),
             (.transcribing, .transcribing):
            return true
        case (.error(let lhsError), .error(let rhsError)):
            return lhsError == rhsError
        default:
            return false
        }
    }
}

@MainActor
final class DictationManager: NSObject, ObservableObject, DictationManagerProtocol {
    static let shared = DictationManager()

    // 允许替换单例以便测试
    #if DEBUG
    static func createForTesting(nowProvider: NowProvider = RealNowProvider()) -> DictationManager {
        let manager = DictationManager(nowProvider: nowProvider)
        return manager
    }

    // 用于测试的重置方法
    public func reset() {
        self.state = .idle
        self.progressMessage = ""
        self.transcribedText = ""
        self.isRecording = false
        self.isPaused = false
        self.breathingAnimation = false
        self.recordingParts = []
        self.processedSegments = []
    }
    #endif

    private let logger = Logger(subsystem: "com.tuna.app", category: "DictationManager")
    private let tunaSettings = TunaSettings.shared
    private let nowProvider: NowProvider
    private let uuidProvider: UUIDProvider

    // 添加启动失败回调
    public var onStartFailure: (() -> Void)?

    // MARK: - Published Properties
    @Published private(set) var state: DictationState = .idle {
        didSet {
            NotificationCenter.default.post(name: .dictationStateChanged, object: nil)
        }
    }
    @Published private(set) var transcribedText: String = ""
    @Published private(set) var progressMessage: String = ""

    // UI相关的状态
    @Published public var isRecording: Bool {
        if case .recording = state {
            return true
        }
        return false
    }
    
    @Published public var isPaused: Bool {
        if case .paused = state {
            return true
        }
        return false
    }
    
    @Published public var breathingAnimation: Bool = false

    // MARK: - Private Properties
    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let audioSession = AVAudioSession.sharedInstance()
    private var recordingParts: Set<URL> = []
    private var processedSegments: Set<URL> = []
    private let fileManager = FileManager.default
    private let notificationCenter = NotificationCenter.default
    private var currentRecordingURL: URL?

    // 修改API密钥获取方式，使用SecureStore
    private var apiKey: String {
        SecureStore.currentAPIKey() ?? ""
    }

    // MARK: - Initialization
    override init() {
        self.nowProvider = RealNowProvider()
        self.uuidProvider = RealUUIDProvider()
        super.init()
        Task { @MainActor in
            do {
                try await setupAudioSession()
            } catch {
                state = .error(error.localizedDescription)
            }
        }
    }
    
    // MARK: - Deinitializer
    deinit {
        cleanup()
    }

    // MARK: - Private Methods
    private func cleanup() {
        audioEngine = nil
        recognitionRequest = nil
        recognitionTask = nil
        transcribedText = ""
    }
    
    private func setupAudioSession() async throws {
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            throw DictationError.audioSessionError("Failed to set up audio session: \(error.localizedDescription)")
        }
    }
    
    private func updateState(_ newState: DictationState) {
        state = newState
        switch newState {
        case .recording:
            notificationCenter.post(name: .dictationStarted, object: nil)
        case .paused:
            notificationCenter.post(name: .dictationPaused, object: nil)
        case .idle:
            notificationCenter.post(name: .dictationStopped, object: nil)
        case .error(_):
            notificationCenter.post(name: .dictationError, object: nil)
        default:
            break
        }
    }

    // MARK: - Public Methods

    // 添加toggle方法，根据当前状态切换录音状态
    public func toggle() async throws {
        switch state {
        case .idle:
            try await startRecording()
        case .recording:
            try await stopRecording()
        case .paused:
            try await startRecording()
        case .processing:
            logger.warning("Toggle called while processing - ignored")
        case .error:
            state = .idle
        }
    }

    public func resumeRecording() async throws {
        guard state == .paused else {
            throw DictationError.invalidState("Cannot resume in current state: \(state)")
        }
        
        do {
            try await setupAndStartRecording()
            updateState(.recording)
            notificationCenter.post(name: .dictationResumed, object: nil)
        } catch {
            updateState(.error(error.localizedDescription))
            throw error
        }
    }

    public func startRecording() async throws {
        guard state == .idle else {
            throw DictationError.invalidState("Cannot start recording in current state: \(state)")
        }
        
        do {
            try await setupAndStartRecording()
            updateState(.recording)
            notificationCenter.post(name: .dictationStarted, object: nil)
        } catch {
            updateState(.error(error.localizedDescription))
            throw error
        }
    }

    public func pauseRecording() async throws {
        guard state == .recording else {
            throw DictationError.invalidState("Cannot pause in current state: \(state)")
        }
        
        audioEngine?.pause()
        recognitionRequest?.endAudio()
        updateState(.paused)
        notificationCenter.post(name: .dictationPaused, object: nil)
    }

    public func stopRecording() async throws {
        guard state == .recording || state == .paused else {
            throw DictationError.invalidState("Cannot stop in current state: \(state)")
        }
        
        audioEngine?.stop()
        recognitionRequest?.endAudio()
        try? await audioSession.setActive(false)
        updateState(.idle)
        cleanup()
        notificationCenter.post(name: .dictationStopped, object: nil)
    }

    public func cancelRecording() {
        audioEngine?.stop()
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        try? audioSession.setActive(false)
        updateState(.idle)
        cleanup()
        notificationCenter.post(name: .dictationCancelled, object: nil)
    }

    public func setOutputDirectory(_ url: URL) {
        self.tunaSettings.transcriptionOutputDirectory = url
        self.logger.debug("Set output directory to \(url.path)")
    }

    public func setOutputFormat(_ format: String) {
        self.tunaSettings.transcriptionFormat = format
        self.logger.debug("Set output format to \(format)")
    }

    public func setApiKey(_ key: String) {
        // 保存密钥到Keychain
        do {
            try SecureStore.save(key: SecureStore.defaultAccount, value: key)
            self.logger.debug("API key updated and securely stored in Keychain")
            // 刷新UI状态
            NotificationCenter.default.post(name: .dictationAPIKeyUpdated, object: nil)
        } catch {
            self.logger.error("Failed to save API key to Keychain: \(error.localizedDescription)")
        }

        // 保持UserDefaults的向后兼容性，但只存储一个空字符串表示API密钥已设置
        // 不实际存储密钥内容
        if !key.isEmpty {
            UserDefaults.standard.set(" ", forKey: "dictationApiKey") // 只存储一个空格表示有密钥
        } else {
            UserDefaults.standard.removeObject(forKey: "dictationApiKey")
        }
    }

    public func getDocumentsDirectory() async -> URL {
        await MainActor.run {
            FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        }
    }

    // 添加获取当前转录内容的方法，用于在用户编辑后比较差异
    public func getPreviousTranscription() -> String? {
        self.transcribedText
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

    private func setupAndStartRecording() async throws {
        // Initialize audio engine and recognition request
        audioEngine = AVAudioEngine()
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let audioEngine = audioEngine,
              let recognitionRequest = recognitionRequest,
              let speechRecognizer = speechRecognizer,
              speechRecognizer.isAvailable else {
            throw DictationError.recordingError("Speech recognition is not available")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Configure audio session
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        // Install tap on input node
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        
        // Start audio engine
        audioEngine.prepare()
        try audioEngine.start()
        
        // Start recognition task
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                self.updateState(.error(error.localizedDescription))
                return
            }
            
            if let result = result {
                self.transcribedText = result.bestTranscription.formattedString
                
                if result.isFinal {
                    self.updateState(.idle)
                    self.cleanup()
                }
            }
        }
    }

    // MARK: - Speech Recognition Authorization
    func requestSpeechRecognitionAuthorization() async throws -> Bool {
        let status = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
        
        switch status {
        case .authorized:
            return true
        case .denied:
            throw DictationError.recordingError("Speech recognition authorization denied")
        case .restricted:
            throw DictationError.recordingError("Speech recognition is restricted on this device")
        case .notDetermined:
            throw DictationError.recordingError("Speech recognition authorization not determined")
        @unknown default:
            throw DictationError.recordingError("Unknown authorization status")
        }
    }

    // MARK: - Transcription Methods
    nonisolated private func transcribeAudio(at url: URL) async throws -> String {
        guard !apiKey.isEmpty else {
            await MainActor.run {
                NotificationCenter.default.post(name: .dictationAPIKeyMissing, object: nil)
            }
            throw DictationError.noAPIKey
        }
        
        do {
            let result = try await callWhisperAPI(with: url)
            await MainActor.run {
                transcribedText = result
                if tunaSettings.autoCopyToClipboard {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(result, forType: .string)
                }
            }
            return result
        } catch {
            await MainActor.run {
                progressMessage = "Transcription failed: \(error.localizedDescription)"
            }
            throw DictationError.transcriptionFailed(error.localizedDescription)
        }
    }
    
    nonisolated private func transcribeCurrentSegment() async throws {
        guard !apiKey.isEmpty else {
            await MainActor.run {
                NotificationCenter.default.post(name: .dictationAPIKeyMissing, object: nil)
            }
            throw DictationError.noAPIKey
        }
        
        guard let lastRecording = recordingParts.last,
              !processedSegments.contains(lastRecording) else {
            return
        }
        
        do {
            let result = try await callWhisperAPI(with: lastRecording)
            await MainActor.run {
                transcribedText += result + " "
                if tunaSettings.autoCopyToClipboard {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(transcribedText, forType: .string)
                }
                processedSegments.insert(lastRecording)
            }
        } catch {
            await MainActor.run {
                progressMessage = "Segment transcription failed: \(error.localizedDescription)"
            }
            throw DictationError.transcriptionFailed(error.localizedDescription)
        }
    }
    
    nonisolated private func callWhisperAPI(with audioFileURL: URL) async throws -> String {
        guard FileManager.default.fileExists(atPath: audioFileURL.path) else {
            throw DictationError.audioFileReadError
        }
        
        let fileSize = try FileManager.default.attributesOfItem(atPath: audioFileURL.path)[.size] as? Int64 ?? 0
        guard fileSize <= 25 * 1024 * 1024 else { // 25MB limit
            throw DictationError.transcriptionFailed("Audio file exceeds size limit")
        }
        
        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/audio/transcriptions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var data = Data()
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.m4a\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
        data.append(try Data(contentsOf: audioFileURL))
        data.append("\r\n".data(using: .utf8)!)
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        data.append("whisper-1\r\n".data(using: .utf8)!)
        data.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = data
        
        let (responseData, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            let errorMessage = String(data: responseData, encoding: .utf8) ?? "Unknown error"
            throw DictationError.transcriptionFailed(errorMessage)
        }
        
        struct WhisperResponse: Codable {
            let text: String
        }
        
        let decoder = JSONDecoder()
        let result = try decoder.decode(WhisperResponse.self, from: responseData)
        return result.text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // 计算文本中的单词数
    private func countWords(in text: String) -> Int {
        // 处理空文本
        if text.isEmpty {
            return 0
        }

        // 使用NSLinguisticTagger来进行更准确的单词分析
        let tagger = NSLinguisticTagger(tagSchemes: [.tokenType], options: 0)
        tagger.string = text

        // 只计算实际词语，忽略标点和空格
        let options: NSLinguisticTagger.Options = [.omitPunctuation, .omitWhitespace]
        let range = NSRange(location: 0, length: text.utf16.count)

        var wordCount = 0

        tagger
            .enumerateTags(in: range, scheme: .tokenType, options: options) { _, tokenRange, _, _ in
                wordCount += 1
            }

        return wordCount
    }

    // 替换原有的finalizeTranscription方法
    @MainActor
    func finalizeTranscription() {
        // 更新状态
        self.state = .idle

        // 计算单词数
        let wordCount = self.countWords(in: self.transcribedText)

        // 发送完成通知，包含词数信息
        NotificationCenter.default.post(
            name: NSNotification.Name("dictationFinished"),
            object: nil,
            userInfo: ["wordCount": wordCount]
        )

        if self.transcribedText.isEmpty {
            self.progressMessage = "Transcription failed, no text result"
        } else {
            // 添加词数信息到进度消息
            self.progressMessage =
                "Transcription completed (\(wordCount) words) - click Save to save"

            // 检查是否启用了自动复制功能，如果是则复制到剪贴板
            if TunaSettings.shared.autoCopyTranscriptionToClipboard, !self.transcribedText.isEmpty {
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString(self.transcribedText, forType: .string)
                self.logger.debug("Auto-copied transcription to clipboard")
                self.progressMessage =
                    "Transcription completed (\(wordCount) words) and copied to clipboard"
            }

            // Magic Transform 功能集成
            Task { await MagicTransformManager.shared.run(raw: self.transcribedText) }
        }

        self.breathingAnimation = false
        self.logger.debug("Completed transcription. Word count: \(wordCount)")
    }

    // 添加一个实用工具方法，用于发送通知
    private func sendDebugNotification(message: String) {
        print("📣 [DEBUG] DictationManager: \(message)")
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: NSNotification.Name("dictationDebugMessage"),
                object: nil,
                userInfo: ["message": message]
            )
        }
    }
}
