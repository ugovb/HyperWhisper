import Foundation

@MainActor
public class LLMService {
    public static let shared = LLMService()
    
    private init() {}
    
    private var openRouterProvider: OpenRouterProvider?
    private var lastOpenRouterKey: String?
    
    public func process(text: String, mode: Mode) async throws -> String {
        // 1. Check if Classic (Raw) -> No processing
        if mode.type == .classic || mode.providerType == .none {
            return text
        }
        
        // 2. Select Provider
        let provider: LLMProvider
        
        switch mode.providerType {
        case .local, .anthropic:
             // Deprecated
             throw LLMError.networkError(NSError(domain: "Provider deprecated. Please migrate to OpenRouter.", code: 410))
             
        case .gemini:
            guard let key = SettingsManager.shared.geminiKey, !key.isEmpty else {
                throw LLMError.missingAPIKey("Google Gemini")
            }
            provider = GeminiProvider(
                apiKey: key,
                modelName: "gemini-3-flash-preview" // User requested specific model
            )
            
        case .ollama:
            // Ollama supports OpenAI API at /v1/chat/completions
            let url = URL(string: "http://localhost:11434/v1/chat/completions")!
            provider = CloudLLMProvider(
                apiKey: "ollama",
                modelName: "gemma3:4b", // Mandated model
                baseURL: url
            )
            
        case .openAI:
            guard let key = SettingsManager.shared.openAIKey, !key.isEmpty else {
                throw LLMError.missingAPIKey("OpenAI")
            }
            let url = URL(string: "https://api.openai.com/v1/chat/completions")!
            provider = CloudLLMProvider(
                apiKey: key,
                modelName: "gpt-5-nano",
                baseURL: url
            )
            
        case .groq:
            guard let key = SettingsManager.shared.groqKey, !key.isEmpty else {
                throw LLMError.missingAPIKey("Groq")
            }
            let url = URL(string: "https://api.groq.com/openai/v1/chat/completions")!
            provider = CloudLLMProvider(
                apiKey: key,
                modelName: mode.modelIdentifier.isEmpty ? "llama3-8b-8192" : mode.modelIdentifier,
                baseURL: url
            )
            
        case .openRouter:
            guard let key = SettingsManager.shared.openRouterKey, !key.isEmpty else {
                throw LLMError.missingAPIKey("OpenRouter")
            }
            
            let modelId = mode.modelIdentifier.isEmpty ? "google/gemini-3-flash-preview" : mode.modelIdentifier
            
            // Check cache
            if let cached = openRouterProvider, lastOpenRouterKey == key {
                // Update model ID if changed (hacky but provider usually just uses it for request)
                // Actually OpenRouterProvider takes modelName in init.
                // If model changed, we need new provider OR update the existing one.
                // Let's just key off API key for now and assume creating a lightweight struct is fine,
                // BUT the underlying client (Actor) holds the URLSession.
                // We should cache the CLIENT, not the Provider if possible, or make Provider hold a static client.
                // For now, let's cache the provider and only recreate if key changes.
                // The provider stores `modelName` primarily for the request.
                // We need to support changing model without dropping connection.
                // OpenRouterProvider struct serves as a wrapper.
                // Let's just create a new one but maybe sharing the session?
                // The current OpenRouterClient is an actor.
                
                // OPTIMIZATION: Re-use cached provider if key matches. 
                // We need to update the model though.
                // Let's recreate for now but rely on URLSession's internal connection pooling which persists across instances if using shared session or same config.
                // OpenRouterClient uses `URLSession.shared` by default? No, it creates one.
                
                // Let's modify OpenRouterProvider to allow updating model, or cache carefully.
                // Actually, simple provider caching prevents the biggest overhead (Client actor init).
                
                if cached.modelName == modelId {
                    provider = cached
                } else {
                    // Model changed, update it.
                    // Ideally we'd update the existing provider's model but it's immutable (let).
                    // So we must recreate.
                    print("LLMService: Switching OpenRouter model to \(modelId)")
                    let newProvider = OpenRouterProvider(apiKey: key, modelName: modelId)
                    self.openRouterProvider = newProvider
                    self.lastOpenRouterKey = key
                    provider = newProvider
                }
            } else {
                print("LLMService: Creating new OpenRouter provider")
                let newProvider = OpenRouterProvider(apiKey: key, modelName: modelId)
                self.openRouterProvider = newProvider
                self.lastOpenRouterKey = key
                provider = newProvider
            }
            
        case .none:
            return text
        }
        
        // 4. Execute
        print("LLMService: Processing with \(mode.providerType) (\(mode.modelIdentifier))...")
        return try await provider.process(text: text, systemPrompt: mode.systemPrompt)
    }
}
