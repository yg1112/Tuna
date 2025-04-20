import SwiftUI

struct SettingsView: View {
    @StateObject private var settings = TunaSettings.shared
    
    private let languages = [
        "English (US)",
        "English (UK)",
        "中文 (简体)",
        "中文 (繁體)",
        "日本語",
        "한국어",
        "Español",
        "Français",
        "Deutsch",
        "Italiano"
    ]
    
    var body: some View {
        Form {
            // General Settings Section
            Section("General") {
                Toggle("Launch at Login", isOn: $settings.launchAtLogin)
                    .onChange(of: settings.launchAtLogin) { newValue in
                        // TODO: Implement launch at login functionality
                    }
                
                Toggle("Show in Dock", isOn: $settings.showInDock)
                    .onChange(of: settings.showInDock) { newValue in
                        // TODO: Implement dock visibility toggle
                    }
                
                Toggle("Show in Menu Bar", isOn: $settings.showInMenuBar)
                    .onChange(of: settings.showInMenuBar) { newValue in
                        // TODO: Implement menu bar visibility toggle
                    }
            }
            
            // Dictation Settings Section
            Section("Dictation") {
                HStack {
                    Text("Hotkey:")
                    TextField("Press keys...", text: $settings.dictationHotkey)
                        .textFieldStyle(.roundedBorder)
                }
                
                Picker("Language", selection: $settings.dictationLanguage) {
                    ForEach(languages, id: \.self) { language in
                        Text(language).tag(language)
                    }
                }
                
                Toggle("Auto-stop after silence", isOn: $settings.autoStopAfterSilence)
                
                if settings.autoStopAfterSilence {
                    VStack(alignment: .leading) {
                        Text("Silence threshold: \(Int(settings.silenceThreshold * 100))%")
                        Slider(value: $settings.silenceThreshold, in: 0...1)
                    }
                }
            }
            
            // Reset Section
            Section {
                Button(action: {
                    settings.resetToDefaults()
                }) {
                    Text("Reset to Defaults")
                        .foregroundColor(.red)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 400)
        .fixedSize()
    }
}

#Preview {
    SettingsView()
} 