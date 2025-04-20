import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarItem: NSStatusItem!
    @ObservedObject private var audioManager = AudioManager.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 隐藏 dock 图标
        NSApp.setActivationPolicy(.accessory)

        // 创建状态栏图标
        self.statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusBarItem.button {
            // 设置图标
            button.image = NSImage(
                systemSymbolName: "fish",
                accessibilityDescription: "Audio Buddy"
            )

            // 创建菜单视图
            let menuView = MenuBarView().environmentObject(self.audioManager)
            let hostingView = NSHostingView(rootView: menuView)
            hostingView.frame = NSRect(x: 0, y: 0, width: 260, height: 400)

            // 创建弹出窗口
            let popover = NSPopover()
            popover.contentSize = NSSize(width: 260, height: 400)
            popover.behavior = .transient
            popover.contentViewController = NSHostingController(rootView: menuView)

            // 点击事件处理
            button.action = #selector(self.togglePopover(_:))
            button.target = self

            // 存储 popover
            self.popover = popover
        }
    }

    private var popover: NSPopover?
    private var eventMonitor: Any?

    @objc func togglePopover(_ sender: AnyObject?) {
        if let popover {
            if popover.isShown {
                self.closePopover(sender: sender)
            } else {
                self.showPopover(sender: sender)
            }
        }
    }

    func showPopover(sender: AnyObject?) {
        if let button = statusBarItem.button {
            if let popover {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
            }
        }
    }

    func closePopover(sender: AnyObject?) {
        if let popover {
            popover.performClose(sender)
        }
    }
}
