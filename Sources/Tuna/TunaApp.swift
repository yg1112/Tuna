import SwiftUI

@main
struct TunaApp: App {
    @NSApplicationDelegateAdaptor(TunaAppDelegate.self) var appDelegate
    @StateObject private var settings = TunaSettings.shared
    
    var body: some Scene {
        WindowGroup {
            EmptyView()
        }
    }
} 