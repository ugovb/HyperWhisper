import SwiftUI
import SwiftData

// MARK: - Mode Editor View
/// A transactional form for creating or editing a Mode
struct ModeEditorView: View {
    // Transactional Actions
    var onSave: (Mode) -> Void
    var onCancel: () -> Void
    
    // Form State
    @State private var name: String
    @State private var type: ModeType
    @State private var audioSource: AudioSource
    @State private var systemPrompt: String
    @State private var providerType: ProviderType
    @State private var modelIdentifier: String
    @State private var isDefault: Bool
    @State private var contextAwarenessEnabled: Bool
    @State private var contextRules: String
    
    // Existing mode being edited (optional)
    private let editingModeId: UUID?
    private let editingMode: Mode?
    
    init(mode: Mode? = nil, onSave: @escaping (Mode) -> Void, onCancel: @escaping () -> Void) {
        self.editingMode = mode
        self.editingModeId = mode?.id
        self.onSave = onSave
        self.onCancel = onCancel
        
        // Initialize State
        _name = State(initialValue: mode?.name ?? "")
        _type = State(initialValue: mode?.type ?? .classic)
        _audioSource = State(initialValue: mode?.audioSource ?? .microphone)
        _systemPrompt = State(initialValue: mode?.systemPrompt ?? "")
        _providerType = State(initialValue: mode?.providerType ?? .none)
        _modelIdentifier = State(initialValue: mode?.modelIdentifier ?? "")
        _isDefault = State(initialValue: mode?.isDefault ?? false)
        _contextAwarenessEnabled = State(initialValue: mode?.contextAwarenessEnabled ?? false)
        _contextRules = State(initialValue: mode?.contextRules ?? "")
    }
    
    // Validation
    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // Dynamic help text for model selection
    private var modelHelpText: String {
        switch providerType {
        case .openRouter:
            return "Sélectionnez parmi les 3 modèles optimisés disponibles."
        case .ollama:
            return "Gemma 3 4B est le seul modèle local supporté."
        default:
            return "Identifiant du modèle à utiliser."
        }
    }
    
    // OpenRouter API Key binding
    private var openRouterKeyBinding: Binding<String> {
        Binding(
            get: { SettingsManager.shared.openRouterKey ?? "" },
            set: { SettingsManager.shared.openRouterKey = $0.isEmpty ? nil : $0 }
        )
    }
    
