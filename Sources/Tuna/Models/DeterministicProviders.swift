import Foundation
import TunaSpeech

// @module: Utilities
// @created_by_cursor: yes
// @summary: Provides deterministic values for testing purposes
// @depends_on: TunaSpeech

/// Common constants for deterministic testing
enum TestConstants {
    /// A fixed date for snapshot testing (April 25, 2024)
    static let previewDate = Date(timeIntervalSince1970: 1_714_000_000)

    /// A fixed UUID for snapshot testing
    static let previewUUID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
}
