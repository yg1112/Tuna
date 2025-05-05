import SwiftUI
import TunaAudio
import TunaTypes

struct InputDeviceCard: View {
    @ObservedObject var audioManager: AudioManager
    @ObservedObject var settings: TunaSettings

    var body: some View {
        VStack {
            Text("Input Device")
                .font(.headline)
        }
        .padding()
    }
}
