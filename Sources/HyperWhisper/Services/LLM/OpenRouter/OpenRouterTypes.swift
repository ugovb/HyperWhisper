import Foundation

// MARK: - Allowed Models (Strict Constraint)

/// Les seuls modèles autorisés pour OpenRouter dans cette application.
/// Cette enum force le choix parmi les 3 modèles approuvés uniquement.
public enum OpenRouterModel: String, CaseIterable, Identifiable, Codable, Sendable {
    case gptNano5 = "openai/gpt-5-nano"
    case llama3_2_3b = "meta-llama/llama-3.2-3b-instruct"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .gptNano5: return "GPT Nano 5"
        case .llama3_2_3b: return "Llama 3.2 3B"
        }
    }
    
    public var provider: String {
        switch self {
        case .gptNano5: return "OpenAI"
        case .llama3_2_3b: return "Meta"
        }
    }
}

// MARK: - Message Types

public enum MessageRole: String, Codable {
    case system
    case user
    case assistant
}

public struct ChatMessage: Codable, Equatable {
    public let role: MessageRole
    public let content: String
    
    public init(role: MessageRole, content: String) {
        self.role = role
        self.content = content
    }
    
    public static func system(_ content: String) -> ChatMessage {
        ChatMessage(role: .system, content: content)
    }
    
    public static func user(_ content: String) -> ChatMessage {
        ChatMessage(role: .user, content: content)
    }
    
    public static func assistant(_ content: String) -> ChatMessage {
        ChatMessage(role: .assistant, content: content)
    }
}

// MARK: - Request Types

public struct ChatRequest: Codable {
    public let model: String
    public let messages: [ChatMessage]
    public let stream: Bool
    public let temperature: Double
    
    public init(model: OpenRouterModel, messages: [ChatMessage], stream: Bool = false, temperature: Double = 0.7) {
        self.model = model.rawValue
        self.messages = messages
        self.stream = stream
        self.temperature = temperature
    }
}

// MARK: - Response Types (Non-Streaming)

public struct ChatResponse: Codable {
    public let id: String
    public let object: String
    public let created: Int
    public let model: String
    public let choices: [Choice]
    public let usage: Usage?
    
    public struct Choice: Codable {
        public let index: Int
        public let message: ChatMessage
        public let finishReason: String?
        
        private enum CodingKeys: String, CodingKey {
            case index
            case message
            case finishReason = "finish_reason"
        }
    }
    
    public struct Usage: Codable {
        public let promptTokens: Int
        public let completionTokens: Int
        public let totalTokens: Int
        
        private enum CodingKeys: String, CodingKey {
            case promptTokens = "prompt_tokens"
            case completionTokens = "completion_tokens"
            case totalTokens = "total_tokens"
        }
    }
    
    /// Convenience accessor for the first response content
    public var content: String? {
        choices.first?.message.content
    }
}

// MARK: - Streaming Response Types (SSE)

public struct StreamChunk: Codable {
    public let id: String?
    public let object: String?
    public let created: Int?
    public let model: String?
    public let choices: [StreamChoice]
    
    public struct StreamChoice: Codable {
        public let index: Int
        public let delta: Delta
        public let finishReason: String?
        
        private enum CodingKeys: String, CodingKey {
            case index
            case delta
            case finishReason = "finish_reason"
        }
    }
    
    public struct Delta: Codable {
        public let role: MessageRole?
        public let content: String?
    }
    
    /// Convenience accessor for delta content
    public var deltaContent: String? {
        choices.first?.delta.content
    }
    
    /// Check if stream is finished
    public var isFinished: Bool {
        choices.first?.finishReason != nil
    }
}

// MARK: - Error Types

public enum OpenRouterError: LocalizedError {
    case invalidURL
    case missingAPIKey
    case invalidResponse(statusCode: Int)
    case decodingFailed(Error)
    case networkError(Error)
    case streamingError(String)
    case rateLimited(retryAfter: Int?)
    case serverError(message: String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid OpenRouter API URL"
        case .missingAPIKey:
            return "OpenRouter API key is missing. Please configure it in Settings."
        case .invalidResponse(let code):
            return "Invalid response from OpenRouter (HTTP \(code))"
        case .decodingFailed(let error):
            return "Failed to decode OpenRouter response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .streamingError(let message):
            return "Streaming error: \(message)"
        case .rateLimited(let retryAfter):
            if let seconds = retryAfter {
                return "Rate limited. Retry after \(seconds) seconds."
            }
            return "Rate limited. Please try again later."
        case .serverError(let message):
            return "Server error: \(message)"
        }
    }
}
