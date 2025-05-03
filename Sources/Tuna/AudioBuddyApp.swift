import AppKit
import Combine
import Foundation
import os.log
import SwiftUI
import TunaAudio
import TunaCore
import TunaSpeech
import TunaTypes
import TunaUI

@MainActor
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
        Task {
            for await _ in await self.audioManager.outputVolumeStream {
                self.modeManager.updateCurrentModeVolumes()
            }
        }

        Task {
            for await _ in await self.audioManager.inputVolumeStream {
                self.modeManager.updateCurrentModeVolumes()
            }
        }

        self.logger.info("Volume sync manager configured")
    }
}

@main
struct AudioBuddyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(TunaSettings.shared)
                .environmentObject(DictationManager.shared)
                .environmentObject(TabRouter.shared)
        }
    }
}
