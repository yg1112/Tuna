// @module: TunaTab
// @created_by_cursor: yes
// @summary: 定义 Tuna 主视图的标签页
// @depends_on: TabRouter

import SwiftUI

// 标签页枚举，仅包含 Devices 和 Whispen 两个选项（移除了 Stats）
enum TunaTab: String, CaseIterable, Identifiable {
    case devices = "Devices"
    case whispen = "Whispen"

    var id: String { rawValue }

    // 获取标签图标
    var icon: String {
        switch self {
            case .devices:
                "speaker.wave.2.fill"
            case .whispen:
                "waveform"
        }
    }

    // 将 TunaTab 映射到 TabRouter 中的字符串值
    var routerValue: String {
        switch self {
            case .devices:
                "devices"
            case .whispen:
                "dictation" // 保持与现有代码兼容
        }
    }

    // 从 TabRouter 的字符串值创建 TunaTab
    static func fromRouterValue(_ value: String) -> TunaTab {
        switch value {
            case "devices":
                .devices
            case "dictation":
                .whispen
            default:
                .devices // 默认值
        }
    }
}

// 扩展 TabRouter 添加 TunaTab 相关方法
extension TabRouter {
    // 当前标签页（计算属性）
    var currentTab: TunaTab {
        get {
            TunaTab.fromRouterValue(current)
        }
        set {
            current = newValue.routerValue
        }
    }

    // 静态方法切换到指定标签页
    static func switchToTab(_ tab: TunaTab) {
        switchTo(tab.routerValue)
    }
}
