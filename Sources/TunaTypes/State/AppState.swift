import Foundation

@MainActor
public class AppState: ObservableObject {
    @Published public var audioState: AudioState
    @Published public var speechState: SpeechState
    @Published public var settings: AppSettings

    public init(
        audioState: AudioState = AudioState(
            inputDevices: [],
            outputDevices: [],
            selectedInputDevice: nil as AudioDeviceImpl?,
            selectedOutputDevice: nil as AudioDeviceImpl?,
            inputVolume: 0.0,
            outputVolume: 0.0
        ),
        speechState: SpeechState = SpeechState(transcriptionText: ""),
        settings: AppSettings = AppSettings(
            mode: .quickDictation,
            isMagicEnabled: false,
            magicPreset: .none,
            transcriptionLanguage: "en"
        )
    ) {
        self.audioState = audioState
        self.speechState = speechState
        self.settings = settings
    }
}
