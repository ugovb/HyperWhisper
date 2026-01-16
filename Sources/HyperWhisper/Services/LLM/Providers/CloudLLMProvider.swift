import Foundation

/// A provider that communicates with an OpenAI-compatible API.
public struct CloudLLMProvider: LLMProvider {
    
    private let apiKey: String
    private let baseURL: URL
    private let modelName: String
    private let additionalHeaders: [String: String]
    
    private let session: URLSession
    
    public init(apiKey: String, modelName: String, baseURL: URL, additionalHeaders: [String: String] = [:]) {
        self.apiKey = apiKey
        self.modelName = modelName
        self.baseURL = baseURL
        self.additionalHeaders = additionalHeaders
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 25 // Increased for slower models
        self.session = URLSession(configuration: config)
    }
    
    public func process(text: String, systemPrompt: String) async throws -> String {
        // 1. Prepare Request
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        for (key, value) in additionalHeaders {
            request.addValue(value, forHTTPHeaderField: key)
        }
        
        // OpenAI / Groq Compatible Format
        // Note: Anthropic would need a different body adapter. For now, we assume OpenAI-compatible formatting.
        let messages: [[String: String]] = [
            ["role": "system", "content": systemPrompt],
            ["role": "user", "content": text]
        ]
        
        // Groq/OpenAI Body
        let body: [String: Any] = [
            "model": modelName,
            "messages": messages,
            "temperature": 0.7
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        // 2. Execute
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMError.networkError(NSError(domain: "Invalid Response", code: 0))
        }
        
        guard httpResponse.statusCode == 200 else {
            // Try to read error message
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("LLM Error: \(errorJson)")
            }
            throw LLMError.invalidResponse(httpResponse.statusCode)
        }
        
        // 3. Parse Response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw LLMError.parsingFailed
        }
        
        return content
    }
}