    // Check if OpenRouter API key is configured
    private var hasOpenRouterKey: Bool {
        guard let key = SettingsManager.shared.openRouterKey else { return false }
        return !key.isEmpty
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header
            HStack {
                Text(editingMode == nil ? "New Mode" : "Edit Mode")
                    .font(.hyperUI(.headline, weight: .bold))
                Spacer()
            }
            .padding()
            .background(.ultraThinMaterial)
            .dividerBottom()
            
            // MARK: - Form Content
            ScrollView {
                VStack(spacing: HyperSpacing.xl) {
                    
                    // General Section
                    VStack(alignment: .leading, spacing: HyperSpacing.md) {
                        Text("General")
                            .font(.hyperUI(.subheadline, weight: .semibold))
                            .foregroundStyle(.secondary)
                        
                        GlassCard(padding: HyperSpacing.md) {
                            VStack(spacing: HyperSpacing.lg) {
                                LabeledContent("Name") {
                                    TextField("e.g. Coding Assistant", text: $name)
                                        .textFieldStyle(.roundedBorder)
                                }
                                
                                Divider()
                                
                                LabeledContent("Mode Type") {
                                    Picker("", selection: $type) {
                                        ForEach(ModeType.allCases, id: \.self) { modeType in
                                            Text(modeType.rawValue).tag(modeType)
                                        }
                                    }
                                }
                                .onChange(of: type) { _, newValue in
                                    if newValue == .meeting {
                                        audioSource = .both
                                    } else if newValue == .classic {
                                        providerType = .none
                                    }
                                }
                                
                                Divider()
                                
                                LabeledContent("Audio Source") {
                                    Picker("", selection: $audioSource) {
                                        ForEach(AudioSource.allCases, id: \.self) { source in
                                            Text(source.rawValue).tag(source)
                                        }
                                    }
                                    .disabled(type == .meeting) // Force 'Both' for meetings
                                }
                                
                                Divider()
                                
                                Toggle("Set as Default", isOn: $isDefault)
                                    .toggleStyle(.switch)
                            }
                        }
                    }
                    
                    // Configuration Section (Only for Refined or Meeting)
                    if type != .classic {
                        VStack(alignment: .leading, spacing: HyperSpacing.md) {
                            Text("Intelligence Engine")
                                .font(.hyperUI(.subheadline, weight: .semibold))
                                .foregroundStyle(.secondary)
                            
                            GlassCard(padding: HyperSpacing.md) {
                                VStack(spacing: HyperSpacing.lg) {
                                    // Provider Picker - Only OpenRouter and Ollama
                                    LabeledContent("Provider") {
                                        Picker("", selection: $providerType) {
                                            Text("OpenRouter").tag(ProviderType.openRouter)
                                            Text("Ollama (Local)").tag(ProviderType.ollama)
                                        }
                                    }
                                    .onChange(of: providerType) { _, newValue in
                                        // Set default model when provider changes
                                        if newValue == .ollama {
                                            modelIdentifier = "gemma3:4b"
                                        } else if newValue == .openRouter {
                                            modelIdentifier = OpenRouterModel.gptNano5.rawValue
                                        }
                                    }
                                    
                                    Divider()
                                    
                                    // OpenRouter: API Key required before model selection
                                    if providerType == .openRouter {
                                        VStack(alignment: .leading, spacing: HyperSpacing.sm) {
                                            LabeledContent("API Key") {
                                                SecureField("sk-or-...", text: openRouterKeyBinding)
                                                    .textFieldStyle(.roundedBorder)
                                            }
                                            
                                            if !hasOpenRouterKey {
                                                HStack(spacing: 4) {
                                                    Image(systemName: "exclamationmark.triangle.fill")
                                                        .foregroundStyle(.orange)
                                                    Text("Clé API requise pour utiliser OpenRouter")
                                                        .font(.hyperUI(.caption))
                                                        .foregroundStyle(.orange)
                                                }
                                            }
                                        }
                                        
                                        // Model picker only if API key is set
                                        if hasOpenRouterKey {
                                            Divider()
                                            
                                            LabeledContent("Model") {
                                                Picker("", selection: $modelIdentifier) {
                                                    ForEach(OpenRouterModel.allCases, id: \.rawValue) { model in
                                                        Text(model.displayName).tag(model.rawValue)
                                                    }
                                                }
                                            }
                                            Text("Sélectionnez parmi les 3 modèles optimisés.")
                                                .font(.hyperUI(.caption))
                                                .foregroundStyle(.secondary)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                    }
                                    
                                    // Ollama: Only gemma3:4b
                                    if providerType == .ollama {
                                        LabeledContent("Model") {
                                            Picker("", selection: $modelIdentifier) {
                                                Text("Gemma 3 4B").tag("gemma3:4b")
                                            }
                                            .disabled(true)
                                        }
                                        Text("Gemma 3 4B est le seul modèle local supporté.")
                                            .font(.hyperUI(.caption))
                                            .foregroundStyle(.secondary)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                }
                            }
                        }
                        
                        // Prompt Engineering Section
                        VStack(alignment: .leading, spacing: HyperSpacing.md) {
                            Text("Instructions")
                                .font(.hyperUI(.subheadline, weight: .semibold))
                                .foregroundStyle(.secondary)
                            
                            GlassCard(padding: HyperSpacing.md) {
                                VStack(alignment: .leading, spacing: HyperSpacing.sm) {
                                    Text("System Prompt")
                                        .font(.hyperUI(.caption, weight: .medium))
                                        .foregroundStyle(.secondary)
                                    
                                    TextEditor(text: $systemPrompt)
                                        .font(.hyperUI(.body))
                                        .frame(minHeight: 120)
                                        .padding(4)
                                        .background(Color(nsColor: .controlBackgroundColor))
                                        .cornerRadius(6)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                                        )
                                    
                                    Text("Tip: Describe how you want the text to be transformed.")
                                        .font(.hyperUI(.caption))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding()
            }
            
            // MARK: - Transactional Footer
            HStack {
                Button("Cancel", role: .cancel) {
                    onCancel()
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(HyperRadius.md)
                
                Spacer()
                
                Button {
                    let newMode = Mode(
                        id: editingModeId ?? UUID(),
                        name: name,
                        type: type,
                        audioSource: audioSource,
                        systemPrompt: systemPrompt,
                        providerType: type == .classic ? .none : providerType,
                        modelIdentifier: modelIdentifier,
                        isDefault: isDefault,
                        contextAwarenessEnabled: contextAwarenessEnabled,
                        contextRules: contextRules
                    )
                    onSave(newMode)
                } label: {
                    Text(editingMode == nil ? "Create Mode" : "Save Changes")
                        .font(.hyperUI(.body, weight: .semibold))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 8)
                        .background(isValid ? Color.accentColor : Color.secondary.opacity(0.2))
                        .foregroundColor(.white)
                        .cornerRadius(HyperRadius.md)
                }
                .buttonStyle(.plain)
                .disabled(!isValid)
            }
            .padding()
            .background(.ultraThinMaterial)
            .dividerTop()
        }
        .frame(minWidth: 500, minHeight: 600)
    }
}

// Helper modifiers (Duplicated to ensure standalone preview works if copied, though likely in global scope)
#Preview {
    ModeEditorView(onSave: { _ in }, onCancel: {})
}