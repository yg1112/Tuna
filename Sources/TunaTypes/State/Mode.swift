import Foundation

public enum Mode: String, Codable, Equatable, CaseIterable {
    case quickDictation
    case fullTranscription
    case custom

    public var displayName: String {
        switch self {
            case .quickDictation: "Quick Dictation"
            case .fullTranscription: "Full Transcription"
            case .custom: "Custom"
        }
    }
}
