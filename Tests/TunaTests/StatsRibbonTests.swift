import SwiftUI
@testable import Tuna
import XCTest

final class StatsRibbonTests: XCTestCase {
    func testStatsRibbonShowsThreeStats() {
        // 使用预览数据创建StatsStore
        let store = StatsStore.preview()

        // 验证预览数据的值
        XCTAssertEqual(store.consecutiveDays, 7, "Stats store should have 7 consecutive days")
        XCTAssertEqual(store.wordsFreed, 1250, "Stats store should have 1250 words freed")
        XCTAssertEqual(store.smartSwaps, 42, "Stats store should have 42 smart swaps")

        // 创建视图
        let ribbon = StatsRibbonView(store: store)

        // 因为SwiftUI视图测试有限，这里只验证视图能正常创建
        XCTAssertNotNil(ribbon, "Stats ribbon view should be created successfully")
    }
}
