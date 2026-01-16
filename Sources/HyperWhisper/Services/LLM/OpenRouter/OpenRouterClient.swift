import Foundation

/// Client réseau thread-safe pour l'API OpenRouter.
/// Utilise Swift Concurrency (Actor) pour garantir la thread-safety.
public actor OpenRouterClient {
    
    // MARK: - Configuration
    
    private static let baseURL = URL(string: "https://openrouter.ai/api/v1")!
    private static let chatEndpoint = "chat/completions"
    
    private let apiKey: String
    private let httpReferer: String
    private let appTitle: String
    private let session: URLSession
    
    // MARK: - Initialization
    
    /// Initialise le client OpenRouter.
    /// - Parameters:
    ///   - apiKey: Clé API OpenRouter (obligatoire)
    ///   - httpReferer: URL de référence pour l'API (défaut: https://hyperwhisper.app)
    ///   - appTitle: Titre de l'application (défaut: HyperWhisper)
    public init(
        apiKey: String,
        httpReferer: String = "https://hyperwhisper.app",
        appTitle: String = "HyperWhisper"
    ) {
        self.apiKey = apiKey
        self.httpReferer = httpReferer
        self.appTitle = appTitle
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120 // 2 minutes for long responses
        config.timeoutIntervalForResource = 300 // 5 minutes total
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Public API
    
    /// Envoie une requête chat non-streaming et retourne la réponse complète.
    /// - Parameters:
    ///   - messages: Liste des messages de la conversation
    ///   - model: Modèle à utiliser (parmi les 3 autorisés)
    ///   - temperature: Température de génération (0.0 - 2.0)
    /// - Returns: Réponse complète du chat
    public func chat(
        messages: [ChatMessage],
        model: OpenRouterModel,
        temperature: Double = 0.7
    ) async throws -> ChatResponse {
        let request = ChatRequest(model: model, messages: messages, stream: false, temperature: temperature)
        let urlRequest = try buildRequest(for: request)
        
        print("🌐 [OpenRouter] Calling \(model.displayName)...")
        
        let (data, response) = try await session.data(for: urlRequest)
        
        try validateResponse(response, data: data)
        
        do {
            let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)
            print("🌐 [OpenRouter] Success! Tokens used: \(chatResponse.usage?.totalTokens ?? 0)")
            return chatResponse
        } catch {
            throw OpenRouterError.decodingFailed(error)
        }
    }
    
    /// Envoie une requête chat en streaming et retourne un AsyncThrowingStream de fragments texte.
    /// - Parameters:
    ///   - messages: Liste des messages de la conversation
    ///   - model: Modèle à utiliser (parmi les 3 autorisés)
    ///   - temperature: Température de génération (0.0 - 2.0)
    /// - Returns: Stream asynchrone de fragments de texte
    public func streamChat(
        messages: [ChatMessage],
        model: OpenRouterModel,
        temperature: Double = 0.7
    ) async throws -> AsyncThrowingStream<String, Error> {
        // Build request on actor
        let request = ChatRequest(model: model, messages: messages, stream: true, temperature: temperature)
        let urlRequest = try buildRequest(for: request)
        let urlSession = self.session
        let modelName = model.displayName
        
        print("🌐 [OpenRouter] Starting stream with \(modelName)...")
        
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let (bytes, response) = try await urlSession.bytes(for: urlRequest)
                    
                    // Validate initial response
                    guard let httpResponse = response as? HTTPURLResponse else {
                        throw OpenRouterError.invalidResponse(statusCode: 0)
                    }
                    
                    guard httpResponse.statusCode == 200 else {
                        throw OpenRouterError.invalidResponse(statusCode: httpResponse.statusCode)
                    }
                    
                    // Process SSE stream
                    for try await line in bytes.lines {
                        // SSE format: "data: {json}" or "data: [DONE]"
                        guard line.hasPrefix("data: ") else { continue }
                        
                        let jsonString = String(line.dropFirst(6)) // Remove "data: " prefix
                        
                        // Check for stream end
                        if jsonString == "[DONE]" {
                            print("🌐 [OpenRouter] Stream completed")
                            break
                        }
                        
                        // Parse chunk
                        guard let jsonData = jsonString.data(using: .utf8) else { continue }
                        
                        do {
                            let chunk = try JSONDecoder().decode(StreamChunk.self, from: jsonData)
                            
                            if let content = chunk.deltaContent, !content.isEmpty {
                                continuation.yield(content)
                            }
                            
                            if chunk.isFinished {
                                break
                            }
                        } catch {
                            // Log but continue - some lines may be malformed
                            print("🌐 [OpenRouter] Warning: Failed to parse chunk: \(error)")
                        }
                    }
                    
                    continuation.finish()
                    
                } catch {
                    print("🌐 [OpenRouter] Stream error: \(error)")
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    /// Helper pour traiter du texte avec un system prompt.
    /// - Parameters:
    ///   - text: Texte à traiter (envoyé comme message user)
    ///   - systemPrompt: Instructions système
    ///   - model: Modèle à utiliser
    /// - Returns: Texte de réponse
    public func process(
        text: String,
        systemPrompt: String,
        model: OpenRouterModel
    ) async throws -> String {
        let messages = [
            ChatMessage.system(systemPrompt),
            ChatMessage.user(text)
        ]
        
        let response = try await chat(messages: messages, model: model)
        
        guard let content = response.content else {
            throw OpenRouterError.streamingError("Empty response from model")
        }
        
        return content
    }
    
    // MARK: - Private Helpers
    
    private func buildRequest(for chatRequest: ChatRequest) throws -> URLRequest {
        let url = Self.baseURL.appendingPathComponent(Self.chatEndpoint)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Required headers
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(httpReferer, forHTTPHeaderField: "HTTP-Referer")
        request.setValue(appTitle, forHTTPHeaderField: "X-Title")
        
        // Encode body
        do {
            request.httpBody = try JSONEncoder().encode(chatRequest)
        } catch {
            throw OpenRouterError.decodingFailed(error)
        }
        
        return request
    }
    
    /// Version async-accessible de buildRequest pour streaming
    func buildStreamRequest(for chatRequest: ChatRequest) throws -> URLRequest {
        try buildRequest(for: chatRequest)
    }
    
    private func validateResponse(_ response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenRouterError.invalidResponse(statusCode: 0)
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return // Success
            
        case 429:
            let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After").flatMap(Int.init)
            throw OpenRouterError.rateLimited(retryAfter: retryAfter)
            
        case 400...499:
            // Try to parse error message
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = json["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw OpenRouterError.serverError(message: message)
            }
            throw OpenRouterError.invalidResponse(statusCode: httpResponse.statusCode)
            
        case 500...599:
            throw OpenRouterError.serverError(message: "Server error (HTTP \(httpResponse.statusCode))")
            
        default:
            throw OpenRouterError.invalidResponse(statusCode: httpResponse.statusCode)
        }
    }
}

// MARK: - Convenience Extensions

extension OpenRouterClient {
    
    /// Crée un client avec la clé API stockée dans SettingsManager.
    /// - Returns: Client configuré ou nil si pas de clé API
    @MainActor
    public static func fromSettings() -> OpenRouterClient? {
        guard let apiKey = SettingsManager.shared.openRouterKey, !apiKey.isEmpty else {
            return nil
        }
        return OpenRouterClient(apiKey: apiKey)
    }
}
