import AppKit
import Combine
import Foundation
import os.log
import SwiftUI
import TunaAudio
import TunaCore
import TunaSpeech

class AudioBuddyAppDelegate: NSObject, ObservableObject {
    var cancellables = Set<AnyCancellable>()
    let audioManager = AudioManager.shared
    let modeManager = AudioModeManager.shared
    private let logger = Logger(subsystem: "com.tuna.app", category: "AudioBuddyApp")

    override init() {
        super.init()
        print("\u{001B}[34m[APP]\u{001B}[0m Audio manager initializing")
        fflush(stdout)
        self.setupModeVolumeSync()
        print("\u{001B}[32m[AUDIO]\u{001B}[0m Volume sync setup complete")
        fflush(stdout)
    }

    private func setupModeVolumeSync() {
        // When volume changes, update current mode's volume settings
        self.audioManager.$outputVolume
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.modeManager.updateCurrentModeVolumes()
            }
            .store(in: &self.cancellables)

        self.audioManager.$inputVolume
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.modeManager.updateCurrentModeVolumes()
            }
            .store(in: &self.cancellables)

        self.logger.info("Volume sync manager configured")
    }
}

@main
struct AudioBuddyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var audioBuddyDelegate = AudioBuddyAppDelegate()

    // Add AppState
    @StateObject private var appState: AppState
    private let services: AppServices

    init() {
        print("\u{001B}[34m[APP]\u{001B}[0m Tuna app launched")

        // Initialize services and state
        let services = AppServices.createLive(
            audioManager: AudioManager.shared,
            dictationManager: DictationManager.shared,
            settings: TunaSettings.shared
        )
        let state = AppState(
            audio: services.audio.currentAudioState(),
            speech: services.speech.currentSpeechState(),
            settings: services.settings.load()
        )

        self._appState = StateObject(wrappedValue: state)
        self.services = services

        fflush(stdout)
    }

    var body: some Scene {
        Settings {
            EmptyView()
                .environmentObject(self.appState)
        }
        .onChange(of: NSApplication.shared.isActive) { isActive in
            if isActive {
                print("\u{001B}[34m[APP]\u{001B}[0m App became active")
                fflush(stdout)
            }
        }
    }
}
