import Foundation

/// Abstraction for audio-device management (decouples TunaCore from TunaAudio)
@preconcurrency
public protocol AudioManagerProtocol {
    // State access - nonisolated for thread-safe read-only access
    nonisolated var inputDevices: [any AudioDevice] { get async }
    nonisolated var outputDevices: [any AudioDevice] { get async }
    nonisolated var selectedInputDevice: (any AudioDevice)? { get async }
    nonisolated var selectedOutputDevice: (any AudioDevice)? { get async }
    nonisolated var inputVolume: Float { get async }
    nonisolated var outputVolume: Float { get async }

    // State access - async to support proper actor isolation
    nonisolated func currentAudioState() async -> AudioState

    // Device selection
    func selectOutputDevice(_ device: any AudioDevice) async
    func selectInputDevice(_ device: any AudioDevice) async

    // Volume control
    func setVolumeForDevice(_ device: any AudioDevice, volume: Float) async
}
