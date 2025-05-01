import Combine
import Foundation
import TunaTypes

public struct AudioState {
    public var selectedOutput: AudioDevice?
    public var outputVolume: Float

    public init(selectedOutput: AudioDevice?, outputVolume: Float) {
        self.selectedOutput = selectedOutput
        self.outputVolume = outputVolume
    }
}

public struct SpeechState {
    public var transcribedText: String

    public init(transcribedText: String) {
        self.transcribedText = transcribedText
    }
}

public struct AppSettings {
    public var mode: Mode

    public init(mode: Mode) {
        self.mode = mode
    }
}

@MainActor
public final class AppState: ObservableObject {
    @Published public private(set) var audio: AudioState
    @Published public private(set) var speech: SpeechState
    @Published public var settings: AppSettings

    public init(audio: AudioState, speech: SpeechState, settings: AppSettings) {
        self.audio = audio
        self.speech = speech
        self.settings = settings
    }
}
