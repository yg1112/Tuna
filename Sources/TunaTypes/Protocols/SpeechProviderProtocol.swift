import Foundation

public protocol SpeechProviderProtocol {
    static var shared: Self { get }
    func transcribe(audioURL: URL) async throws -> String
}
