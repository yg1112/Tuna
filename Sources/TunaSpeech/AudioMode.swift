import Foundation

/// Represents an audio mode configuration for quick switching between different scenarios
public struct AudioMode: Identifiable, Codable, Equatable {
    /// Unique identifier
    public var id: String
    /// Display name
    public var name: String
    /// Output device UID
    public var outputDeviceUID: String
    /// Input device UID
    public var inputDeviceUID: String
    /// Output volume (0-1)
    public var outputVolume: Float?
    /// Input volume (0-1)
    public var inputVolume: Float?
    /// Whether this mode is automatic
    public var isAutomatic: Bool

    public init(
        id: String = UUID().uuidString,
        name: String,
        outputDeviceUID: String,
        inputDeviceUID: String,
        outputVolume: Float? = nil,
        inputVolume: Float? = nil,
        isAutomatic: Bool = false
    ) {
        self.id = id
        self.name = name
        self.outputDeviceUID = outputDeviceUID
        self.inputDeviceUID = inputDeviceUID
        self.outputVolume = outputVolume
        self.inputVolume = inputVolume
        self.isAutomatic = isAutomatic
    }

    public static func == (lhs: AudioMode, rhs: AudioMode) -> Bool {
        lhs.id == rhs.id
    }
}
