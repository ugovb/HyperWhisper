import Foundation

@MainActor
class OllamaManager: ObservableObject {
    static let shared = OllamaManager()
    
    @Published var isInstalled = false
    @Published var isPulling = false
    @Published var currentProgress: String = ""
    
    private let possiblePaths = [
        "/usr/local/bin/ollama",
        "/opt/homebrew/bin/ollama"
    ]
    
    // Suggested models
    let suggestedModels = [
        ("gemma:2b", "Gemma 2B (Lightweight, Fast)"),
        ("llama3:8b", "Llama 3 8B (Balanced)"),
        ("mistral", "Mistral 7B (High Quality)"),
        ("phi3", "Phi-3 (Very Efficient)")
    ]
    
    init() {
        checkInstallation()
    }
    
    func checkInstallation() {
        isInstalled = resolveOllamaPath() != nil
    }
    
    private func resolveOllamaPath() -> String? {
        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        return nil
    }
    
    func pullModel(_ modelName: String) async {
        guard let binary = resolveOllamaPath() else { return }
        
        isPulling = true
        currentProgress = "Starting pull for \(modelName)..."
        
        // Run in background task
        await Task.detached {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: binary)
            process.arguments = ["pull", modelName]
            
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe
            
            do {
                try process.run()
                
                for try await line in pipe.fileHandleForReading.bytes.lines {
                    await MainActor.run {
                        self.currentProgress = line
                    }
                }
                
                process.waitUntilExit()
                
                await MainActor.run {
                    self.isPulling = false
                    self.currentProgress = "Done"
                }
            } catch {
                await MainActor.run {
                    self.currentProgress = "Error: \(error.localizedDescription)"
                    self.isPulling = false
                }
            }
        }.value
    }
}
