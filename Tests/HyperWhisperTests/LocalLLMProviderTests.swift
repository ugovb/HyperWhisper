import XCTest
@testable import HyperWhisper

final class LocalLLMProviderTests: XCTestCase {
    
    func testLocalProviderRouting() async throws {
        let orchestrator = LLMOrchestrator()
        let mode = Mode(name: "Test Local", systemPrompt: "Fix", providerType: .local)
        
        let input = "Hello"
        let output = try await orchestrator.process(input, with: mode)
        
        XCTAssertTrue(output.contains("[Local Refinement]"), "Should use LocalLLMProvider which adds prefix")
        XCTAssertTrue(output.contains(input))
    }
}
