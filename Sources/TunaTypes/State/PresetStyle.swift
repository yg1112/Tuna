import Foundation

public enum PresetStyle: String, CaseIterable, Codable {
    case none
    case formal
    case casual
    case concise
    case custom

    public var name: String {
        switch self {
            case .none: "None"
            case .formal: "Formal"
            case .casual: "Casual"
            case .concise: "Concise"
            case .custom: "Custom"
        }
    }

    public var prompt: String {
        switch self {
            case .none: ""
            case .formal: "Please make this text more formal and professional:"
            case .casual: "Please make this text more casual and conversational:"
            case .concise: "Please make this text more concise and to the point:"
            case .custom: "Transform this text according to custom rules:"
        }
    }
}
