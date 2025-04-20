import SwiftUI

struct VolumeControl: View {
    let title: String
    @Binding var volume: Float
    let isInput: Bool
    @EnvironmentObject private var audioManager: AudioManager

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(self.title)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)

            HStack {
                Slider(value: self.$volume, onEditingChanged: { _ in
                    self.audioManager.setVolume(self.volume, forInput: self.isInput)
                })
                .padding(.horizontal, 12)
            }
            .padding(.bottom, 4)
        }
    }
} 