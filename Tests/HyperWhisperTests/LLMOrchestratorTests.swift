import XCTest
import SwiftData
@testable import HyperWhisper

final class LLMOrchestratorTests: XCTestCase {
    
    func testDirectModeBypass() async throws {
        let orchestrator = LLMOrchestrator()
        let mode = Mode(name: "Test Direct", systemPrompt: "Ignore me", providerType: .none)
        
        let input = "Hello World"
        let output = try await orchestrator.process(input, with: mode)
        
        XCTAssertEqual(output, input, "Direct mode should return input exactly")
    }
    
    func testMockProviderRouting() async throws {
        let orchestrator = LLMOrchestrator()
        // Use .local which is currently mapped to LocalLLMProvider in Orchestrator
        let mode = Mode(name: "Test Local", systemPrompt: "Refine", providerType: .local)
        
        let input = "Hello"
        let output = try await orchestrator.process(input, with: mode)
        
        XCTAssertTrue(output.contains("[Local Refinement]"), "Should use LocalLLMProvider which adds prefix")
        XCTAssertTrue(output.contains(input))
    }
}
