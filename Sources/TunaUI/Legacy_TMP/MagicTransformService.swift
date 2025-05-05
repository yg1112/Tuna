import Foundation
import TunaTypes

enum MagicTransformService {
    static func transform(_ raw: String, style: PresetStyle) async throws -> String {
        let template = PromptTemplate.forStyle(style)
        // TODO: replace with actual POST /v1/transform
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3s fake latency
        return raw // For now, just return the raw text
    }
}
