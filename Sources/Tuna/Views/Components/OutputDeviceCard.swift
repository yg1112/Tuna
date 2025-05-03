import SwiftUI
import TunaAudio
import TunaTypes

struct OutputDeviceCard: View {
    @ObservedObject var audioManager: AudioManager
    @ObservedObject var settings: TunaSettings

    var body: some View {
        VStack {
            Text("Output Device")
                .font(.headline)
        }
        .padding()
    }
}
