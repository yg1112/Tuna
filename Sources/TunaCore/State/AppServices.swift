import Foundation
import TunaAudio
import TunaSpeech

public protocol AudioServiceProtocol {
    func currentAudioState() -> AudioState
}

public struct LiveAudioService: AudioServiceProtocol {
    private let manager: AudioManagerProtocol

    public init(manager: AudioManagerProtocol) {
        self.manager = manager
    }

    public func currentAudioState() -> AudioState {
        AudioState(
            selectedOutput: self.manager.selectedOutputDevice,
            outputVolume: self.manager.outputVolume
        )
    }
}

public protocol SpeechServiceProtocol {
    func currentSpeechState() -> SpeechState
}

public struct LiveSpeechService: SpeechServiceProtocol {
    private let manager: DictationManagerProtocol

    public init(manager: DictationManagerProtocol) {
        self.manager = manager
    }

    public func currentSpeechState() -> SpeechState {
        SpeechState(transcribedText: self.manager.transcribedText)
    }
}

public protocol SettingsServiceProtocol {
    func load() -> AppSettings
    func save(_ settings: AppSettings)
}

public struct LiveSettingsService: SettingsServiceProtocol {
    private let settings: TunaSettings

    public init(settings: TunaSettings = .shared) {
        self.settings = settings
    }

    public func load() -> AppSettings {
        AppSettings(
            mode: self.settings.currentMode,
            isMagicEnabled: self.settings.magicEnabled
        )
    }

    public func save(_ settings: AppSettings) {
        self.settings.currentMode = settings.mode
        self.settings.magicEnabled = settings.isMagicEnabled
    }
}

public struct AppServices {
    public let audio: AudioServiceProtocol
    public let speech: SpeechServiceProtocol
    public let settings: SettingsServiceProtocol

    public init(
        audio: AudioServiceProtocol,
        speech: SpeechServiceProtocol,
        settings: SettingsServiceProtocol
    ) {
        self.audio = audio
        self.speech = speech
        self.settings = settings
    }

    public static func createLive(
        audioManager: AudioManagerProtocol,
        dictationManager: DictationManagerProtocol,
        settings: TunaSettings = .shared
    ) -> AppServices {
        AppServices(
            audio: LiveAudioService(manager: audioManager),
            speech: LiveSpeechService(manager: dictationManager),
            settings: LiveSettingsService(settings: settings)
        )
    }

    public static var live: AppServices {
        createLive(
            audioManager: AudioManager.shared,
            dictationManager: DictationManager.shared
        )
    }
}
