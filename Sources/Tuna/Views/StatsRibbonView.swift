// @module: StatsRibbonView
// @created_by_cursor: yes
// @summary: 显示应用统计数据的Ribbon组件
// @depends_on: StatsStore

import SwiftUI

/// 显示单个统计数据的组件
struct StatPill: View {
    let value: Int
    let label: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(TunaTheme.textPri)
            
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(TunaTheme.textSec)
        }
        .frame(minWidth: 65)
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(TunaTheme.panel.opacity(0.3))
        .cornerRadius(6)
    }
}

/// 统计数据横幅视图
struct StatsRibbonView: View {
    @ObservedObject var store: StatsStore
    
    var body: some View {
        HStack(spacing: 8) {
            StatPill(value: store.consecutiveDays, label: "days in")
            StatPill(value: store.wordsFreed, label: "words freed")
            StatPill(value: store.smartSwaps, label: "smart swaps")
        }
        .padding(.vertical, 2)
    }
    
    /// 创建预览用实例
    static func preview() -> some View {
        StatsRibbonView(store: StatsStore.preview())
    }
}

struct StatsRibbonView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            StatsRibbonView(store: StatsStore.preview())
                .padding()
        }
        .background(Color.black.opacity(0.1))
        .previewLayout(.sizeThatFits)
    }
} 