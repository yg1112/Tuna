import Foundation
import AVFoundation
import SwiftUI
import Combine
import os.log
// import Views -- 已移至 Tuna 模块

// 添加错误枚举
public enum DictationError: Error, LocalizedError {
    case noAPIKey
    case audioFileReadError
    case transcriptionFailed(Error)
    
    public var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "No API key provided. Please add your OpenAI API key in Settings."
        case .audioFileReadError:
            return "Could not read audio file."
        case .transcriptionFailed(let error):
            return "Transcription failed: \(error.localizedDescription)"
        }
    }
}

// 添加通知名称扩展
extension Notification.Name {
    static let dictationAPIKeyMissing = Notification.Name("dictationAPIKeyMissing")
    static let dictationAPIKeyUpdated = Notification.Name("dictationAPIKeyUpdated")
}

public class DictationManager: ObservableObject, DictationManagerProtocol {
    public static let shared = DictationManager()
    
    private let logger = Logger(subsystem: "com.tuna.app", category: "DictationManager")
    private let tunaSettings = TunaSettings.shared
    
    // 添加启动失败回调
    public var onStartFailure: (() -> Void)?
    
    // 状态和消息
    @Published public var state: DictationState = .idle {
        didSet {
            if oldValue != state {
                // 发送状态变更通知
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("dictationStateChanged"),
                        object: nil,
                        userInfo: ["state": self.state]
                    )
                }
                
                // 根据状态自动更新UI状态变量
                switch state {
                case .recording:
                    isRecording = true
                    isPaused = false
                case .paused:
                    isRecording = true
                    isPaused = true 
                case .idle, .error, .processing:
                    isRecording = false
                    isPaused = false
                }
                
                // 记录状态变更
                logger.debug("Dictation state changed from \(String(describing: oldValue)) to \(String(describing: self.state))")
            }
        }
    }
    @Published public var progressMessage: String = ""
    @Published public var transcribedText: String = ""
    
    // UI相关的状态
    @Published public var isRecording: Bool = false
    @Published public var isPaused: Bool = false
    @Published public var breathingAnimation: Bool = false
    
    // 录音相关
    private var audioRecorder: AVAudioRecorder?
    private var recordingURL: URL?
    private var tempDirectory: URL?
    private var recordingParts: [URL] = []
    // 跟踪已转录的片段
    private var processedSegments: Set<URL> = []
    
    // 修改API密钥获取方式，使用SecureStore
    private var apiKey: String {
        SecureStore.currentAPIKey() ?? ""
    }
    
    private init() {
        logger.debug("DictationManager initialized")
        
        // 创建临时目录用于处理音频文件
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("tuna_dictation", isDirectory: true)
        
        do {
            try FileManager.default.createDirectory(at: tempDirectory!, withIntermediateDirectories: true)
        } catch {
            logger.error("Failed to create temp directory: \(error.localizedDescription)")
        }
        
        setupRecordingSession()
    }
    
    // MARK: - Public Methods
    
    // 添加toggle方法，根据当前状态切换录音状态
    public func toggle() {
        switch state {
        case .idle:
            startRecording()
        case .recording:
            stopRecording()
        case .paused:
            resumeRecording()
        case .processing, .error:
            // 这些状态下不做任何操作
            logger.warning("Toggle called while in processing or error state - ignored")
            break
        }
    }
    
    public func resumeRecording() {
        if state == .paused {
            continueRecording()
        }
    }
    
    public func startRecording() {
        logger.notice("开始录音...")
        
        // 如果已经在录音，直接返回
        if isRecording {
            logger.notice("已经在录音中，忽略请求")
            return
        }
        
        progressMessage = "准备录音..."
        
#if os(iOS)
        // 检查麦克风权限 - iOS版本
        let audioSession = AVAudioSession.sharedInstance()
        switch audioSession.recordPermission {
        case .denied:
            logger.error("麦克风权限被拒绝")
            progressMessage = "麦克风权限被拒绝，请在设置中允许访问麦克风"
            onStartFailure?()
            return
            
        case .undetermined:
            logger.notice("麦克风权限未确定，请求权限")
            audioSession.requestRecordPermission { [weak self] allowed in
                guard let self = self else { return }
                if !allowed {
                    logger.error("用户拒绝了麦克风权限")
                    self.progressMessage = "麦克风权限被拒绝，请在设置中允许访问麦克风"
                    self.onStartFailure?()
                    return
                }
                // 权限获取成功，继续录音流程
                DispatchQueue.main.async {
                    self.continueRecording()
                }
            }
            return
            
        case .granted:
            logger.notice("麦克风权限已获取")
            // 继续录音流程
        @unknown default:
            logger.error("未知的麦克风权限状态")
            progressMessage = "未知的麦克风权限状态"
            onStartFailure?()
            return
        }
#else
        // macOS版本 - 使用AVCaptureDevice检查权限
        if #available(macOS 10.14, *) {
            switch AVCaptureDevice.authorizationStatus(for: .audio) {
            case .denied, .restricted:
                logger.error("麦克风权限被拒绝或受限")
                progressMessage = "麦克风权限被拒绝，请在系统偏好设置中允许访问麦克风"
                onStartFailure?()
                return
                
            case .notDetermined:
                logger.notice("麦克风权限未确定，请求权限")
                AVCaptureDevice.requestAccess(for: .audio) { [weak self] allowed in
                    guard let self = self else { return }
                    if !allowed {
                        logger.error("用户拒绝了麦克风权限")
                        self.progressMessage = "麦克风权限被拒绝，请在系统偏好设置中允许访问麦克风"
                        self.onStartFailure?()
                        return
                    }
                    // 权限获取成功，继续录音流程
                    DispatchQueue.main.async {
                        self.continueRecording()
                    }
                }
                return
                
            case .authorized:
                logger.notice("麦克风权限已获取")
                // 继续录音流程
            @unknown default:
                logger.error("未知的麦克风权限状态")
                progressMessage = "未知的麦克风权限状态"
                onStartFailure?()
                return
            }
        } else {
            // 旧版macOS默认有权限，但记录日志
            logger.notice("macOS 10.14以下版本无法检查麦克风权限，默认继续")
        }
