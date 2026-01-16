import SwiftUI

struct AISettingsView: View {
    @State private var settings = SettingsManager.shared
    @ObservedObject private var modelManager = ModelManager.shared
    @StateObject private var ollamaManager = OllamaManager.shared
    
    // Binding helpers for optional strings
    private func binding(for keyPath: ReferenceWritableKeyPath<SettingsManager, String?>) -> Binding<String> {
        Binding(
            get: { settings[keyPath: keyPath] ?? "" },
            set: { settings[keyPath: keyPath] = $0.isEmpty ? nil : $0 }
        )
    }
    
    var body: some View {
        Form {
            Section("Transcription Models") {
                ForEach(modelManager.models, id: \.id) { info in
                    TranscriptionModelRow(info: info, modelManager: modelManager)
                }
            }
            
            Section("Cloud Providers") {
                VStack(alignment: .leading) {
                    Text("API Keys")
                        .font(.headline)
                    Text("To use AI features, please provide your own API keys. These are stored locally.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 8)
                
                TextField("OpenAI Key", text: binding(for: \.openAIKey))
                TextField("Anthropic Key", text: binding(for: \.anthropicKey))
                TextField("Gemini Key", text: binding(for: \.geminiKey))
                TextField("Groq Key", text: binding(for: \.groqKey))
                
                Divider()
                
                VStack(alignment: .leading, spacing: 4) {
                    TextField("OpenRouter Key", text: binding(for: \.openRouterKey))
                    Text("OpenRouter unifies 400+ models (Claude, GPT, Gemini...) with one API key")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            Section("Ollama Model Manager") {
                OllamaSectionView(ollamaManager: ollamaManager)
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            ollamaManager.checkInstallation()
        }
    }
}

struct TranscriptionModelRow: View {
    let info: ModelDownloadInfo
    let modelManager: ModelManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text(String(info.name))
                        .fontWeight(.medium)
                    Text(String(info.description))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(String(info.expectedSize))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                
                Spacer()
                
                // Action Button
                switch info.status {
                case .notDownloaded, .error:
                    Button("Download") {
                        modelManager.startDownload(for: info.id)
                    }
                    .buttonStyle(.bordered)
                    
                case .downloading:
                    Button("Cancel") {
                        modelManager.cancelDownload(for: info.id)
                    }
                    .tint(.red)
                    
                case .paused:
                    Button("Resume") {
                        modelManager.startDownload(for: info.id)
                    }
                    
                case .downloaded:
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }
            
            // Progress Bar
            if info.status == .downloading || info.status == .paused {
                ProgressView(value: info.progress)
                    .progressViewStyle(.linear)
                Text("\(Int(info.progress * 100))%")
                    .font(.caption2)
                    .monospacedDigit()
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct OllamaSectionView: View {
    @ObservedObject var ollamaManager: OllamaManager
    
    var body: some View {
        if ollamaManager.isInstalled {
            VStack(alignment: .leading, spacing: 12) {
                Text("Install Local Models")
                    .font(.headline)
                
                ForEach(ollamaManager.suggestedModels, id: \.0) { modelId, description in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(modelId).fontWeight(.medium)
                            Text(description).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("Install") {
                            Task { await ollamaManager.pullModel(modelId) }
                        }
                        .disabled(ollamaManager.isPulling)
                    }
                }
                
                if ollamaManager.isPulling {
                    Divider()
                    HStack {
                        ProgressView().scaleEffect(0.5)
                        Text(ollamaManager.currentProgress)
                            .font(.caption)
                            .monospaced()
                            .lineLimit(1)
                    }
                }
            }
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Text("Ollama is not installed.")
                    .foregroundStyle(.red)
                Link("Download Ollama", destination: URL(string: "https://ollama.com")!)
                    .font(.headline)
                Text("Ollama is required to run local models efficiently.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
