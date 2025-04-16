// @module: TabRouter
// @created_by_cursor: yes
// @summary: 管理应用标签页状态的路由器
// @depends_on: MenuBarView

import SwiftUI

final class TabRouter: ObservableObject {
    @Published var current: String = "devices"
    static let shared = TabRouter()          // 简单单例
    
    static func switchTo(_ id: String) {
        DispatchQueue.main.async {              // 保证在主线程
            print("[TabRouter] switched to \(id)")
            Logger(subsystem:"ai.tuna",category:"Shortcut").notice("[TabRouter] switched to \(id)")
            TabRouter.shared.current = id
        }
    }
} 