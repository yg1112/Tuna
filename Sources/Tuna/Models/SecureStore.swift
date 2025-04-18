// @module: SecureStore
// @created_by_cursor: yes
// @summary: 安全存储API密钥（Keychain包装）
// @depends_on: None

import Foundation
import Security

/// 安全存储工具，封装Keychain API以安全存储敏感信息如API密钥
enum SecureStore {
    /// 服务标识符，用于在Keychain中唯一标识存储的条目
    private static let service = "ai.tuna.openai"
    
    /// 默认账户名
    static let defaultAccount = "default"
    
    /// Keychain错误类型
    enum KeychainError: Error {
        case duplicateItem
        case itemNotFound
        case unexpectedStatus(OSStatus)
    }
    
    /// 将值安全地存储到Keychain
    /// - Parameters:
    ///   - key: 要存储的密钥标识符
    ///   - value: 要存储的值
    static func save(key: String, value: String) throws {
        // 创建一个查询以检查项目是否已存在
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        // 删除任何现有项目
        SecItemDelete(query as CFDictionary)
        
        // 添加新项目
        let valueData = value.data(using: .utf8)!
        let attributes: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: valueData
        ]
        
        let status = SecItemAdd(attributes as CFDictionary, nil)
        
        // 检查状态
        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
    
    /// 从Keychain安全加载值
    /// - Parameter key: 要加载的密钥标识符
    /// - Returns: 存储的值，如果未找到则返回nil
    static func load(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess, 
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return value
    }
    
    /// 从Keychain删除存储的值
    /// - Parameter key: 要删除的密钥标识符
    static func delete(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        // 如果项目不存在，不视为错误
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
    
    /// 辅助函数：获取当前OpenAI API密钥
    /// 首先尝试从Keychain获取，然后尝试从环境变量获取
    /// - Returns: API密钥，如果都没有找到则返回nil
    static func currentAPIKey() -> String? {
        // 首先检查Keychain中是否有存储的密钥
        if let key = load(key: defaultAccount), !key.isEmpty {
            return key
        }
        
        // 然后检查环境变量
        if let envKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !envKey.isEmpty {
            return envKey
        }
        
        // 如果都没有找到，返回nil
        return nil
    }
} 