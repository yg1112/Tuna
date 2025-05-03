import Foundation
import TunaTypes

public struct LiveSpeechService {
    private let manager: any DictationManagerProtocol

    public init(dictationManager: any DictationManagerProtocol) {
        self.manager = dictationManager
    }

    public func startDictation() async {
        await self.manager.startDictation()
    }

    public func stopDictation() async {
        await self.manager.stopDictation()
    }

    public func toggleDictation() async {
        await self.manager.toggleDictation()
    }

    public nonisolated func currentSpeechState() async -> SpeechState {
        await Task { @MainActor in
            SpeechState(transcriptionText: self.manager.transcribedText)
        }.value
    }

    public func startRecording() async {
        await self.startDictation()
    }

    public func stopRecording() async {
        await self.stopDictation()
    }

    public func pauseRecording() async {
        await self.toggleDictation()
    }

    public func resumeRecording() async {
        await self.toggleDictation()
    }
}
