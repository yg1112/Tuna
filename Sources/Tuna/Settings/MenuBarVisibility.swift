import Foundation
import AppKit

class MenuBarVisibility {
    static let shared = MenuBarVisibility()
    private var statusItem: NSStatusItem?
    
    private init() {}
    
    func setVisible(_ visible: Bool) {
        if visible {
            if statusItem == nil {
                statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
                if let button = statusItem?.button {
                    button.image = NSImage(systemSymbolName: "waveform", accessibilityDescription: "Tuna")
                }
            }
        } else {
            if let item = statusItem {
                NSStatusBar.system.removeStatusItem(item)
                statusItem = nil
            }
        }
    }
    
    func isVisible() -> Bool {
        return statusItem != nil
    }
    
    func getStatusItem() -> NSStatusItem? {
        return statusItem
    }
} 