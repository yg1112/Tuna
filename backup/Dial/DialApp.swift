import SwiftUI

@main
struct DialApp: App {
    @StateObject private var audioManager = AudioManager.shared

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(audioManager)
        } label: {
            Image(systemName: "infinity")
                .font(.title2.bold())
                .symbolRenderingMode(.hierarchical)
                .imageScale(.large)
                .frame(width: 28)
        }
    }
}
