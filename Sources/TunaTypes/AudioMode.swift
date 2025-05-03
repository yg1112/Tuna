import Foundation

public struct AudioMode: Identifiable, Codable, Hashable {
    public let id: String
    public let name: String
    public var inputVolume: Float
    public var outputVolume: Float
    public var isActive: Bool
    public var outputDeviceUID: String?
    public var inputDeviceUID: String?
    public var isAutomatic: Bool = false

    public init(
        id: String = UUID().uuidString,
        name: String,
        inputVolume: Float,
        outputVolume: Float,
        isActive: Bool
    ) {
        self.init(
            id: id,
            name: name,
            inputVolume: inputVolume,
            outputVolume: outputVolume,
            isActive: isActive,
            outputDeviceUID: nil,
            inputDeviceUID: nil,
            isAutomatic: false
        )
    }

    public init(
        id: String = UUID().uuidString,
        name: String,
        inputVolume: Float = 0,
        outputVolume: Float = 0,
        isActive: Bool = false,
        outputDeviceUID: String? = nil,
        inputDeviceUID: String? = nil,
        isAutomatic: Bool = false
    ) {
        self.id = id
        self.name = name
        self.inputVolume = inputVolume
        self.outputVolume = outputVolume
        self.isActive = isActive
        self.outputDeviceUID = outputDeviceUID
        self.inputDeviceUID = inputDeviceUID
        self.isAutomatic = isAutomatic
    }

    public static func == (lhs: AudioMode, rhs: AudioMode) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
}
