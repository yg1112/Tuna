import TunaAudio
import TunaCore
import TunaSpeech
import TunaTypes

public extension AppServices {
    @MainActor
    static func createLive() -> AppServices {
        self.init(
            audioService: LiveAudioService(manager: AudioManager.shared),
            speechService: LiveSpeechService(dictationManager: DictationManager.shared),
            settingsService: LiveSettingsService(settings: TunaSettings.shared)
        )
    }
}
