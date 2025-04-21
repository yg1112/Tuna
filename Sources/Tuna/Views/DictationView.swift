import SwiftUI

struct DictationView: View {
    @EnvironmentObject var dictationManager: DictationManager
    @EnvironmentObject var settings: TunaSettings
    @State private var error: Error?
    @State private var showError = false
    
    var body: some View {
        VStack {
            Text("Dictation")
                .font(.headline)
                .padding()
            
            // Status display
            Text(dictationManager.state.displayText)
                .foregroundColor(statusColor)
                .padding(.bottom)
            
            // Recording button
            Button(action: {
                Task {
                    do {
                        try await dictationManager.toggle()
                    } catch {
                        self.error = error
                        self.showError = true
                    }
                }
            }) {
                Image(systemName: buttonImageName)
                    .resizable()
                    .frame(width: 44, height: 44)
                    .foregroundColor(buttonColor)
            }
            .buttonStyle(.plain)
            .padding()
            
            // Transcribed text
            ScrollView {
                Text(dictationManager.transcribedText)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: .infinity)
        }
        .padding()
        .frame(width: 300)
        .alert("Error", isPresented: $showError) {
            Button("OK") {
                showError = false
            }
        } message: {
            Text(error?.localizedDescription ?? "An unknown error occurred")
        }
    }
    
    // MARK: - Computed Properties
    
    private var statusColor: Color {
        switch dictationManager.state {
        case .recording:
            return .red
        case .paused:
            return .orange
        case .processing:
            return .blue
        case .error:
            return .red
        case .idle:
            return .primary
        }
    }
    
    private var buttonImageName: String {
        switch dictationManager.state {
        case .recording:
            return "stop.circle.fill"
        case .paused:
            return "play.circle.fill"
        case .processing:
            return "clock.circle.fill"
        case .error:
            return "exclamationmark.circle.fill"
        case .idle:
            return "mic.circle.fill"
        }
    }
    
    private var buttonColor: Color {
        switch dictationManager.state {
        case .recording:
            return .red
        case .paused:
            return .orange
        case .processing:
            return .blue
        case .error:
            return .red
        case .idle:
            return .blue
        }
    }
}

#Preview {
    DictationView()
        .environmentObject(DictationManager.shared)
        .environmentObject(TunaSettings.shared)
} 