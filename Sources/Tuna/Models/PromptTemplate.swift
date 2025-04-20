import Foundation

struct PromptTemplate: Codable {
    let name: String
    let description: String
    let prompt: String
    
    static let library: [String: PromptTemplate] = [
        "professional": PromptTemplate(
            name: "Professional",
            description: "Formal and business-like tone",
            prompt: "Transform the following text into a professional and formal tone, maintaining the original meaning but making it suitable for business communication:"
        ),
        "casual": PromptTemplate(
            name: "Casual",
            description: "Friendly and conversational tone",
            prompt: "Transform the following text into a casual and friendly tone, making it more conversational while maintaining the core message:"
        ),
        "academic": PromptTemplate(
            name: "Academic",
            description: "Scholarly and research-oriented tone",
            prompt: "Transform the following text into an academic style, using formal language and scholarly tone while preserving the essential information:"
        )
    ]
} 