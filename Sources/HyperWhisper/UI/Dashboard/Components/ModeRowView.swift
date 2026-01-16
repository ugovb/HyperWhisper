import SwiftUI

struct ModeRowView: View {
    let mode: Mode
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon Placeholder based on provider
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 40, height: 40)
                
                Image(systemName: iconForProvider(mode.providerType))
                    .foregroundStyle(Color.accentColor)
                    .font(.system(size: 18))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(mode.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    if mode.isDefault {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.yellow)
                    }
                }
                
                Text(mode.providerType.rawValue.capitalized)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Detail Arrow
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 8)
    }
    
    private func iconForProvider(_ type: ProviderType) -> String {
        switch type {
        case .local: return "laptopcomputer"
        case .ollama: return "terminal"
        case .openAI: return "cloud"
        case .anthropic: return "brain.head.profile"
        case .gemini: return "sparkles"
        case .groq: return "bolt"
        case .openRouter: return "network"
        case .none: return "pencil"
        }
    }
}
