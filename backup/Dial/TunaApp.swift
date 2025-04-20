import SwiftUI

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
                .font(.title2.bold())
                .imageScale(.large)
                .frame(width: 28)
        }
        .menuBarExtraStyle(.window)
    }
}
