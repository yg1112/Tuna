import Foundation

public struct PromptTemplate: Codable, Hashable {
    public let id: String
    public let prompt: String

    public init(id: String, prompt: String) {
        self.id = id
        self.prompt = prompt
    }

    public static func forStyle(_ style: PresetStyle) -> PromptTemplate {
        PromptTemplate(id: style.rawValue, prompt: style.prompt)
    }
}
