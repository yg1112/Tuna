import Foundation
import AVFoundation
import SwiftUI
import Combine
import os.log
import Views

public class DictationManager: ObservableObject, DictationManagerProtocol {
    public static let shared = DictationManager()
    
    private let logger = Logger(subsystem: "com.tuna.app", category: "DictationManager")
    
    // 状态和消息
    @Published public var state: DictationState = .idle
    @Published public var progressMessage: String = ""
    @Published public var transcribedText: String = ""
    
    // 录音相关
    private var audioRecorder: AVAudioRecorder?
    private var recordingURL: URL?
    private var tempDirectory: URL?
    private var recordingParts: [URL] = []
    
    // 设置
    private var apiKey: String = UserDefaults.standard.string(forKey: "dictationApiKey") ?? ""
    public var outputFormat: String = UserDefaults.standard.string(forKey: "dictationFormat") ?? "txt"
    private var outputDirectory: URL? = UserDefaults.standard.url(forKey: "dictationOutputDirectory")
    
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
    
    public func startRecording() {
        guard state != .recording && state != .processing else {
            logger.warning("Cannot start recording while already recording or processing")
            return
        }
        
        setupRecordingSession()
        
        if state == .paused && audioRecorder != nil {
            // 继续录音
            audioRecorder?.record()
            state = .recording
            progressMessage = "继续录音..."
            logger.debug("Resumed recording")
            return
        }
        
        // 创建新的录音文件
        let fileName = "dictation_\(Date().timeIntervalSince1970).m4a"
        recordingURL = tempDirectory?.appendingPathComponent(fileName)
        
        guard let recordingURL = recordingURL else {
            logger.error("Failed to create recording URL")
            progressMessage = "无法创建录音文件"
            return
        }
        
        // 设置录音参数
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: recordingURL, settings: settings)
            audioRecorder?.delegate = nil
            audioRecorder?.record()
            
            // 添加到录音部分列表
            recordingParts.append(recordingURL)
            
