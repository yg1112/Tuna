import Foundation
@testable import Tuna
import XCTest

// 模拟URL协议用于测试
class MockURLProtocol: URLProtocol {
    // 存储模拟响应的字典
    static var mockResponses = [URL: (data: Data, response: HTTPURLResponse, error: Error?)]()

    // 重置所有模拟数据
    static func reset() {
        mockResponses = [:]
    }

    // 注册模拟响应
    static func registerMockResponse(
        for url: URL,
        data: Data,
        statusCode: Int = 200,
        error: Error? = nil
    ) {
        let response = HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        mockResponses[url] = (data, response, error)
    }

    // 判断是否可以处理请求
    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    // 返回标准化的请求
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    // 开始加载请求
    override func startLoading() {
        guard let url = request.url else {
            client?.urlProtocolDidFinishLoading(self)
            return
        }

        // 获取模拟响应
        if let mockData = MockURLProtocol.mockResponses[url] {
            // 如果有错误，返回错误
            if let error = mockData.error {
                client?.urlProtocol(self, didFailWithError: error)
                return
            }

            // 发送响应和数据
            client?.urlProtocol(
                self,
                didReceive: mockData.response,
                cacheStoragePolicy: .notAllowed
            )
            client?.urlProtocol(self, didLoad: mockData.data)
        }

        // 完成加载
        client?.urlProtocolDidFinishLoading(self)
    }

    // 停止加载
    override func stopLoading() {}
}

class MagicTransformServiceMockTests: XCTestCase {
    var service: MagicTransformService!
    var session: URLSession!
    let apiURL = URL(string: "https://api.openai.com/v1/chat/completions")!

    override func setUp() {
        super.setUp()

        // 配置测试会话
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        session = URLSession(configuration: configuration)

        // 初始化服务，使用模拟会话
        service = MagicTransformService(session: session)

        // 设置API密钥
        TunaSettings.shared.dictationApiKey = "test_api_key"
    }

    override func tearDown() {
        MockURLProtocol.reset()
        session = nil
        service = nil
        super.tearDown()
    }

    // 测试成功的响应
    func testSuccessfulResponse() async throws {
        // 准备模拟JSON响应
        let responseJSON = """
        {
            "id": "test_id",
            "object": "chat.completion",
            "created": 1630000000,
            "model": "gpt-3.5-turbo",
            "choices": [
                {
                    "message": {
                        "role": "assistant",
                        "content": "This is a transformed text."
                    },
                    "index": 0,
                    "finish_reason": "stop"
                }
            ]
        }
        """

        let responseData = responseJSON.data(using: .utf8)!

        // 注册模拟响应
        MockURLProtocol.registerMockResponse(for: apiURL, data: responseData, statusCode: 200)

        // 执行转换
        let template = PromptTemplate(id: .concise, system: "Test system prompt")
        let result = try await service.transform("Test input", template: template)

        // 验证结果
        XCTAssertEqual(result, "This is a transformed text.")
    }

    // 测试API错误响应
    func testAPIErrorResponse() async {
        // 准备模拟错误响应
        let errorJSON = """
        {
            "error": {
                "message": "Invalid API key",
                "type": "invalid_request_error",
                "code": "invalid_api_key"
            }
        }
        """

        let errorData = errorJSON.data(using: .utf8)!

        // 注册模拟响应
        MockURLProtocol.registerMockResponse(for: apiURL, data: errorData, statusCode: 401)

        // 执行转换并捕获错误
        do {
            let template = PromptTemplate(id: .concise, system: "Test system prompt")
            _ = try await service.transform("Test input", template: template)
            XCTFail("应该抛出错误")
        } catch {
            // 验证错误
            let nsError = error as NSError
            XCTAssertEqual(nsError.code, 401)
            XCTAssertEqual(nsError.domain, "ai.tuna.error")
            XCTAssertTrue(nsError.localizedDescription.contains("API error: Invalid API key"))
        }
    }

    // 测试网络失败
    func testNetworkFailure() async {
        // 创建网络错误
        let networkError = NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorNotConnectedToInternet,
            userInfo: nil
        )

        // 注册错误响应
        MockURLProtocol.registerMockResponse(for: apiURL, data: Data(), error: networkError)

        // 执行转换并捕获错误
        do {
            let template = PromptTemplate(id: .concise, system: "Test system prompt")
            _ = try await service.transform("Test input", template: template)
            XCTFail("应该抛出错误")
        } catch {
            // 验证错误是网络错误
            XCTAssertEqual((error as NSError).domain, NSURLErrorDomain)
            XCTAssertEqual((error as NSError).code, NSURLErrorNotConnectedToInternet)
        }
    }

    // 测试空输入
    func testEmptyInput() async throws {
        let template = PromptTemplate(id: .concise, system: "Test system prompt")
        let result = try await service.transform("", template: template)
        XCTAssertEqual(result, "")
    }

    // 测试空API密钥
    func testEmptyAPIKey() async {
        // 设置空API密钥
        TunaSettings.shared.dictationApiKey = ""

        // 执行转换并捕获错误
        do {
            let template = PromptTemplate(id: .concise, system: "Test system prompt")
            _ = try await service.transform("Test input", template: template)
            XCTFail("应该抛出错误")
        } catch {
            // 验证错误
            let nsError = error as NSError
            XCTAssertEqual(nsError.code, 401)
            XCTAssertEqual(nsError.domain, "ai.tuna.error")
            XCTAssertTrue(nsError.localizedDescription.contains("API key not set"))
        }
    }
}
