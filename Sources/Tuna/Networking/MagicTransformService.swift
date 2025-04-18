import Foundation

struct MagicTransformService {
    static func transform(_ raw: String, template: PromptTemplate) async throws -> String {
        // TODO: replace with actual POST /v1/transform
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3s fake latency
        return "[MAGIC] " + raw             // echo for now
    }
} 