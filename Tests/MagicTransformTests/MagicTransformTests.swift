import XCTest
@testable import Tuna

final class MagicTransformTests: XCTestCase {
    
    @MainActor
    func testMagicTransformManagerInitialState() async {
        let manager = MagicTransformManager.shared
        
        // 验证初始状态
        let isProcessing = manager.isProcessing
        let errorMessage = manager.errorMessage
        let lastResult = manager.lastResult
        
        XCTAssertFalse(isProcessing)
        XCTAssertEqual(errorMessage, "")
        XCTAssertEqual(lastResult, "")
    }
    
    func testPresetStyleEnumCases() {
        // 验证枚举定义完整
        let allCases = PresetStyle.allCases
        XCTAssertEqual(allCases.count, 3)
        XCTAssertTrue(allCases.contains(.abit))
        XCTAssertTrue(allCases.contains(.concise))
        XCTAssertTrue(allCases.contains(.custom))
    }
    
    func testPromptTemplateLibrary() {
        // 验证模板库包含所有预设
        let library = PromptTemplate.library
        XCTAssertEqual(library.count, 3)
        
        // 验证模板内容
        XCTAssertEqual(library[.abit]?.system, "Rephrase to sound a bit more native.")
        XCTAssertEqual(library[.concise]?.system, "Summarize concisely in ≤2 lines.")
        XCTAssertEqual(library[.custom]?.system, "")
    }
    
    // 注意：由于需要API密钥，不测试实际的API调用
    
    @MainActor
    func testMagicTransformManagerEmptyInput() async {
        let manager = MagicTransformManager()
        
        // 重置状态
        manager.isProcessing = false
        manager.errorMessage = ""
        manager.lastResult = "previous result"
        
        // 确保magic功能启用
        TunaSettings.shared.magicEnabled = true
        
        // 测试空输入
        await manager.run(raw: "")
        
        // 空输入直接返回，不处理，所以应该没有错误
        XCTAssertFalse(manager.isProcessing)
        // 新实现中空输入会直接返回，不设置错误信息
        XCTAssertEqual(manager.errorMessage, "")
        // lastResult应该保持不变
        XCTAssertEqual(manager.lastResult, "previous result")
    }
} 