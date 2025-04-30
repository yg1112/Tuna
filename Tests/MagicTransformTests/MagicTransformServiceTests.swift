@testable import TunaApp
import TunaCore
import XCTest

final class MagicTransformServiceTests: XCTestCase {
    func testEmptyInputReturnsEmpty() async throws {
        // 验证空输入直接返回
        let result = try await MagicTransformService.transform(
            "",
            template: PromptTemplate(id: .abit, system: "Test")
        )
        XCTAssertEqual(result, "")
    }

    func testMissingAPIKeyThrowsError() async throws {
        // 保存原始API密钥
        let originalApiKey = TunaSettings.shared.dictationApiKey

        // 清除API密钥
        TunaSettings.shared.dictationApiKey = ""

        do {
            _ = try await MagicTransformService.transform(
                "Test input",
                template: PromptTemplate(id: .abit, system: "Test")
            )
            XCTFail("Should throw error when API key is missing")
        } catch {
            XCTAssertTrue(
                error.localizedDescription.contains("API key not set"),
                "Expected API key error"
            )
        }

        // 恢复原始API密钥
        TunaSettings.shared.dictationApiKey = originalApiKey
    }

    // 模拟API响应测试
    func testResponseParsing() {
        // 这里我们测试响应解析逻辑
        // 通常需要使用URLProtocol或依赖注入来模拟网络请求
        // 因为实际API调用需要有效密钥，所以这个测试只是一个示例框架

        // 实际项目中，推荐使用以下方式进行完整测试：
        // 1. 创建MockURLProtocol来拦截网络请求
        // 2. 注入自定义的URLSession到Service中
        // 3. 准备模拟的JSON响应数据
        // 4. 验证请求和响应处理
    }

    // 测试错误处理情况
    func testErrorHandling() {
        // 模拟不同的HTTP错误码和API错误响应
        // 同样，这需要使用URLProtocol模拟或依赖注入
    }
}
