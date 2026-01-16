import Foundation

/// Protocol defining an LLM provider capabilities.
public protocol LLMProvider: Sendable {
    func process(text: String, systemPrompt: String) async throws -> String
}

/// A pass-through provider for when no LLM processing is needed.
public struct DirectProvider: LLMProvider {
    public init() {}
    public func process(text: String, systemPrompt: String) async throws -> String {
        return text
    }
}

/// A mock provider for cloud/local simulation until fully implemented.
public struct MockProvider: LLMProvider {
    public init() {}
    public func process(text: String, systemPrompt: String) async throws -> String {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5s
        return "[Processed]: \(text)"
    }
}
