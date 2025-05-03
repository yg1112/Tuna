import Foundation

public struct SpeechState: Equatable {
    public var isRecording: Bool
    public var transcriptionText: String

    public init(isRecording: Bool = false, transcriptionText: String = "") {
        self.isRecording = isRecording
        self.transcriptionText = transcriptionText
    }
}
