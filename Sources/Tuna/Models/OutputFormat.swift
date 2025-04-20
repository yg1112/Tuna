/// Defines the available output formats for transcription text
enum OutputFormat: String, CaseIterable {
    /// Plain text format (.txt)
    case plain = "txt"
    
    /// Markdown format (.md)
    case markdown = "md"
    
    /// Rich Text Format (.rtf)
    case rtf = "rtf"
    
    /// Returns the file extension for the format
    var fileExtension: String {
        self.rawValue
    }
    
    /// Returns a human-readable description of the format
    var description: String {
        switch self {
        case .plain:
            return "Plain Text"
        case .markdown:
            return "Markdown"
        case .rtf:
            return "Rich Text"
        }
    }
    
    /// Returns the UTType for the format
    var utType: String {
        switch self {
        case .plain:
            return "public.plain-text"
        case .markdown:
            return "net.daringfireball.markdown"
        case .rtf:
            return "public.rtf"
        }
    }
    
    func format(_ text: String) -> String {
        switch self {
        case .plain:
            return text
        case .markdown:
            // Basic markdown formatting could be added here
            return text
        case .rtf:
            // Basic RTF formatting could be added here
            return text
        }
    }
} 