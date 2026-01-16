import Foundation

/// Provider LLM utilisant le nouveau OpenRouterClient avec support des 3 modèles autorisés.
/// Ce provider s'intègre avec l'architecture LLMProvider existante tout en utilisant
/// le client thread-safe basé sur Actor.
public struct OpenRouterProvider: LLMProvider {
    private let client: OpenRouterClient
    public let model: OpenRouterModel
    
    public var modelName: String { model.id }
    
    /// Initialise avec un modèle spécifique parmi les 3 autorisés.
    public init(apiKey: String, model: OpenRouterModel) {
        self.client = OpenRouterClient(apiKey: apiKey)
        self.model = model
    }
    
    /// Initialise avec un identifiant de modèle string (pour compatibilité avec LLMService).
    /// Convertit automatiquement en OpenRouterModel si valide, sinon utilise le défaut.
    public init(apiKey: String, modelName: String) {
        self.client = OpenRouterClient(apiKey: apiKey)
        self.model = OpenRouterModel(rawValue: modelName) ?? .llama3_2_3b
    }
    
    public func process(text: String, systemPrompt: String) async throws -> String {
        do {
            return try await client.process(text: text, systemPrompt: systemPrompt, model: model)
        } catch let error as OpenRouterError {
            // Convert to LLMError for compatibility
            switch error {
            case .missingAPIKey:
                throw LLMError.missingAPIKey("OpenRouter")
            case .invalidResponse(let code):
                throw LLMError.invalidResponse(code)
            case .decodingFailed, .streamingError:
                throw LLMError.parsingFailed
            case .networkError(let underlyingError):
                throw LLMError.networkError(underlyingError)
            case .rateLimited, .serverError, .invalidURL:
                throw LLMError.networkError(error)
            }
        }
    }
    
    /// Streaming version - returns AsyncThrowingStream of text fragments.
    public func streamProcess(
        text: String,
        systemPrompt: String
    ) async throws -> AsyncThrowingStream<String, Error> {
        let messages = [
            ChatMessage.system(systemPrompt),
            ChatMessage.user(text)
        ]
        return try await client.streamChat(messages: messages, model: model)
    }
}

// MARK: - Model Selection Helper

extension OpenRouterProvider {
    /// Retourne tous les modèles disponibles pour affichage dans l'UI.
    public static var availableModels: [OpenRouterModel] {
        OpenRouterModel.allCases
    }
    
    /// Retourne le modèle recommandé par défaut.
    public static var defaultModel: OpenRouterModel {
        .llama3_2_3b
    }
}
