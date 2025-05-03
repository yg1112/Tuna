import Foundation

public struct TranscriptionState: Equatable {
    public var autoCopyTranscriptionToClipboard: Bool
    public var transcriptionOutputDirectory: URL?
    public var transcriptionFormat: String
    public var whisperAPIKey: String

    public init(
        autoCopyTranscriptionToClipboard: Bool = true,
        transcriptionOutputDirectory: URL? = nil,
        transcriptionFormat: String = "txt",
        whisperAPIKey: String = ""
    ) {
        self.autoCopyTranscriptionToClipboard = autoCopyTranscriptionToClipboard
        self.transcriptionOutputDirectory = transcriptionOutputDirectory
        self.transcriptionFormat = transcriptionFormat
        self.whisperAPIKey = whisperAPIKey
    }
}
