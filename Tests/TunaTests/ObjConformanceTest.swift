import XCTest
@testable import Tuna

final class ObjConformanceTest: XCTestCase {
    // Whitelist of known ObservableObject types
    private let knownObservableObjects = [
        "UIState",
        "AudioManager",
        "DictationManager"
    ]
    
    func testObservedObjectConformance() throws {
        let fileManager = FileManager.default
        let sourcesPath = try XCTUnwrap(Bundle.module.resourcePath)?
            .replacingOccurrences(of: "TunaTests.bundle/Contents/Resources", with: "../../Sources/Tuna")
        
        // Recursively find all .swift files
        if let enumerator = fileManager.enumerator(
            at: URL(fileURLWithPath: sourcesPath),
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) {
            for case let fileURL as URL in enumerator {
                guard fileURL.pathExtension == "swift" else { continue }
                
                // Read file content
                let content = try String(contentsOf: fileURL)
                
                // Find @ObservedObject declarations
                let observedPattern = #"@ObservedObject\s+var\s+\w+\s*:\s*(\w+)"#
                let observedRegex = try NSRegularExpression(pattern: observedPattern)
                let range = NSRange(content.startIndex..<content.endIndex, in: content)
                
                let matches = observedRegex.matches(in: content, range: range)
                for match in matches {
                    let typeRange = match.range(at: 1)
                    if let range = Range(typeRange, in: content) {
                        let typeName = String(content[range])
                        
                        // Skip whitelisted types
                        guard !self.knownObservableObjects.contains(typeName) else { continue }
                        
                        // Find type declaration
                        let typePattern = #"(class|struct|enum)\s+\#(typeName).*\{"#
                        let typeRegex = try NSRegularExpression(pattern: typePattern)
                        let typeMatches = typeRegex.matches(in: content, range: range)
                        
                        for typeMatch in typeMatches {
                            let declarationRange = typeMatch.range(at: 0)
                            if let declRange = Range(declarationRange, in: content) {
                                let declaration = String(content[declRange])
                                XCTAssertTrue(
                                    declaration.contains("ObservableObject"),
                                    "Type '\(typeName)' is used with @ObservedObject but doesn't conform to ObservableObject protocol in file: \(fileURL.path)"
                                )
                            }
                        }
                    }
                }
            }
        }
    }
} 