import SwiftUI

struct TranscriptSettingsView: View {
    @ObservedObject var settings: TunaSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Magic Transform 设置
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Enable Magic Transform", isOn: self.$settings.magicEnabled)
                    .toggleStyle(SwitchToggleStyle(tint: Color.blue))

                Picker("Style", selection: self.$settings.magicPreset) {
                    Text("A bit").tag(PresetStyle.abit)
                    Text("Concise").tag(PresetStyle.concise)
                    Text("Custom").tag(PresetStyle.custom)
                }
                .pickerStyle(.segmented)
                .disabled(!self.settings.magicEnabled)

                if self.settings.magicPreset == .custom {
                    TextEditor(text: self.$settings.magicCustomPrompt)
                        .font(.system(size: 14))
                        .foregroundColor(.primary)
                        .frame(height: 80)
                        .cornerRadius(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.secondary.opacity(0.5), lineWidth: 1)
                        )
                        .disabled(!self.settings.magicEnabled)
                }
            }
            .padding()
            .background(Color(.textBackgroundColor).opacity(0.1))
            .cornerRadius(8)
        }
        .padding()
    }
}
