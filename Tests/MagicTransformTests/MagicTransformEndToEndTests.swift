@testable import Tuna
import XCTest

final class MagicTransformEndToEndTests: XCTestCase {
    var manager: MagicTransformManager!

    @MainActor
    override func setUpWithError() throws {
        try super.setUpWithError()
        // 直接在MainActor上下文中初始化
        self.manager = MagicTransformManager()
    }

    @MainActor
    override func tearDownWithError() throws {
        self.manager = nil
        try super.tearDownWithError()
    }

    // 端到端功能测试：验证整个变换流程
    @MainActor
    func testEndToEndTransformation() async throws {
        // 确保有API密钥（测试前需要设置）
        if TunaSettings.shared.dictationApiKey.isEmpty {
            // 设置测试API密钥以便测试
            TunaSettings.shared.dictationApiKey = ProcessInfo.processInfo
                .environment["TEST_API_KEY"] ?? ""

            // 如果无法获取测试API密钥，则跳过测试
            if TunaSettings.shared.dictationApiKey.isEmpty {
                throw XCTSkip("Skipping end-to-end test: No API key available in the environment")
            }
        }

        // 启用Magic功能
        TunaSettings.shared.magicEnabled = true

        // 准备测试数据
        let testInput = "这是一个测试文本，重复重复的内容可以被优化。重复重复的内容可以被优化。"

        // 直接运行变换
        await manager.run(raw: testInput)

        // 检查是否有错误消息，如果有"API key"相关错误，则跳过测试
        if !self.manager.errorMessage.isEmpty {
            if self.manager.errorMessage.contains("API key") || self.manager.errorMessage
                .contains("Incorrect API key")
            {
                throw XCTSkip("Skipping test due to API key error: \(self.manager.errorMessage)")
            } else {
                // 其他错误仍然会导致测试失败
                XCTFail("发生意外错误: \(self.manager.errorMessage)")
            }
        } else {
            // 没有错误，验证结果
            XCTAssertFalse(self.manager.isProcessing, "处理应当已经完成")
            XCTAssertFalse(self.manager.lastResult.isEmpty, "结果不应为空")
            XCTAssertNotEqual(self.manager.lastResult, testInput, "变换后结果应与输入不同")

            // 验证实际内容（近似检查）
            XCTAssertTrue(self.manager.lastResult.count < testInput.count, "优化后的文本应更简洁")
        }
    }

    // 测试无网络情况下的行为
    @MainActor
    func testOfflineHandling() async {
        // 可在实际项目中实现离线模式测试
        // 通过模拟断网情况或使用模拟的URLSession
    }

    // 测试用户取消正在处理的请求
    @MainActor
    func testCancellation() async {
        // 可实现取消正在处理的请求功能
        // 然后测试取消后的状态恢复
    }
}
