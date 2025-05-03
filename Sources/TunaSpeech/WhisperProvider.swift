import Foundation
import TunaTypes

public final class WhisperProvider: SpeechProviderProtocol {
    public static let shared = WhisperProvider()
    public init() {}
    public func transcribe(audioURL: URL) async throws -> String {
        // Stub: 实际实现应调用 OpenAI Whisper API
        "[Stub transcription for \(audioURL.lastPathComponent)]"
    }
}
