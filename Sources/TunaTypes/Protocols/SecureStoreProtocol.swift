import Foundation

public protocol SecureStoreProtocol {
    static var shared: Self { get }
    static var defaultAccount: String { get }
    func load(key: String, account: String) throws -> String?
    func set(value: Data, forKey key: String, account: String) throws
}
