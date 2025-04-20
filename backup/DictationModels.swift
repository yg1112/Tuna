import Foundation
import SwiftUI

public enum DictationState: Int, Equatable {
    case idle = 0
    case recording = 1
    case paused = 2
    case processing = 3
    case error = 4
}

public protocol DictationManagerProtocol: ObservableObject {
    var state: DictationState { get set }
    var progressMessage: String { get set }
    var transcribedText: String { get set }

    func startRecording()
    func pauseRecording()
    func stopRecording()
    func getDocumentsDirectory() -> URL
}

public struct DictationView: View {
    public var body: some View {
        Text("DictationView")
    }

    public init() {}
}
