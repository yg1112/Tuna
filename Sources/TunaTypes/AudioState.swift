public struct AudioState {
    public let inputDevices: [any AudioDevice]
    public let outputDevices: [any AudioDevice]
    public let selectedInputDevice: (any AudioDevice)?
    public let selectedOutputDevice: (any AudioDevice)?
    public let inputVolume: Float
    public let outputVolume: Float

    public init(
        inputDevices: [any AudioDevice],
        outputDevices: [any AudioDevice],
        selectedInputDevice: (any AudioDevice)?,
        selectedOutputDevice: (any AudioDevice)?,
        inputVolume: Float,
        outputVolume: Float
    ) {
        self.inputDevices = inputDevices
        self.outputDevices = outputDevices
        self.selectedInputDevice = selectedInputDevice
        self.selectedOutputDevice = selectedOutputDevice
        self.inputVolume = inputVolume
        self.outputVolume = outputVolume
    }
}
