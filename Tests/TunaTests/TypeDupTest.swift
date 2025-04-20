import XCTest
@testable import Tuna

final class TypeDupTest: XCTestCase {
    func testNoDuplicateTypes() throws {
        let fileManager = FileManager.default
        let sourcesPath = try XCTUnwrap(Bundle.module.resourcePath)?
            .replacingOccurrences(of: "TunaTests.bundle/Contents/Resources", with: "../../Sources/Tuna")
        
        var typeDeclarations: [String: String] = [:] // typeName: filePath
        
        // Recursively find all .swift files
        if let enumerator = fileManager.enumerator(
            at: URL(fileURLWithPath: sourcesPath),
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) {
            for case let fileURL as URL in enumerator {
                guard fileURL.pathExtension == "swift" else { continue }
                
                // Skip backup files
                let path = fileURL.path
                XCTAssertFalse(
                    path.contains("backup"),
                    "Found backup file that should be removed: \(path)"
                )
                
                // Read file content
                let content = try String(contentsOf: fileURL)
                
                // Find type declarations using regex
                let typePattern = #"(class|struct|enum)\s+(\w+)"#
                let regex = try NSRegularExpression(pattern: typePattern)
                let range = NSRange(content.startIndex..<content.endIndex, in: content)
                
                let matches = regex.matches(in: content, range: range)
                for match in matches {
                    let typeNameRange = match.range(at: 2)
                    if let range = Range(typeNameRange, in: content) {
                        let typeName = String(content[range])
                        
                        if let existingFile = typeDeclarations[typeName] {
                            XCTFail(
                                "Duplicate type '\(typeName)' found in:\n1. \(existingFile)\n2. \(fileURL.path)"
                            )
                        } else {
                            typeDeclarations[typeName] = fileURL.path
                        }
                    }
                }
            }
        }
    }
} 