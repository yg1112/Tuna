import AppKit
import SwiftUI

class TunaAppDelegate: NSObject, NSApplicationDelegate {
    private var settingsWindow: NSWindow?
    private var settings: TunaSettings
    
    override init() {
        self.settings = TunaSettings.shared
        super.init()
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize visibility based on settings
        DockVisibility.shared.setVisible(settings.showInDock)
        MenuBarVisibility.shared.setVisible(settings.showInMenuBar)
        
        // Set up menu bar if enabled
        if settings.showInMenuBar {
            setupMenuBar()
        }
    }
    
    private func setupMenuBar() {
        if let statusItem = MenuBarVisibility.shared.getStatusItem() {
            let menuBarView = MenuBarView()
                .environmentObject(settings)
            
            let hostingView = NSHostingView(rootView: menuBarView)
            hostingView.frame = NSRect(x: 0, y: 0, width: 300, height: 400)
            
            let menu = NSMenu()
            let menuItem = NSMenuItem()
            menuItem.view = hostingView
            menu.addItem(menuItem)
            
            statusItem.menu = menu
        }
    }
    
    func showSettings() {
        if settingsWindow == nil {
            let settingsView = SettingsView()
                .environmentObject(settings)
            
            let hostingController = NSHostingController(rootView: settingsView)
            
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 400, height: 500),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            
            window.title = "Tuna Settings"
            window.contentViewController = hostingController
            window.center()
            
            settingsWindow = window
        }
        
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
} 