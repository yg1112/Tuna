import SwiftUI
import TunaAudio
import TunaCore
import TunaSpeech

struct MenuBarView: View {
    @EnvironmentObject var state: AppState
    @ObservedObject var audioManager: AudioManager
    @ObservedObject var settings: TunaSettings

    init(audioManager: AudioManager, settings: TunaSettings) {
        self.audioManager = audioManager
        self.settings = settings
    }

    var body: some View {
        VStack {
            // Audio Controls
            VStack(alignment: .leading, spacing: 10) {
                Text("Output Device: \(self.state.audio.selectedOutput?.name ?? "None")")
                    .padding(.horizontal)

                Text("Output Volume: \(Int(self.state.audio.outputVolume * 100))%")
                    .padding(.horizontal)

                Slider(
                    value: Binding(
                        get: { self.audioManager.outputVolume },
                        set: { self.audioManager.setOutputVolume($0) }
                    ),
                    in: 0 ... 1,
                    step: 0.01
                )
                .padding(.horizontal)
            }
            .padding(.vertical)

            // Speech Status
            if !self.state.speech.transcribedText.isEmpty {
                Text("Last Transcription:")
                    .padding(.horizontal)
                Text(self.state.speech.transcribedText)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Mode Selection
            Picker("Mode", selection: self.$state.settings.mode) {
                ForEach(Mode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
        }
    }
}
