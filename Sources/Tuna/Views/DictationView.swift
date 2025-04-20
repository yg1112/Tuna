import SwiftUI

struct DictationView: View {
    @EnvironmentObject var dictationManager: DictationManager
    @EnvironmentObject var settings: TunaSettings
    
    var body: some View {
        VStack {
            Text("Dictation")
                .font(.headline)
                .padding()
            
            if dictationManager.isRecording {
                Text("Recording...")
                    .foregroundColor(.red)
            }
            
            Button(action: {
                if dictationManager.isRecording {
                    dictationManager.stopRecording()
                } else {
                    dictationManager.startRecording()
                }
            }) {
                Image(systemName: dictationManager.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                    .resizable()
                    .frame(width: 44, height: 44)
                    .foregroundColor(dictationManager.isRecording ? .red : .blue)
            }
            .buttonStyle(.plain)
            .padding()
            
            Text(dictationManager.transcribedText)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .frame(width: 300)
    }
}

#Preview {
    DictationView()
        .environmentObject(DictationManager())
        .environmentObject(TunaSettings())
} 