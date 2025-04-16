// @module: TabRouter
// @created_by_cursor: yes
// @summary: 管理应用标签页状态的路由器
// @depends_on: MenuBarView

import SwiftUI
import os.log

final class TabRouter: ObservableObject {
    @Published var current: String = "devices" {
        didSet {
            print("🧭 TabRouter.current 变更：", oldValue, "→", current,
                  "at", Thread.isMainThread ? "Main" : "BG",
                  ObjectIdentifier(self))
            Logger(subsystem:"ai.tuna", category:"Shortcut")
                .notice("🧭 current: \(oldValue) → \(self.current)")
        }
    }
    static let shared = TabRouter()          // 简单单例
    
    static func switchTo(_ id: String) {
        DispatchQueue.main.async {              // 保证在主线程
            print("🔄 switchTo \(id), router =", ObjectIdentifier(TabRouter.shared), "current before =", TabRouter.shared.current)
            Logger(subsystem:"ai.tuna",category:"Shortcut").notice("[TabRouter] switched to \(id)")
            TabRouter.shared.current = id
            print("ROUTER-DBG [1]", ObjectIdentifier(TabRouter.shared), TabRouter.shared.current)
        }
    }
    
    init() {
        print("👋 TabRouter initialized, id:", ObjectIdentifier(self))
    }
    
    deinit {
        print("❌ TabRouter deinit") // 单例不应该被释放，这是个诊断日志
    }
} 