import Foundation
import AppKit

class DockVisibility {
    static let shared = DockVisibility()
    
    private init() {}
    
    func setVisible(_ visible: Bool) {
        if visible {
            NSApp.setActivationPolicy(.regular)
        } else {
            NSApp.setActivationPolicy(.accessory)
        }
    }
    
    func isVisible() -> Bool {
        return NSApp.activationPolicy() == .regular
    }
} 