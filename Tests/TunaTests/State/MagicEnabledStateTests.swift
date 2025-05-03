import TunaAudio
@testable import TunaCore
import TunaSpeech
import TunaTypes
import XCTest

final class MagicEnabledStateTests: XCTestCase {
    func testMagicEnabledSync() async throws {
        let settings = TunaSettings.shared
        let services = AppServices(
            audioService: LiveAudioService(manager: AudioManager.shared),
            speechService: LiveSpeechService(dictationManager: DictationManager.shared),
            settingsService: LiveSettingsService(settings: settings)
        )

        // Initial state
        let initialSettings = await services.settingsService.currentSettings()
        XCTAssertFalse(initialSettings.isMagicEnabled)

        // Toggle magic
        var updatedSettings = initialSettings
        updatedSettings.isMagicEnabled.toggle()
        services.settingsService.save(updatedSettings)

        // Verify the change was synced
        XCTAssertEqual(settings.magicEnabled, updatedSettings.isMagicEnabled)
        let currentSettings = await services.settingsService.currentSettings()
        XCTAssertEqual(currentSettings.isMagicEnabled, updatedSettings.isMagicEnabled)
    }
}
