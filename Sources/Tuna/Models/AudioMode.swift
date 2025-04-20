import Foundation

/// Represents an audio mode configuration for quick switching between different scenarios
struct AudioMode: Identifiable, Codable, Equatable {
    /// Unique identifier
    var id: String
    /// Mode name (e.g., "Meeting", "Study")
    var name: String
    /// Default output device UID
    var outputDeviceUID: String
    /// Default input device UID
    var inputDeviceUID: String
    /// Output device volume (0-1)
    var outputVolume: Float
    /// Input device volume (0-1)
    var inputVolume: Float
    /// Whether this is an automatic mode
    var isAutomatic: Bool

    /// Create a new audio mode
    init(
        id: String = UUID().uuidString,
        name: String,
        outputDeviceUID: String,
        inputDeviceUID: String,
        outputVolume: Float = 0.5,
        inputVolume: Float = 0.5,
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

    static func == (lhs: AudioMode, rhs: AudioMode) -> Bool {
        lhs.id == rhs.id
    }
}
