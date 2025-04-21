import Foundation

// TEMPORARY STUB - Minimal implementation for build pass
public class TunaAudioManager {
    public static let shared = TunaAudioManager()
    
    private init() {}
    
    // Stub properties to satisfy compile-time requirements
    public var outputDevices: [AudioDevice] = []
    public var inputDevices: [AudioDevice] = []
    public var selectedOutputDevice: AudioDevice?
    public var selectedInputDevice: AudioDevice?
} 