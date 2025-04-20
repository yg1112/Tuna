import Foundation

// @module: Utilities
// @created_by_cursor: yes
// @summary: Provides deterministic values for testing purposes
// @depends_on: None

/// Protocol for providing current time
protocol NowProvider {
    var now: Date { get }
}

/// Real implementation that uses the system time
struct RealNowProvider: NowProvider {
    var now: Date { Date() }
}

/// Static implementation that always returns the same date
struct StaticNowProvider: NowProvider {
    let fixedDate: Date

    init(_ date: Date) {
        fixedDate = date
    }

    var now: Date { fixedDate }
}

/// Extension for testing convenience
extension NowProvider where Self == RealNowProvider {
    static var real: NowProvider { RealNowProvider() }

    static func `static`(_ date: Date) -> NowProvider {
        StaticNowProvider(date)
    }
}

/// Protocol for providing UUIDs
protocol UUIDProvider {
    func uuid() -> UUID
}

/// Real implementation that generates random UUIDs
struct RealUUIDProvider: UUIDProvider {
    func uuid() -> UUID { UUID() }
}

/// Static implementation that always returns the same UUID
struct StaticUUIDProvider: UUIDProvider {
    let fixedUUID: UUID

    init(_ uuid: UUID) {
        fixedUUID = uuid
    }

    func uuid() -> UUID { fixedUUID }
}

/// Extension for testing convenience
extension UUIDProvider where Self == RealUUIDProvider {
    static var real: UUIDProvider { RealUUIDProvider() }

    static func `static`(_ uuid: UUID) -> UUIDProvider {
        StaticUUIDProvider(uuid)
    }
}

/// Common constants for deterministic testing
enum TestConstants {
    /// A fixed date for snapshot testing (April 25, 2024)
    static let previewDate = Date(timeIntervalSince1970: 1_714_000_000)

    /// A fixed UUID for snapshot testing
    static let previewUUID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
}
