import SwiftUI
import AppKit

/// A SwiftUI wrapper around `NSVisualEffectView` that provides system-standard visual effects
/// like blurred backgrounds for popovers and HUD windows.
struct VisualEffectView: NSViewRepresentable {
    /// The material style to use for the visual effect.
    /// Common values are `.popover` for menu-style views and `.hudWindow` for floating panels.
    let material: NSVisualEffectView.Material
    
    /// The blending mode that determines how the effect is composited.
    /// `.behindWindow` is typically used to blend with the content behind the window.
    let blendingMode: NSVisualEffectView.BlendingMode
    
    /// Creates a new visual effect view with the specified material and blending mode.
    /// - Parameters:
    ///   - material: The material style to use. Defaults to `.popover`.
    ///   - blendingMode: The blending mode to use. Defaults to `.behindWindow`.
    init(
        material: NSVisualEffectView.Material = .popover,
        blendingMode: NSVisualEffectView.BlendingMode = .behindWindow
    ) {
        self.material = material
        self.blendingMode = blendingMode
    }
    
    /// Creates the underlying `NSVisualEffectView` and configures it with the specified properties.
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    /// Updates the visual effect view when the configuration changes.
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
} 