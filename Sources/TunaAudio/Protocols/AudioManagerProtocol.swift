import Foundation
import TunaTypes

public protocol AudioManagerProtocol {
    var selectedOutputDevice: AudioDevice? { get }
    var outputVolume: Float { get }
}
