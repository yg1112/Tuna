import Foundation

/// Lightweight notification hub (thread-safe)
public final actor Notifier: NotifierProtocol {
    public static let shared = Notifier()

    @discardableResult
    public static func post(_ name: Notification.Name, object: Any? = nil) -> Bool {
        NotificationCenter.default.post(name: name, object: object)
        return true
    }
}
