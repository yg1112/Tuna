import Foundation
import TunaTypes

public protocol AudioServiceProtocol {
    nonisolated func currentAudioState() async -> AudioState
    func selectOutputDevice(_ device: any AudioDevice) async
    func selectInputDevice(_ device: any AudioDevice) async
    func setVolumeForDevice(_ device: any AudioDevice, volume: Float) async
}

@MainActor
public struct LiveAudioService: AudioServiceProtocol {
    private let manager: any AudioManagerProtocol

    public init(manager: any AudioManagerProtocol) {
        self.manager = manager
    }

    // MARK: - State Access

    public nonisolated var inputDevices: [any AudioDevice] {
        get async {
            await self.manager.inputDevices
        }
    }

    public nonisolated var outputDevices: [any AudioDevice] {
        get async {
            await self.manager.outputDevices
        }
    }

    public nonisolated var selectedInputDevice: (any AudioDevice)? {
        get async {
            await self.manager.selectedInputDevice
        }
    }

    public nonisolated var selectedOutputDevice: (any AudioDevice)? {
        get async {
            await self.manager.selectedOutputDevice
        }
    }

    public nonisolated var inputVolume: Float {
        get async {
            await self.manager.inputVolume
        }
    }

    public nonisolated var outputVolume: Float {
        get async {
            await self.manager.outputVolume
        }
    }

    public nonisolated func currentAudioState() async -> AudioState {
        await self.manager.currentAudioState()
    }

    // MARK: - Device Operations

    @MainActor public func selectOutputDevice(_ device: any AudioDevice) async {
        await self.manager.selectOutputDevice(device)
    }

    @MainActor public func selectInputDevice(_ device: any AudioDevice) async {
        await self.manager.selectInputDevice(device)
    }

    @MainActor public func setVolumeForDevice(_ device: any AudioDevice, volume: Float) async {
        await self.manager.setVolumeForDevice(device, volume: volume)
    }

    @MainActor public func setOutputVolume(_ volume: Float) async {
        if let device = await selectedOutputDevice {
            await self.setVolumeForDevice(device, volume: volume)
        }
    }

    @MainActor public func setInputVolume(_ volume: Float) async {
        if let device = await selectedInputDevice {
            await self.setVolumeForDevice(device, volume: volume)
        }
    }
}
