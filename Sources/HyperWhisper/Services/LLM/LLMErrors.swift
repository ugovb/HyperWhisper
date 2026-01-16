import Foundation

public enum LLMError: LocalizedError {
    case missingAPIKey(String) // Account
    case networkError(Error)
    case invalidResponse(Int)
    case parsingFailed
    case timeout
    case providerNotImplemented(String)
    
    public var errorDescription: String? {
        switch self {
        case .missingAPIKey(let account): return "API Key missing for \(account). Please check Settings."
        case .networkError(let error): return "Network error: \(error.localizedDescription)"
        case .invalidResponse(let code): return "Server returned error code: \(code)"
        case .parsingFailed: return "Failed to parse server response."
        case .timeout: return "Request timed out."
        case .providerNotImplemented(let provider): return "Provider '\(provider)' is not yet implemented."
        }
    }
}
