import TunaAudio
@testable import TunaCore
import TunaSpeech
import TunaTypes
import XCTest

final class RemainingSettingsStateTests: XCTestCase {
    func testMagicPresetAndLanguageSync() async throws {
        let settings = TunaSettings.shared
        let services = AppServices(
            audioService: LiveAudioService(manager: AudioManager.shared),
            speechService: LiveSpeechService(dictationManager: DictationManager.shared),
            settingsService: LiveSettingsService(settings: settings)
        )

        // Initial state
        let initialSettings = await services.settingsService.currentSettings()
        XCTAssertEqual(initialSettings.magicPreset, .none)
        XCTAssertEqual(initialSettings.transcriptionLanguage, "en")

        // Update settings
        var updatedSettings = initialSettings
        updatedSettings.magicPreset = .formal
        updatedSettings.transcriptionLanguage = "en-US"
        services.settingsService.save(updatedSettings)

        // Verify changes were synced
        XCTAssertEqual(settings.magicPreset, updatedSettings.magicPreset.rawValue)
        XCTAssertEqual(settings.transcriptionLanguage, updatedSettings.transcriptionLanguage)

        let currentSettings = await services.settingsService.currentSettings()
        XCTAssertEqual(currentSettings.magicPreset, updatedSettings.magicPreset)
        XCTAssertEqual(currentSettings.transcriptionLanguage, updatedSettings.transcriptionLanguage)
    }
}
