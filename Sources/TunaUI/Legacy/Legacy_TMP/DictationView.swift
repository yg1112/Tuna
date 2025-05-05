import SwiftUI
import TunaAudio
import TunaCore
import TunaSpeech
import TunaTypes

struct DictationView: View {
    @EnvironmentObject var dictationManager: DictationManager
    @StateObject private var settings = TunaSettings.shared

    var body: some View {
        VStack {
            Text("Dictation View")
                .font(.title)
        }
        .padding()
    }
}
