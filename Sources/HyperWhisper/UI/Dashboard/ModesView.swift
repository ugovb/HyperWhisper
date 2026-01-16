import SwiftUI
import SwiftData

struct ModesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Mode.name) private var modes: [Mode]
    
    // UI State
    @State private var showingCreateSheet = false
    @State private var modeToEdit: Mode?
    @State private var hoveringModeId: UUID?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: HyperSpacing.xs) {
                HStack {
                    Text("Modes")
                        .font(.hyperUI(.title, weight: .bold))
                    
                    Spacer()
                    
                    Button {
                        showingCreateSheet = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .bold))
                            Text("Create Mode")
                                .font(.hyperUI(.subheadline, weight: .semibold))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                        .shadow(color: .accentColor.opacity(0.3), radius: 4, y: 2)
                    }
                    .buttonStyle(.plain)
                }
                
                Text("Manage your dictation presets and AI instructions")
                    .font(.hyperUI(.subheadline))
                    .foregroundStyle(.secondary)
            }
            .padding(HyperSpacing.xl)
            .background(Color(nsColor: .windowBackgroundColor))
            
            Divider()
            
            // List Content
            ScrollView {
                VStack(spacing: HyperSpacing.sm) {
                    ForEach(modes) { mode in
                        ModeListRow(mode: mode, isHovered: hoveringModeId == mode.id) {
                            modeToEdit = mode
                        }
                        .onHover { isHovered in
                            hoveringModeId = isHovered ? mode.id : nil
                        }
                        .contextMenu {
                            Button {
                                modeToEdit = mode
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            
                            Divider()
                            
                            Button(role: .destructive) {
                                deleteMode(mode)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .padding(HyperSpacing.xl)
            }
        }
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.5))
        // Create Sheet
        .sheet(isPresented: $showingCreateSheet) {
            ModeEditorView(
                onSave: { newMode in
                    modelContext.insert(newMode)
                    showingCreateSheet = false
                },
                onCancel: {
                    showingCreateSheet = false
                }
            )
        }
        // Edit Sheet
        .sheet(item: $modeToEdit) { mode in
            ModeEditorView(
                mode: mode,
                onSave: { updatedMode in
                    // Update existing mode properties
                    mode.name = updatedMode.name
                    mode.type = updatedMode.type
                    mode.audioSource = updatedMode.audioSource
                    mode.systemPrompt = updatedMode.systemPrompt
                    mode.providerType = updatedMode.providerType
                    mode.modelIdentifier = updatedMode.modelIdentifier
                    mode.isDefault = updatedMode.isDefault
                    
                    modeToEdit = nil
                },
                onCancel: {
                    modeToEdit = nil
                }
            )
        }
    }
    
    private func deleteMode(_ mode: Mode) {
        withAnimation {
            modelContext.delete(mode)
        }
    }
}

// MARK: - List Row Component
struct ModeListRow: View {
    let mode: Mode
    let isHovered: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: HyperSpacing.md) {
                // Status Dot
                Circle()
                    .fill(mode.isDefault ? Color.green : Color.secondary.opacity(0.3))
                    .frame(width: 8, height: 8)
                
                // Icon
                ZStack {
                    Circle()
                        .fill(providerColor.opacity(0.1))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: iconName)
                        .font(.system(size: 16))
                        .foregroundStyle(providerColor)
                }
                
                // Details
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(mode.name)
                            .font(.hyperUI(.body, weight: .semibold))
                            .foregroundStyle(.primary)
                        
                        if mode.isDefault {
                            Text("Default")
                                .font(.hyperData(9, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.green.opacity(0.8)))
                        }
                    }
                    
                    Text(descriptionText)
                        .font(.hyperUI(.caption))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Edit Chevron (only visible on hover)
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .opacity(isHovered ? 1.0 : 0.0)
            }
            .padding(HyperSpacing.md)
            .background(
                Group {
                    if isHovered {
                        RoundedRectangle(cornerRadius: HyperRadius.md)
                            .fill(.ultraThinMaterial)
                    } else {
                        RoundedRectangle(cornerRadius: HyperRadius.md)
                            .fill(Color.clear)
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: HyperRadius.md)
                    .stroke(isHovered ? Color.glassBorder : Color.clear, lineWidth: 0.5)
            )
            .contentShape(Rectangle()) // Hit test entire row
            .animation(.hyperSpring, value: isHovered)
        }
        .buttonStyle(.plain)
    }
    
    private var providerColor: Color {
        switch mode.providerType {
        case .openAI: return .providerOpenAI
        case .anthropic: return .providerAnthropic
        case .local: return .purple
        case .none: return .secondary
        case .ollama: return .orange
        case .gemini: return .blue
        case .groq: return .red
        case .openRouter: return .cyan
        }
    }
    
    private var iconName: String {
        switch mode.providerType {
        case .openAI: return "brain"
        case .anthropic: return "sparkles"
        case .local: return "laptopcomputer"
        case .none: return "mic"
        case .ollama: return "flame"
        case .gemini: return "star.fill"
        case .groq: return "bolt.fill"
        case .openRouter: return "network"
        }
    }
    
    private var descriptionText: String {
        if mode.type == .classic {
            return "Raw Transcription"
        } else {
            return "\(mode.type.rawValue) • \(mode.providerType.rawValue.capitalized)"
        }
    }
}