import Foundation

/// 听写状态
public enum DictationStateType: Equatable {
    case idle
    case recording
    case paused
    case processing
    case error(Error)

    public static func == (lhs: DictationStateType, rhs: DictationStateType) -> Bool {
        switch (lhs, rhs) {
            case (.idle, .idle),
                 (.recording, .recording),
                 (.paused, .paused),
                 (.processing, .processing):
                true
            case (.error, .error):
                true
            default:
                false
        }
    }
}

public struct DictationState: Equatable {
    public var settings: DictationSettings
    public var state: DictationStateType
    public var progressMessage: String
    public var transcribedText: String
    public var isRecording: Bool
    public var isPaused: Bool
    public var breathingAnimation: Bool

    public init(
        settings: DictationSettings = DictationSettings(),
        state: DictationStateType = .idle,
        progressMessage: String = "",
        transcribedText: String = "",
        isRecording: Bool = false,
        isPaused: Bool = false,
        breathingAnimation: Bool = false
    ) {
        self.settings = settings
        self.state = state
        self.progressMessage = progressMessage
        self.transcribedText = transcribedText
        self.isRecording = isRecording
        self.isPaused = isPaused
        self.breathingAnimation = breathingAnimation
    }

    public static func == (lhs: DictationState, rhs: DictationState) -> Bool {
        lhs.state == rhs.state &&
            lhs.progressMessage == rhs.progressMessage &&
            lhs.transcribedText == rhs.transcribedText &&
            lhs.isRecording == rhs.isRecording &&
            lhs.isPaused == rhs.isPaused &&
            lhs.breathingAnimation == rhs.breathingAnimation &&
            lhs.settings == rhs.settings
    }
}

public struct DictationSettings: Equatable {
    public var transcriptionLanguage: String

    public init(transcriptionLanguage: String = "") {
        self.transcriptionLanguage = transcriptionLanguage
    }

    public static func == (lhs: DictationSettings, rhs: DictationSettings) -> Bool {
        lhs.transcriptionLanguage == rhs.transcriptionLanguage
    }
}

/// Protocol defining the interface for dictation management
@preconcurrency
@MainActor
public protocol DictationManagerProtocol: ObservableObject {
    var state: DictationState { get set }
    var progressMessage: String { get set }
    var transcribedText: String { get set }
    var isRecording: Bool { get }
    var isPaused: Bool { get }
    var breathingAnimation: Bool { get }

    func startRecording() async
    func stopRecording() async
    func pauseRecording() async
    func startDictation() async
    func stopDictation() async
    func toggleDictation() async
    func updateAPIKey(_ key: String) async
    func toggle() async
}

/// Error types for dictation operations
public enum DictationError: Error, LocalizedError {
    case noAPIKey
    case audioFileReadError
    case transcriptionFailed(Error)
    case recordingFailed
    case apiKeyMissing

    public var errorDescription: String? {
        switch self {
            case .noAPIKey:
                "No API key provided. Please add your OpenAI API key in Settings."
            case .audioFileReadError:
                "Could not read audio file."
            case let .transcriptionFailed(error):
                "Transcription failed: \(error.localizedDescription)"
            case .recordingFailed:
                "Recording failed."
            case .apiKeyMissing:
                "API key is missing."
        }
    }
}

public protocol NowProvider {
    func now() -> Date
}

public struct RealNowProvider: NowProvider {
    public init() {}

    public func now() -> Date {
        Date()
    }
}

public protocol UUIDProvider {
    func uuid() -> UUID
}

public struct RealUUIDProvider: UUIDProvider {
    public init() {}

    public func uuid() -> UUID {
        UUID()
    }
}
