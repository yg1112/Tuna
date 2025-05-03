import SwiftUI
import TunaTypes
import TunaAudio
import TunaSpeech
import TunaUI

    @ObservedObject var audioManager: AudioManager
    @ObservedObject var settings: TunaSettings
    @EnvironmentObject var dictationManager: DictationManager
    @EnvironmentObject var tabRouter: TabRouter
    
    var body: some View {
        VStack(spacing: 16) {
            // Mode Selection
            Picker("Mode", selection: self.$settings.currentMode) {
                ForEach(Mode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode.rawValue)
                }
            }
            .pickerStyle(.segmented)
            
            // Content based on mode
            if Mode(rawValue: self.settings.currentMode) == .quickDictation {
                TunaDictationView()
            } else {
                TunaSettingsView()
            }
        }
        .padding()
    }
}