            state = .recording
            progressMessage = "正在录音..."
            logger.debug("Started new recording at \(recordingURL.path)")
        } catch {
            logger.error("Failed to start recording: \(error.localizedDescription)")
            progressMessage = "开始录音失败: \(error.localizedDescription)"
        }
    }
    
    public func pauseRecording() {
        guard state == .recording, let audioRecorder = audioRecorder else {
            logger.warning("Cannot pause - not recording or recorder is nil")
            return
        }
        
        audioRecorder.pause()
        state = .paused
        progressMessage = "录音已暂停"
        logger.debug("Recording paused")
    }
    
    public func stopRecording() {
        guard (state == .recording || state == .paused), let audioRecorder = audioRecorder else {
            logger.warning("Cannot stop - not recording/paused or recorder is nil")
            return
        }
        
        audioRecorder.stop()
        state = .processing
        progressMessage = "正在处理录音..."
        logger.debug("Recording stopped, processing started")
        
        // 处理录音
        processRecordings()
    }
    
    public func setOutputDirectory(_ url: URL) {
        outputDirectory = url
        UserDefaults.standard.set(url, forKey: "dictationOutputDirectory")
        logger.debug("Set output directory to \(url.path)")
    }
    
    public func setOutputFormat(_ format: String) {
        outputFormat = format
        UserDefaults.standard.set(format, forKey: "dictationFormat")
        logger.debug("Set output format to \(format)")
    }
    
    public func setApiKey(_ key: String) {
        apiKey = key
        UserDefaults.standard.set(key, forKey: "dictationApiKey")
        logger.debug("API key updated")
    }
    
    public func getDocumentsDirectory() -> URL {
        return outputDirectory ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    // MARK: - Private Methods
    
    private func setupRecordingSession() {
        // 检查麦克风权限
        AVCaptureDevice.requestAccess(for: .audio) { [weak self] allowed in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if !allowed {
                    self.progressMessage = "需要麦克风访问权限"
                    self.logger.error("Microphone access denied")
                    return
                }
                
                self.logger.debug("Microphone access granted")
            }
        }
    }
    
    private func processRecordings() {
        guard !self.recordingParts.isEmpty else {
            state = .idle
            progressMessage = "没有录音文件"
            logger.warning("No recordings to process")
            return
        }
        
        // 如果只有一个录音部分，直接使用它
        if self.recordingParts.count == 1, let audioURL = self.recordingParts.first {
            transcribeAudio(audioURL)
            return
        }
        
        // 如果有多个录音部分，需要合并它们
        logger.debug("Merging \(self.recordingParts.count) recording parts")
        progressMessage = "合并录音部分..."
        
        // 这里应该是合并音频文件的代码
        // 由于合并音频需要额外的处理，我们先使用第一个部分进行转录
        // 实际应用中应该实现音频文件的合并
        logger.warning("Audio merging not implemented, using first recording part")
        transcribeAudio(self.recordingParts.first!)
    }
    
    private func transcribeAudio(_ audioURL: URL) {
        guard !apiKey.isEmpty else {
            state = .idle
            progressMessage = "请在设置中设置API密钥"
            logger.error("API key not set")
            return
        }
        
        progressMessage = "正在转录音频..."
        logger.debug("Transcribing audio from \(audioURL.path)")
        
        // 检查音频文件是否可读
        guard FileManager.default.fileExists(atPath: audioURL.path) else {
            state = .idle
            progressMessage = "无法读取音频文件"
            logger.error("Failed to read audio file")
            return
        }
        
        // 调用Whisper API
        callWhisperAPI(audioURL: audioURL) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success(let transcribedText):
                    // 创建输出文件
                    let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .medium)
                            .replacingOccurrences(of: "/", with: "-")
                            .replacingOccurrences(of: ":", with: "-")
                    let outputFileName = "dictation_\(timestamp).\(self.outputFormat)"
                    let outputURL = self.getDocumentsDirectory().appendingPathComponent(outputFileName)
                    
                    do {
                        // 设置转录文本，使用API返回的实际内容
                        self.transcribedText = transcribedText
                        
                        // 根据输出格式生成不同格式的文件
                        switch self.outputFormat {
                        case "txt":
                            try transcribedText.write(to: outputURL, atomically: true, encoding: .utf8)
                        case "json":
                            let json = """
                            {
                                "text": "\(transcribedText.replacingOccurrences(of: "\"", with: "\\\""))",
                                "timestamp": "\(timestamp)",
                                "duration": 0
                            }
                            """
                            try json.write(to: outputURL, atomically: true, encoding: .utf8)
                        default:
                            try transcribedText.write(to: outputURL, atomically: true, encoding: .utf8)
                        }
                        
                        self.progressMessage = "转录完成并保存到: \(outputURL.lastPathComponent)"
                        self.logger.debug("Transcription saved to \(outputURL.path)")
                    } catch {
                        self.progressMessage = "保存结果失败: \(error.localizedDescription)"
                        self.logger.error("Failed to save transcription: \(error.localizedDescription)")
                    }
                    
                case .failure(let error):
                    self.progressMessage = "转录失败: \(error.localizedDescription)"
                    self.logger.error("Transcription failed: \(error.localizedDescription)")
                }
                
                // 清理
                self.recordingParts = []
                self.audioRecorder = nil
                self.state = .idle
            }
        }
    }
    
    // 调用OpenAI Whisper API
    private func callWhisperAPI(audioURL: URL, completion: @escaping (Result<String, Error>) -> Void) {
        // 检查API密钥
        guard !apiKey.isEmpty else {
            completion(.failure(NSError(domain: "com.tuna.error", code: 401, userInfo: [NSLocalizedDescriptionKey: "API密钥未设置"])))
            return
        }
        
        // 检查音频文件
        guard let audioData = try? Data(contentsOf: audioURL) else {
            completion(.failure(NSError(domain: "com.tuna.error", code: 404, userInfo: [NSLocalizedDescriptionKey: "无法读取音频文件"])))
            return
        }
        
        // 创建boundary用于multipart请求
        let boundary = "Boundary-\(UUID().uuidString)"
        
        // 设置API URL
        guard let url = URL(string: "https://api.openai.com/v1/audio/transcriptions") else {
            completion(.failure(NSError(domain: "com.tuna.error", code: 500, userInfo: [NSLocalizedDescriptionKey: "无效的API URL"])))
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
        httpBody.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.m4a\"\r\n".data(using: .utf8)!)
        httpBody.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
        httpBody.append(audioData)
        httpBody.append("\r\n".data(using: .utf8)!)
        
        // 添加响应格式
        httpBody.append("--\(boundary)\r\n".data(using: .utf8)!)
        httpBody.append("Content-Disposition: form-data; name=\"response_format\"\r\n\r\n".data(using: .utf8)!)
        httpBody.append("json\r\n".data(using: .utf8)!)
        
        // 添加语言（中文）
        httpBody.append("--\(boundary)\r\n".data(using: .utf8)!)
        httpBody.append("Content-Disposition: form-data; name=\"language\"\r\n\r\n".data(using: .utf8)!)
        httpBody.append("zh\r\n".data(using: .utf8)!)
        
        // 结束boundary
        httpBody.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        // 设置请求体
        request.httpBody = httpBody
        
        // 发送请求
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NSError(domain: "com.tuna.error", code: 500, userInfo: [NSLocalizedDescriptionKey: "无效的HTTP响应"])))
                return
            }
            
            // 检查状态码
            if httpResponse.statusCode != 200 {
                let errorMessage = "API错误: 状态码 \(httpResponse.statusCode)"
                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    self.logger.error("API错误响应: \(responseString)")
                }
                completion(.failure(NSError(domain: "com.tuna.error", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])))
                return
            }
            
            // 解析响应
            guard let data = data else {
                completion(.failure(NSError(domain: "com.tuna.error", code: 500, userInfo: [NSLocalizedDescriptionKey: "没有返回数据"])))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let text = json["text"] as? String {
                    self.logger.debug("API返回转录文本: \(text)")
                    completion(.success(text))
                } else {
                    completion(.failure(NSError(domain: "com.tuna.error", code: 500, userInfo: [NSLocalizedDescriptionKey: "无法解析API响应"])))
                }
            } catch {
                completion(.failure(error))
            }
        }
        
        // 启动任务
        task.resume()
    }
} 