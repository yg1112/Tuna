import AppKit

/// NSPopover's window that can receive key events.
final class KeyPopoverWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
