import SwiftUI
import AppKit

class SettingsWindowController {
    private var window: NSWindow?
    static let shared = SettingsWindowController()
    
    private init() {}
    
    func showWindow() {
        if let window = window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 500),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "Tuna Settings"
        window.center()
        window.contentView = NSHostingView(rootView: SettingsView())
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        self.window = window
    }
    
    func closeWindow() {
        window?.close()
        window = nil
    }
} 