#endif

        continueRecording()
    }
    
    private func continueRecording() {
        Logger(subsystem:"ai.tuna",category:"Shortcut").notice("[R] startRecording() actually called")
        
        // 确保我们处于正确的状态
        guard state == .idle || state == .paused else {
            logger.warning("Cannot start recording - wrong state")
            return
        }
        
        // 如果处于暂停状态，创建新的录音片段
        if state == .paused && audioRecorder != nil {
            // 保存已有的audioRecorder用于清理
            let oldRecorder = audioRecorder
            
            // 创建新的录音文件
            let fileName = "dictation_\(Date().timeIntervalSince1970).wav"
            recordingURL = tempDirectory?.appendingPathComponent(fileName)
            
            guard let recordingURL = recordingURL else {
                logger.error("Failed to create recording URL")
                progressMessage = "⚠️ 无法创建录音文件"
                onStartFailure?()
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
                AVLinearPCMIsFloatKey: false
            ]
            
            do {
                audioRecorder = try AVAudioRecorder(url: recordingURL, settings: settings)
                audioRecorder?.delegate = nil
                audioRecorder?.record()
                
                // 添加到录音部分列表
                recordingParts.append(recordingURL)
                
                // 停止并释放旧的录音器
                oldRecorder?.stop()
                
                // 更新状态
                DispatchQueue.main.async {
                    self.state = .recording
                    self.progressMessage = "🎙 正在录音..."
                    
                    // 触发UI更新
                    let current = self.transcribedText
                    self.transcribedText = ""
                    self.transcribedText = current
                }
                
                logger.debug("Created new recording segment at \(recordingURL.path)")
                logger.notice("state -> recording (continue)")
            } catch {
                logger.error("Failed to continue recording: \(error.localizedDescription)")
                progressMessage = "⚠️ 录音失败: \(error.localizedDescription)"
                
                // 恢复旧的录音器状态
                audioRecorder = oldRecorder
                onStartFailure?()
            }
            
            return
        }
        
        // 如果不是从暂停状态继续，则清除已有的转录内容并开始新录音
        if state == .idle {
            // 清除转录文本以开始新录音
            transcribedText = ""
            recordingParts = []
            processedSegments = [] // 重置已处理片段记录
        }
        
        // 创建新的录音文件
        let fileName = "dictation_\(Date().timeIntervalSince1970).wav"
        recordingURL = tempDirectory?.appendingPathComponent(fileName)
        
        guard let recordingURL = recordingURL else {
            logger.error("Failed to create recording URL")
            progressMessage = "⚠️ 无法创建录音文件"
            onStartFailure?()
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
            AVLinearPCMIsFloatKey: false
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: recordingURL, settings: settings)
            audioRecorder?.delegate = nil
            audioRecorder?.record()
            
            // 添加到录音部分列表
            recordingParts.append(recordingURL)
            
            state = .recording
            progressMessage = "🎙 正在录音..."
            logger.debug("Started new recording at \(recordingURL.path)")
            logger.notice("state -> recording (new)")
        } catch {
            logger.error("Failed to start recording: \(error.localizedDescription)")
            progressMessage = "⚠️ 录音失败: \(error.localizedDescription)"
            onStartFailure?()
        }
    }
    
    public func pauseRecording() {
        guard state == .recording, let audioRecorder = audioRecorder else {
            logger.warning("Cannot pause - not recording or recorder is nil")
            return
        }
        
        // 暂停录音并确保文件被正确写入
        audioRecorder.pause()
        
        // 重要：等待一小段时间确保文件被正确写入
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            
            self.state = .paused
            self.progressMessage = "Recording paused, processing..."
            self.logger.debug("Recording paused, preparing to transcribe current segment")
            
            // 获取当前录音文件并转录
            if let currentRecordingURL = self.recordingURL, FileManager.default.fileExists(atPath: currentRecordingURL.path) {
                // 验证文件大小
                do {
                    let fileAttributes = try FileManager.default.attributesOfItem(atPath: currentRecordingURL.path)
                    if let fileSize = fileAttributes[.size] as? Int {
                        let fileSizeKB = Double(fileSize) / 1024.0
                        self.logger.debug("Recording file size when paused: \(fileSizeKB) KB")
                        
                        if fileSize < 500 { // 少于500字节可能不是有效音频
                            self.progressMessage = "Recording paused (segment too short to transcribe)"
                            self.logger.warning("Recording segment too short, skipping transcription")
                            return
                        }
                    }
                } catch {
                    self.logger.error("Cannot get file attributes: \(error.localizedDescription)")
                }
                
                // 临时保存当前URL以便继续录音
                let currentURL = self.recordingURL
                
                // 转录当前片段
                self.transcribeCurrentSegment(currentURL!)
            }
        }
    }
    
    public func stopRecording() {
        guard (state == .recording || state == .paused), let audioRecorder = audioRecorder else {
            logger.warning("Cannot stop - not recording/paused or recorder is nil")
            return
        }
        
        audioRecorder.stop()
        state = .processing
        
        // 检查是否所有片段都已处理
        let unprocessedParts = self.recordingParts.filter { !self.processedSegments.contains($0) }
        
        if unprocessedParts.isEmpty {
            logger.debug("Recording stopped - all segments already transcribed")
            progressMessage = "Processing complete, all content transcribed"
            finalizeTranscription()
            
            // 清理
            recordingParts = []
            self.audioRecorder = nil
            return
        }
        
        progressMessage = "Processing recording..."
        logger.debug("Recording stopped, processing started (with \(unprocessedParts.count) unprocessed segments)")
        
        // 处理录音
        processRecordings()
    }
    
    public func setOutputDirectory(_ url: URL) {
        tunaSettings.transcriptionOutputDirectory = url
        logger.debug("Set output directory to \(url.path)")
    }
    
    public func setOutputFormat(_ format: String) {
        tunaSettings.transcriptionFormat = format
        logger.debug("Set output format to \(format)")
    }
    
    public func setApiKey(_ key: String) {
        // 保存密钥到Keychain
        do {
            try SecureStore.save(key: SecureStore.defaultAccount, value: key)
            logger.debug("API key updated and securely stored in Keychain")
            // 刷新UI状态
            NotificationCenter.default.post(name: .dictationAPIKeyUpdated, object: nil)
        } catch {
            logger.error("Failed to save API key to Keychain: \(error.localizedDescription)")
        }
        
        // 保持UserDefaults的向后兼容性，但只存储一个空字符串表示API密钥已设置
        // 不实际存储密钥内容
        if !key.isEmpty {
            UserDefaults.standard.set(" ", forKey: "dictationApiKey") // 只存储一个空格表示有密钥
        } else {
            UserDefaults.standard.removeObject(forKey: "dictationApiKey")
        }
    }
    
    public func getDocumentsDirectory() -> URL {
        return tunaSettings.transcriptionOutputDirectory ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    // 添加获取当前转录内容的方法，用于在用户编辑后比较差异
    public func getPreviousTranscription() -> String? {
        return self.transcribedText
    }
    
    // MARK: - 获取当前设置
    
    // 获取当前输出格式
    public var outputFormat: String {
        return tunaSettings.transcriptionFormat
    }
    
    // 获取当前输出目录
    public var outputDirectory: URL? {
        return tunaSettings.transcriptionOutputDirectory
    }
    
    // MARK: - Private Methods
    
    private func setupRecordingSession() {
#if os(iOS)
        // iOS版本 - 使用AVAudioSession
        // 检查麦克风权限
        let audioSession = AVAudioSession.sharedInstance()
        audioSession.requestRecordPermission { [weak self] allowed in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if !allowed {
                    self.progressMessage = "麦克风访问权限被拒绝"
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
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    if !allowed {
                        self.progressMessage = "麦克风访问权限被拒绝"
                        self.logger.error("麦克风访问权限被拒绝")
                        return
                    }
                    
                    self.logger.debug("麦克风访问权限已授予")
                }
            }
        } else {
            // 旧版macOS默认有权限
            logger.debug("macOS 10.14以下版本无法检查麦克风权限，默认继续")
        }
#endif
    }
    
    private func processRecordings() {
        guard !self.recordingParts.isEmpty else {
            state = .idle
            progressMessage = "No recording files"
            logger.warning("No recordings to process")
            return
        }
        
        // 过滤出未处理的片段
        let unprocessedParts = self.recordingParts.filter { !self.processedSegments.contains($0) }
        
        if unprocessedParts.isEmpty {
            // 所有片段都已转录，直接完成
            logger.debug("All segments already transcribed, skipping duplicate processing")
            finalizeTranscription()
            
            // 清理
            self.recordingParts = []
            self.audioRecorder = nil
            return
        }
        
        logger.debug("Processing \(unprocessedParts.count) untranscribed segments, out of \(self.recordingParts.count) total segments")
        progressMessage = "Processing new recording parts..."
        
        // 如果只有一个未处理的片段，直接使用它
        if unprocessedParts.count == 1, let audioURL = unprocessedParts.first {
            transcribeAudio(audioURL)
            return
        }
        
        // 使用递归函数处理未转录的片段
        transcribeSegmentsSequentially(unprocessedParts, currentIndex: 0, accumulator: self.transcribedText)
    }
    
    // 依次处理多个录音片段
    private func transcribeSegmentsSequentially(_ segments: [URL], currentIndex: Int, accumulator: String) {
        // 基础情况：所有片段都已处理
        if currentIndex >= segments.count {
            // 全部处理完成，更新状态
            self.transcribedText = accumulator
            finalizeTranscription()
            
            // 清理
            self.recordingParts = []
            self.audioRecorder = nil
            return
        }
        
        // 获取当前片段
        let currentSegment = segments[currentIndex]
        
        // 如果该片段已经被处理过，直接跳到下一个
        if self.processedSegments.contains(currentSegment) {
            logger.debug("片段已处理过，跳过: \(currentSegment.path)")
            transcribeSegmentsSequentially(segments, currentIndex: currentIndex + 1, accumulator: accumulator)
            return
        }
        
        progressMessage = "Transcribing segment \(currentIndex + 1)/\(segments.count)..."
        logger.debug("Transcribing segment \(currentIndex + 1)/\(segments.count): \(currentSegment.path)")
        
        // 转录当前片段
        callWhisperAPI(audioURL: currentSegment) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success(let segmentText):
                    // 将当前片段的转录结果添加到累加器
                    var newAccumulator = accumulator
                    if !newAccumulator.isEmpty && !segmentText.isEmpty {
                        newAccumulator += "\n"
                    }
                    newAccumulator += segmentText
                    
                    // 标记该片段已处理
                    self.processedSegments.insert(currentSegment)
                    
                    // 递归处理下一个片段
                    self.transcribeSegmentsSequentially(segments, currentIndex: currentIndex + 1, accumulator: newAccumulator)
                    
                case .failure(let error):
                    self.logger.error("Failed to transcribe segment \(currentIndex + 1): \(error.localizedDescription)")
                    
                    // 即使当前片段失败，也继续处理下一个片段
                    self.transcribeSegmentsSequentially(segments, currentIndex: currentIndex + 1, accumulator: accumulator)
                }
            }
        }
    }
    
    private func transcribeAudio(_ audioURL: URL) {
        // 检查API密钥是否存在
        guard !apiKey.isEmpty else {
            state = .idle
            progressMessage = "Please set API key in settings"
            logger.error("API key not set")
            
            // 发送通知，表示缺少API密钥
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .dictationAPIKeyMissing,
                    object: nil
                )
            }
            return
        }
        
        // 如果已经处理过此文件，跳过重复转录
        if processedSegments.contains(audioURL) {
            logger.debug("文件已转录过，跳过: \(audioURL.path)")
            finalizeTranscription()
            
            // 清理
            self.recordingParts = []
            self.audioRecorder = nil
            return
        }
        
        progressMessage = "Transcribing audio..."
        logger.debug("Transcribing audio from \(audioURL.path)")
        
        // 检查音频文件是否可读
        guard FileManager.default.fileExists(atPath: audioURL.path) else {
            state = .idle
            progressMessage = "Cannot read audio file"
            logger.error("Failed to read audio file")
            return
        }
        
        // 调用Whisper API
        callWhisperAPI(audioURL: audioURL) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success(let transcribedText):
                    // 设置转录文本，使用API返回的实际内容
                    self.transcribedText = transcribedText
                    
                    // 标记该文件已处理
                    self.processedSegments.insert(audioURL)
                    
                    // 更新状态并设置消息
                    self.finalizeTranscription()
                    self.logger.debug("Transcription completed successfully")
                    
                case .failure(let error):
                    self.progressMessage = "Transcription failed: \(error.localizedDescription)"
                    self.logger.error("Transcription failed: \(error.localizedDescription)")
                    self.state = .idle
                }
                
                // 清理
                self.recordingParts = []
                self.audioRecorder = nil
            }
        }
    }
    
    // 转录当前录音片段，但保持录音状态
    private func transcribeCurrentSegment(_ audioURL: URL) {
        // 检查API密钥是否存在
        guard !apiKey.isEmpty else {
            progressMessage = "Please set API key in settings"
            logger.error("API key not set")
            
            // 发送通知，表示缺少API密钥
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .dictationAPIKeyMissing,
                    object: nil
                )
            }
            return
        }
        
        progressMessage = "Transcribing current segment..."
        logger.debug("Transcribing current segment from \(audioURL.path)")
        
        // 检查音频文件是否可读
        guard FileManager.default.fileExists(atPath: audioURL.path) else {
            progressMessage = "Cannot read audio file"
            logger.error("Failed to read audio file")
            return
        }
        
        // 调用Whisper API转录当前片段
        callWhisperAPI(audioURL: audioURL) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success(let segmentText):
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
                    self.progressMessage = "Paused - partial content transcribed"
                    self.logger.debug("Current segment transcribed successfully")
                    
                    // 检查是否启用了自动复制功能，如果是则复制当前转录文本到剪贴板
                    if self.tunaSettings.autoCopyTranscriptionToClipboard && !self.transcribedText.isEmpty {
                        let pasteboard = NSPasteboard.general
                        pasteboard.clearContents()
                        pasteboard.setString(self.transcribedText, forType: .string)
                        self.logger.debug("Auto-copied segment transcription to clipboard")
                        self.progressMessage = "Paused - content transcribed and copied"
                    }
                    
                case .failure(let error):
                    self.progressMessage = "Partial transcription failed: \(error.localizedDescription)"
                    self.logger.error("Segment transcription failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // 调用OpenAI Whisper API
    private func callWhisperAPI(audioURL: URL, completion: @escaping (Result<String, Error>) -> Void) {
        // 检查API密钥
        guard !apiKey.isEmpty else {
            completion(.failure(DictationError.noAPIKey))
            
            // 发送通知，表示缺少API密钥
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .dictationAPIKeyMissing,
                    object: nil
                )
            }
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
        logger.debug("Audio file size: \(fileSizeKB) KB")
        
        // 检查文件大小 - Whisper API对文件大小有限制
        if fileSizeBytes < 1024 { // 少于1KB，可能太小
            logger.warning("Audio file may be too small (\(fileSizeKB) KB)")
            // 仍然尝试发送，但记录警告
        }
        
        if fileSizeBytes > 25 * 1024 * 1024 { // 大于25MB
            completion(.failure(NSError(domain: "com.tuna.error", code: 413, userInfo: [NSLocalizedDescriptionKey: "Audio file too large: \(fileSizeKB) KB, exceeds API limit"])))
            return
        }
        
        // 创建boundary用于multipart请求
        let boundary = "Boundary-\(UUID().uuidString)"
        
        // 设置API URL
        guard let url = URL(string: "https://api.openai.com/v1/audio/transcriptions") else {
            completion(.failure(NSError(domain: "com.tuna.error", code: 500, userInfo: [NSLocalizedDescriptionKey: "Invalid API URL"])))
            return
        }
        
        // 创建请求
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // 创建请求体
        var httpBody = Data()
        
        // 添加模型
        httpBody.append("--\(boundary)\r\n".data(using: .utf8)!)
        httpBody.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        httpBody.append("whisper-1\r\n".data(using: .utf8)!)
        
        // 添加文件
        httpBody.append("--\(boundary)\r\n".data(using: .utf8)!)
        httpBody.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.wav\"\r\n".data(using: .utf8)!)
        httpBody.append("Content-Type: audio/wav\r\n\r\n".data(using: .utf8)!)
        httpBody.append(audioData)
        httpBody.append("\r\n".data(using: .utf8)!)
        
        // 添加响应格式
        httpBody.append("--\(boundary)\r\n".data(using: .utf8)!)
        httpBody.append("Content-Disposition: form-data; name=\"response_format\"\r\n\r\n".data(using: .utf8)!)
        httpBody.append("json\r\n".data(using: .utf8)!)
        
        // 如果用户指定了语言，则添加language参数，否则让API自动检测
        let selectedLanguage = TunaSettings.shared.transcriptionLanguage
        if !selectedLanguage.isEmpty {
            httpBody.append("--\(boundary)\r\n".data(using: .utf8)!)
            httpBody.append("Content-Disposition: form-data; name=\"language\"\r\n\r\n".data(using: .utf8)!)
            httpBody.append("\(selectedLanguage)\r\n".data(using: .utf8)!)
            logger.debug("Using specified language for transcription: \(selectedLanguage)")
        } else {
            // 不指定语言，让API自动检测
            // Whisper API会根据音频内容自动检测语言
            logger.debug("Using automatic language detection for transcription")
        }
        
        // 添加温度参数（可以调整模型输出的随机性）
        httpBody.append("--\(boundary)\r\n".data(using: .utf8)!)
        httpBody.append("Content-Disposition: form-data; name=\"temperature\"\r\n\r\n".data(using: .utf8)!)
        httpBody.append("0.0\r\n".data(using: .utf8)!) // 使用最低温度，最确定的转录
        
        // 结束boundary
        httpBody.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        // 设置请求体
        request.httpBody = httpBody
        
        // 记录请求详情用于调试
        logger.debug("API request total size: \(httpBody.count) bytes")
        logger.debug("Audio file URL: \(audioURL.path)")
        
        // 发送请求
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                self.logger.error("Network error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                self.logger.error("Invalid HTTP response")
                completion(.failure(NSError(domain: "com.tuna.error", code: 500, userInfo: [NSLocalizedDescriptionKey: "Invalid HTTP response"])))
                return
            }
            
            // 记录响应状态码
            self.logger.debug("API response status code: \(httpResponse.statusCode)")
            
            // 检查状态码
            if httpResponse.statusCode != 200 {
                var errorMessage = "API error: Status code \(httpResponse.statusCode)"
                
                if let data = data {
                    // 尝试解析详细错误信息
                    if let responseString = String(data: data, encoding: .utf8) {
                        self.logger.error("API error response: \(responseString)")
                        errorMessage = "API error(\(httpResponse.statusCode)): \(responseString)"
                        
                        // 尝试解析为JSON获取更详细的错误
                        if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let errorObject = errorJson["error"] as? [String: Any],
                           let errorMessage = errorObject["message"] as? String {
                            self.logger.error("API error details: \(errorMessage)")
                            completion(.failure(NSError(domain: "com.tuna.error", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "API error: \(errorMessage)"])))
                            return
                        }
                    }
                }
                
                // 若无法解析详细错误，返回基本错误
                completion(.failure(NSError(domain: "com.tuna.error", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])))
                return
            }
            
            // 解析响应
            guard let data = data else {
                self.logger.error("API did not return data")
                completion(.failure(NSError(domain: "com.tuna.error", code: 500, userInfo: [NSLocalizedDescriptionKey: "No data returned"])))
                return
            }
            
            do {
                if let responseString = String(data: data, encoding: .utf8) {
                    self.logger.debug("API raw response: \(responseString)")
                }
                
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let text = json["text"] as? String {
                    self.logger.debug("API returned transcription: \(text)")
                    completion(.success(text))
                } else {
                    self.logger.error("Could not parse API response to expected format")
                    completion(.failure(NSError(domain: "com.tuna.error", code: 500, userInfo: [NSLocalizedDescriptionKey: "Could not parse API response"])))
                }
            } catch {
                self.logger.error("Failed to parse API response: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
        
        // 启动任务
        task.resume()
        
        logger.debug("API request sent")
    }
    
    // 设置录音中状态为处理中
    func finalizeTranscription() {
        state = .idle
        if transcribedText.isEmpty {
            progressMessage = "Transcription failed, no text result"
        } else {
            progressMessage = "Transcription completed - click Save to save"
            
            // 检查是否启用了自动复制功能，如果是则复制到剪贴板
            if TunaSettings.shared.autoCopyTranscriptionToClipboard && !transcribedText.isEmpty {
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString(transcribedText, forType: .string)
                logger.debug("Auto-copied transcription to clipboard")
                progressMessage = "Transcription completed and copied to clipboard"
            }
        }
    }
} 