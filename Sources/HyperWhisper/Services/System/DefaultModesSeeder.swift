import Foundation
import SwiftData

/// Seeds the database with default modes on first launch.
/// These modes are fully modifiable by the user.
@MainActor
public struct DefaultModesSeeder {
    
    /// Check if modes exist, if not create defaults
    public static func seedIfNeeded(context: ModelContext) {
        // Check if any modes exist
        let descriptor = FetchDescriptor<Mode>()
        let existingCount = (try? context.fetchCount(descriptor)) ?? 0
        
        guard existingCount == 0 else {
            print("DefaultModesSeeder: Modes already exist (\(existingCount)), skipping seed.")
            return
        }
        
        print("DefaultModesSeeder: No modes found. Creating default modes...")
        
        // Create default modes
        let defaultModes = createDefaultModes()
        
        for mode in defaultModes {
            context.insert(mode)
        }
        
        try? context.save()
        print("DefaultModesSeeder: Created \(defaultModes.count) default modes.")
    }
    
    private static func createDefaultModes() -> [Mode] {
        return [
            // 1. Raw Dictation - No processing
            Mode(
                name: "Raw",
                type: .classic,
                audioSource: .microphone,
                systemPrompt: "",
                providerType: .none,
                modelIdentifier: "",
                isDefault: true,
                contextAwarenessEnabled: false,
                contextRules: ""
            ),
            
            // 2. Refined - Grammar and spelling correction (LOCAL - FAST)
            Mode(
                name: "Refined",
                type: .refined,
                audioSource: .microphone,
                systemPrompt: """
                Corrige l'orthographe, la grammaire et la ponctuation de cette transcription vocale. 
                Supprime les répétitions et hésitations (euh, hum, etc.).
                Conserve le sens et le style original.
                Réponds uniquement avec le texte corrigé, sans explication.
                """,
                providerType: .ollama,
                modelIdentifier: "gemma3:4b",
                isDefault: false,
                contextAwarenessEnabled: false,
                contextRules: ""
            ),
            
            // 3. Translator - Translate to English
            Mode(
                name: "Translate → English",
                type: .refined,
                audioSource: .microphone,
                systemPrompt: """
                Translate the following text to English.
                Keep the original meaning and tone.
                Reply only with the translation, no explanations.
                """,
                providerType: .openRouter,
                modelIdentifier: "google/gemini-3-flash-preview",
                isDefault: false,
                contextAwarenessEnabled: false,
                contextRules: ""
            )
        ]
    }
}
