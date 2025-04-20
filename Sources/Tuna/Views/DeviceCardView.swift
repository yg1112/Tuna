import SwiftUI
import CoreAudio

struct VolumeSliderView: View {
    @Binding var volume: Float
    let isInput: Bool
    let onChanged: (Float) -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isInput ? "mic" : "speaker.wave.2")
                .foregroundColor(TunaTheme.textSec)
                .frame(width: 16)
            
            Slider(value: self.$volume, in: 0...1) { editing in
                if !editing {
                    self.onChanged(self.volume)
                }
            }
        }
        .padding(.horizontal, 8)
    }
}

struct DeviceCardView: View {
    let device: AudioDevice
    let isInput: Bool
    @Binding var selectedDeviceID: AudioDeviceID
    @EnvironmentObject private var audioManager: AudioManager
    
    private var isSelected: Bool {
        self.selectedDeviceID == self.device.id
    }
    
    private var volume: Binding<Float> {
        Binding(
            get: { self.isInput ? self.audioManager.getInputVolume() : self.audioManager.getOutputVolume() },
            set: { newValue in
                if self.isInput {
                    self.audioManager.setInputVolume(newValue)
                } else {
                    self.audioManager.setOutputVolume(newValue)
                }
            }
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Device selection button
            Button(action: {
                self.selectedDeviceID = self.device.id
                self.audioManager.setDefaultDevice(self.device, forInput: self.isInput)
            }) {
                HStack {
                    Image(systemName: self.isInput ? "mic" : "speaker.wave.2")
                        .foregroundColor(self.isSelected ? TunaTheme.accent : TunaTheme.textSec)
                    
                    Text(self.device.name)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .foregroundColor(self.isSelected ? TunaTheme.accent : TunaTheme.textPri)
                    
                    Spacer()
                    
                    if self.isSelected {
                        Image(systemName: "checkmark")
                            .foregroundColor(TunaTheme.accent)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Volume slider
            if self.isSelected {
                VolumeSliderView(
                    volume: self.volume,
                    isInput: self.isInput,
                    onChanged: { volume in
                        if self.isInput {
                            self.audioManager.setInputVolume(volume)
                        } else {
                            self.audioManager.setOutputVolume(volume)
                        }
                    }
                )
            }
        }
        .padding(8)
        .background(self.isSelected ? TunaTheme.accent.opacity(0.1) : Color.clear)
        .cornerRadius(8)
    }
} 