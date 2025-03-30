import SwiftUI

/// Tuna 音频设备管理应用
@available(macOS 13.0, *)
@main
struct TunaApp: App {
    @StateObject private var audioManager = AudioManager.shared
    
    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(audioManager)
        } label: {
            Image(systemName: "fish")
                .symbolRenderingMode(.hierarchical)
                .imageScale(.large)
                .frame(width: 28)
        }
        .menuBarExtraStyle(.window)
    }
} 