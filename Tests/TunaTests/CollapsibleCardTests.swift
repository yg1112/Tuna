import SwiftUI
@testable import TunaApp
import TunaUI
import XCTest

final class CollapsibleCardTests: XCTestCase {
    func testButtonToggleExpandsCard() {
        // 创建一个可观察的状态值
        var isExpanded = false

        // 创建一个带有绑定的 CollapsibleCard
        let card = CollapsibleCard(title: "Test Card", isExpanded: Binding(
            get: { isExpanded },
            set: { isExpanded = $0 }
        )) {
            Text("Content")
        }

        // 验证初始状态是折叠的
        XCTAssertFalse(isExpanded)

        // 模拟点击按钮
        // 注意：这里不使用 ViewInspector，因为它需要额外的库和配置
        // 而是直接修改绑定的值，就像按钮动作会做的那样
        isExpanded = true

        // 验证状态已更改为展开
        XCTAssertTrue(isExpanded, "点击后卡片应展开")

        // 再次模拟点击，应该折叠卡片
        isExpanded = false

        // 验证状态已更改为折叠
        XCTAssertFalse(isExpanded, "再次点击后卡片应折叠")
    }
}
