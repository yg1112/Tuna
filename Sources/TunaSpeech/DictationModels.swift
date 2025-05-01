import Foundation
import TunaCore

/// 听写状态
public enum DictationState: Equatable {
    case idle
    case recording
    case paused
    case processing
    case error(Error)

    public static func == (lhs: DictationState, rhs: DictationState) -> Bool {
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

/// Protocol defining the interface for dictation management
public protocol DictationManagerProtocol: ObservableObject {
    var state: DictationState { get set }
    var progressMessage: String { get set }
    var transcribedText: String { get set }
    var isRecording: Bool { get }
    var isPaused: Bool { get }
    var breathingAnimation: Bool { get }

    func startRecording()
    func stopRecording()
    func pauseRecording()
    func resumeRecording()
    func updateAPIKey(_ key: String)
    func toggle()
}

/// Error types for dictation operations
public enum DictationError: Error, LocalizedError {
    case noAPIKey
    case audioFileReadError
    case transcriptionFailed(Error)

    public var errorDescription: String? {
        switch self {
            case .noAPIKey:
                "No API key provided. Please add your OpenAI API key in Settings."
            case .audioFileReadError:
                "Could not read audio file."
            case let .transcriptionFailed(error):
                "Transcription failed: \(error.localizedDescription)"
        }
    }
}

/// Notification names for dictation events
public extension Notification.Name {
    static let dictationAPIKeyMissing = Notification.Name("dictationAPIKeyMissing")
    static let dictationAPIKeyUpdated = Notification.Name("dictationAPIKeyUpdated")
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
