@testable import TunaCore
import XCTest

final class MagicEnabledStateTests: XCTestCase {
    func testMagicEnabledSync() {
        let services = AppServices(
            audio: LiveAudioService(),
            speech: LiveSpeechService(),
            settings: LiveSettingsService()
        )
        var state = AppState(
            audio: .init(selectedOutput: nil, outputVolume: 0),
            speech: .init(transcribedText: ""),
            settings: services.settings.load()
        )

        // toggle magic
        state.settings.isMagicEnabled.toggle()
        services.settings.save(state.settings)

        XCTAssertEqual(
            TunaSettings.shared.magicEnabled,
            state.settings.isMagicEnabled
        )
    }
}
