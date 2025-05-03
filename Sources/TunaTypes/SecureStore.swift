import Foundation

// MARK: - Concrete implementation (kept for now, but _does not_ import TunaCore)

public final class SecureStore: SecureStoreProtocol {
    public static let shared: SecureStore = .init()
    public static let defaultAccount = "tuna_default"

    public static func currentAPIKey() -> String? {
        try? SecureStore.load(key: SecureStore.defaultAccount)
    }

    public static func setAPIKey(_ key: String) async {
        try? SecureStore.save(key: SecureStore.defaultAccount, value: key)
    }

    public static func save(key: String, value: String) throws {
        let data = value.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        if status == errSecDuplicateItem {
            let updateQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: key,
            ]
            let updateAttributes: [String: Any] = [
                kSecValueData as String: data,
            ]
            SecItemUpdate(updateQuery as CFDictionary, updateAttributes as CFDictionary)
        }
    }

    public static func load(key: String) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecSuccess, let data = result as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }

    public static func delete(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(query as CFDictionary)
    }

    // Protocol instance methods
    public func set(value: Data, forKey key: String, account: String) throws {
        // 这里假设 key 用于 account，兼容原有实现
        try SecureStore.save(key: account, value: String(data: value, encoding: .utf8) ?? "")
    }

    public func data(forKey key: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecSuccess, let data = result as? Data {
            return data
        }
        return nil
    }

    public func load(key: String, account: String) throws -> String? {
        // 这里假设 key 用于 account，兼容原有实现
        try SecureStore.load(key: account)
    }
}
