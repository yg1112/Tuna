// @module: TunaTheme
// @created_by_cursor: yes
// @summary: 定义 Tuna 应用的主题颜色和样式
// @depends_on: None

import SwiftUI

// 主题定义，包含亮色和暗色模式的颜色值
struct TunaTheme {
    // 亮色模式颜色
    struct Light {
        static let background = Color(hex: "FDFBF7") // Hermès Ivory 背景色
        static let panel = Color.white // 面板白色
        static let border = Color(hex: "E6E1D6") // 边框颜色
        static let textPrimary = Color(hex: "2B2B2B") // 主要文本颜色
        static let textSecondary = Color(hex: "6F6558") // 次要文本颜色
        static let accent = Color(hex: "E86A24") // 橙色强调色
    }
    
    // 暗色模式颜色
    struct Dark {
        static let background = Color(hex: "1C1C1E") // 暗色背景
        static let panel = Color(hex: "2D2D2F").opacity(0.9) // 面板颜色，90%不透明度
        static let border = Color.white.opacity(0.12) // 边框颜色，12%不透明度
        static let textPrimary = Color(hex: "F5F5F7") // 主要文本颜色
        static let textSecondary = Color(hex: "B3B3B7") // 次要文本颜色
        static let accent = Color(hex: "4169E1") // Bleu Indigo 蓝色强调色
    }
    
    // 当前主题，根据系统亮/暗模式自动切换
    @Environment(\.colorScheme) static var colorScheme
    
    // 背景颜色
    static var background: Color {
        colorScheme == .dark ? Dark.background : Light.background
    }
    
    // 面板颜色
    static var panel: Color {
        colorScheme == .dark ? Dark.panel : Light.panel
    }
    
    // 边框颜色
    static var border: Color {
        colorScheme == .dark ? Dark.border : Light.border
    }
    
    // 主要文本颜色
    static var textPri: Color {
        colorScheme == .dark ? Dark.textPrimary : Light.textPrimary
    }
    
    // 次要文本颜色
    static var textSec: Color {
        colorScheme == .dark ? Dark.textSecondary : Light.textSecondary
    }
    
    // 强调色
    static var accent: Color {
        colorScheme == .dark ? Dark.accent : Light.accent
    }
}

// 颜色扩展，支持十六进制初始化
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
} 