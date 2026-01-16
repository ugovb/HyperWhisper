import Foundation
import Observation

@MainActor
@Observable
public final class SettingsManager {
    public static let shared = SettingsManager()
    
    private let defaults = UserDefaults.standard
    
    private enum Keys {
        static let activeModeId = "activeModeId"
        static let selectedMicrophoneId = "selectedMicrophoneId"
        static let apiKeysPath = "apiKeysPath"
        static let openAIKey = "openAIKey"
        static let anthropicKey = "anthropicKey"
        static let geminiKey = "geminiKey"
        static let groqKey = "groqKey"
        static let openRouterKey = "openRouterKey"
        static let autoGain = "autoGain"
        static let silenceRemoval = "silenceRemoval"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let selectedModelType = "selectedModelType"
    }
    
    public var hasCompletedOnboarding: Bool {
        didSet { defaults.set(hasCompletedOnboarding, forKey: Keys.hasCompletedOnboarding) }
    }
    
    public var autoGain: Bool {
        didSet { defaults.set(autoGain, forKey: Keys.autoGain) }
    }
    
    public var silenceRemoval: Bool {
        didSet { defaults.set(silenceRemoval, forKey: Keys.silenceRemoval) }
    }

    
    public var activeModeId: UUID? {
        didSet {
            if let id = activeModeId {
                defaults.set(id.uuidString, forKey: Keys.activeModeId)
            } else {
                defaults.removeObject(forKey: Keys.activeModeId)
            }
        }
    }
    
    public var selectedMicrophoneId: String? {
        didSet {
            defaults.set(selectedMicrophoneId, forKey: Keys.selectedMicrophoneId)
        }
    }
    
    public var apiKeysPath: String? {
        didSet {
            defaults.set(apiKeysPath, forKey: Keys.apiKeysPath)
        }
    }
    
    public var openAIKey: String? {
        didSet {
            if let key = openAIKey, !key.isEmpty {
                defaults.set(key, forKey: Keys.openAIKey)
            } else {
                defaults.removeObject(forKey: Keys.openAIKey)
            }
        }
    }
    
    public var anthropicKey: String? {
        didSet {
            if let key = anthropicKey, !key.isEmpty {
                defaults.set(key, forKey: Keys.anthropicKey)
            } else {
                defaults.removeObject(forKey: Keys.anthropicKey)
            }
        }
    }
    
    public var geminiKey: String? {
        didSet {
            if let key = geminiKey, !key.isEmpty {
                defaults.set(key, forKey: Keys.geminiKey)
            } else {
                defaults.removeObject(forKey: Keys.geminiKey)
            }
        }
    }
    
    public var groqKey: String? {
        didSet {
            if let key = groqKey, !key.isEmpty {
                defaults.set(key, forKey: Keys.groqKey)
            } else {
                defaults.removeObject(forKey: Keys.groqKey)
            }
        }
    }
    
    public var openRouterKey: String? {
        didSet {
            if let key = openRouterKey, !key.isEmpty {
                defaults.set(key, forKey: Keys.openRouterKey)
            } else {
                defaults.removeObject(forKey: Keys.openRouterKey)
            }
        }
    }
    
    public var selectedModelType: String {
        didSet {
            defaults.set(selectedModelType, forKey: Keys.selectedModelType)
        }
    }
    
    private init() {
        if let modeString = defaults.string(forKey: Keys.activeModeId),
           let uuid = UUID(uuidString: modeString) {
            self.activeModeId = uuid
        }
        self.selectedMicrophoneId = defaults.string(forKey: Keys.selectedMicrophoneId)
        self.apiKeysPath = defaults.string(forKey: Keys.apiKeysPath)
        self.openAIKey = defaults.string(forKey: Keys.openAIKey)
        self.anthropicKey = defaults.string(forKey: Keys.anthropicKey)
        // Load API keys from user defaults (no hardcoded keys)
        self.geminiKey = defaults.string(forKey: Keys.geminiKey)
        self.groqKey = defaults.string(forKey: Keys.groqKey)
        self.openRouterKey = defaults.string(forKey: Keys.openRouterKey)
        self.autoGain = defaults.object(forKey: Keys.autoGain) == nil ? true : defaults.bool(forKey: Keys.autoGain)
        self.silenceRemoval = defaults.object(forKey: Keys.silenceRemoval) == nil ? true : defaults.bool(forKey: Keys.silenceRemoval)
        self.hasCompletedOnboarding = defaults.bool(forKey: Keys.hasCompletedOnboarding)
        self.selectedModelType = defaults.string(forKey: Keys.selectedModelType) ?? "Parakeet (Recommended)"
    }
}
