// @module: TunaCard
// @created_by_cursor: yes
// @summary: 定义 Tuna 卡片视图修饰器
// @depends_on: TunaTheme

import SwiftUI

// TunaCard 视图修饰器，提供统一的卡片样式
struct TunaCard: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(
                ZStack {
                    // 背景模糊效果
                    TunaTheme.panel
                        .blur(radius: 0)
                    
                    // 卡片边框
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(TunaTheme.border, lineWidth: 1)
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))
            )
            // 暗模式下添加阴影
            .shadow(color: colorScheme == .dark ? .black.opacity(0.6) : .black.opacity(0.1), 
                    radius: colorScheme == .dark ? 6 : 4,
                    x: 0,
                    y: colorScheme == .dark ? 2 : 1)
    }
}

// TunaCardHeader 视图修饰器，用于卡片标题
struct TunaCardHeader: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(TunaTheme.textPri)
            .padding(.bottom, 8)
    }
}

// TunaCardInfo 视图修饰器，用于卡片内的信息文本
struct TunaCardInfo: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 13))
            .foregroundColor(TunaTheme.textPri)
            .lineLimit(1)
            .truncationMode(.middle)
    }
}

// 视图扩展，为所有视图添加 tunaCard 修饰器
extension View {
    func tunaCard() -> some View {
        self.modifier(TunaCard())
    }
    
    func tunaCardHeader() -> some View {
        self.modifier(TunaCardHeader())
    }
    
    func tunaCardInfo() -> some View {
        self.modifier(TunaCardInfo())
    }
} 