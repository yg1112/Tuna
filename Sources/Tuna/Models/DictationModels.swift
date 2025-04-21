import Foundation
import SwiftUI

/// Represents the current state of the dictation system
public enum DictationState: Equatable {
    case idle
    case recording
    case paused
    case processing
    case error(String)
    
    public var isActive: Bool {
        switch self {
        case .recording, .processing:
            return true
        case .idle, .paused, .error:
            return false
        }
    }
    
    public var displayText: String {
        switch self {
        case .idle:
            return "Ready"
        case .recording:
            return "Recording..."
        case .paused:
            return "Paused"
        case .processing:
            return "Processing..."
        case .error(let message):
            return "Error: \(message)"
        }
    }
}

@preconcurrency
public protocol DictationManagerProtocol: ObservableObject {
    var state: DictationState { get set }
    var progressMessage: String { get set }
    var transcribedText: String { get set }
    var isRecording: Bool { get }
    var isPaused: Bool { get }
    
    func startRecording() async throws
    func pauseRecording() async throws
    func stopRecording() async throws
    func getDocumentsDirectory() async -> URL
    func toggle() async throws
}

// MARK: - Notifications
public extension Notification.Name {
    static let dictationStateChanged = Notification.Name("dictationStateChanged")
    static let dictationAPIKeyMissing = Notification.Name("dictationAPIKeyMissing")
    static let dictationAPIKeyUpdated = Notification.Name("dictationAPIKeyUpdated")
    static let dictationStarted = Notification.Name("dictationStarted")
    static let dictationStopped = Notification.Name("dictationStopped")
    static let dictationPaused = Notification.Name("dictationPaused")
    static let dictationResumed = Notification.Name("dictationResumed")
    static let dictationError = Notification.Name("dictationError")
    static let dictationCancelled = Notification.Name("dictationCancelled")
}

// MARK: - Errors
public enum DictationError: LocalizedError {
    case invalidState(String)
    case recordingError(String)
    case transcriptionError(String)
    case audioSessionError(String)
    case noAPIKey
    case audioFileReadError
    case transcriptionFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidState(let message):
            return "Invalid state: \(message)"
        case .recordingError(let message):
            return "Recording error: \(message)"
        case .transcriptionError(let message):
            return "Transcription error: \(message)"
        case .audioSessionError(let message):
            return "Audio session error: \(message)"
        case .noAPIKey:
            return "API key is missing"
        case .audioFileReadError:
            return "Failed to read audio file"
        case .transcriptionFailed(let message):
            return "Transcription failed: \(message)"
        }
    }
}
