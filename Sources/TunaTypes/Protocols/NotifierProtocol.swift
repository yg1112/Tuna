import Foundation

public protocol NotifierProtocol {
    @discardableResult
    static func post(_ name: Notification.Name, object: Any?) -> Bool
}
