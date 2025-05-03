@preconcurrency
public protocol AudioServiceProtocol {
    // State access - nonisolated for thread-safe read-only access
    nonisolated var inputDevices: [any AudioDevice] { get async }
    nonisolated var outputDevices: [any AudioDevice] { get async }
    nonisolated var selectedInputDevice: (any AudioDevice)? { get async }
    nonisolated var selectedOutputDevice: (any AudioDevice)? { get async }
    nonisolated var inputVolume: Float { get async }
    nonisolated var outputVolume: Float { get async }

    // Current state snapshot
    nonisolated func currentAudioState() async -> AudioState

    // Device operations - async to support proper actor isolation
    @MainActor func selectOutputDevice(_ device: any AudioDevice) async
    @MainActor func selectInputDevice(_ device: any AudioDevice) async
    @MainActor func setOutputVolume(_ volume: Float) async
    @MainActor func setInputVolume(_ volume: Float) async
}
