import Cocoa
import SwiftUI
import os.log

// 添加 NSImage 扩展以支持着色
extension NSImage {
    func tinted(with color: NSColor) -> NSImage {
        let image = self.copy() as! NSImage
        image.lockFocus()
        
        color.set()
        
        let imageRect = NSRect(origin: .zero, size: image.size)
        imageRect.fill(using: .sourceAtop)
        
        image.unlockFocus()
        return image
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    private var settingsWindowController: SettingsWindowController?
    private let logger = Logger(subsystem: "com.tuna.app", category: "AppDelegate")
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("\u{001B}[34m[APP]\u{001B}[0m Application finished launching")
        fflush(stdout)
        
        setupStatusItem()
        
        // Register notification observer for settings window
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(showSettingsWindow(_:)),
            name: NSNotification.Name("showSettings"),
            object: nil
        )
        
        logger.info("Application initialization completed")
        print("\u{001B}[32m[APP]\u{001B}[0m Initialization complete")
        fflush(stdout)
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        print("\u{001B}[34m[APP]\u{001B}[0m Application will terminate")
        logger.info("Application will terminate")
        fflush(stdout)
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            // Use fish icon to match app name "Tuna"
            if let fishImage = NSImage(systemSymbolName: "fish.fill", accessibilityDescription: "Tuna Audio Controls") {
                // 设置图标为绿色
                let coloredImage = fishImage.tinted(with: NSColor(red: 0.4, green: 0.9, blue: 0.6, alpha: 1.0))
                button.image = coloredImage
            }
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        popover = NSPopover()
        popover.contentSize = NSSize(width: 300, height: 480)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: MenuBarView())
        
        print("\u{001B}[36m[UI]\u{001B}[0m Status bar icon configured")
        fflush(stdout)
    }
    
    @objc private func togglePopover() {
        if let button = statusItem.button {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }
    
    @objc func showSettingsWindow(_ notification: Notification) {
        print("\u{001B}[36m[SETTINGS]\u{001B}[0m User requested settings window")
        fflush(stdout)
        
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController()
        }
        
        if let window = settingsWindowController?.window {
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(nil)
            
            print("\u{001B}[36m[SETTINGS]\u{001B}[0m Settings window displayed")
            fflush(stdout)
        }
    }
    
    @objc func handleDeviceSelection(_ sender: NSMenuItem) {
        guard let info = sender.representedObject as? DeviceSelectionInfo else { return }
        
        print("Switching device: \(info.device.name), is input: \(info.isInput)")
        
        // Use AudioManager to switch device
        AudioManager.shared.setDefaultDevice(info.device, forInput: info.isInput)
        
        // Close menu
        if let menu = sender.menu {
            menu.cancelTracking()
        }
    }
} 