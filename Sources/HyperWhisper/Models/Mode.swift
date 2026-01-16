import Foundation
import SwiftData

public enum ProviderType: String, Codable, CaseIterable {
    case local
    case ollama
    case openAI
    case anthropic
    case gemini
    case groq
    case openRouter
    case none // For direct dictation (bypass)
}

public enum ModeType: String, Codable, CaseIterable {
    case classic = "Classic (Raw)"
    case refined = "Adjusted (Refined)"
    case meeting = "Meeting (Summarized)"
}

public enum AudioSource: String, Codable, CaseIterable {
    case microphone = "Microphone Only"
    case system = "System Audio Only"
    case both = "Meeting (Mic + System)"
}

@Model
public class Mode {
    public var id: UUID
    public var name: String
    public var type: ModeType
    public var audioSource: AudioSource
    public var systemPrompt: String
    public var providerType: ProviderType
    public var modelIdentifier: String
    public var isDefault: Bool
    public var contextAwarenessEnabled: Bool
    public var contextRules: String
    
    public init(id: UUID = UUID(), 
                name: String, 
                type: ModeType = .classic,
                audioSource: AudioSource = .microphone,
                systemPrompt: String = "", 
                providerType: ProviderType = .none, 
                modelIdentifier: String = "", 
                isDefault: Bool = false,
                contextAwarenessEnabled: Bool = false,
                contextRules: String = "") {
        self.id = id
        self.name = name
        self.type = type
        self.audioSource = audioSource
        self.systemPrompt = systemPrompt
        self.providerType = providerType
        self.modelIdentifier = modelIdentifier
        self.isDefault = isDefault
        self.contextAwarenessEnabled = contextAwarenessEnabled
        self.contextRules = contextRules
    }
    
    // Default Seeds
    static var defaults: [Mode] {
        [
            Mode(name: "Direct Dictation", type: .classic, audioSource: .microphone, providerType: .none, isDefault: true),
            Mode(name: "Refine Grammar (OpenAI)", type: .refined, audioSource: .microphone, systemPrompt: "Fix grammar and punctuation while keeping the original meaning.", providerType: .openAI, modelIdentifier: "gpt-5-nano"),
            Mode(name: "Meeting Summary (Claude)", type: .meeting, audioSource: .both, systemPrompt: "Summarize this meeting into clear bullet points with action items.", providerType: .anthropic, modelIdentifier: "claude-haiku-4.5")
        ]
    }
}