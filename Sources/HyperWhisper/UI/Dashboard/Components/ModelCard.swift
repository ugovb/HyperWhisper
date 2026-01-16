import SwiftUI

// MARK: - AIModel
/// UI model that wraps ModelDownloadInfo with additional display properties
struct AIModel: Identifiable {
    let id: UUID
    let name: String
    let description: String
    let expectedSize: String
    var status: Status
    var progress: Double
    let provider: ModelProvider
    let isMultilingual: Bool
    let version: String?
    let ramUsage: String?
    let ramPercentage: CGFloat
    
    enum Status {
        case notDownloaded
        case downloading
        case paused
        case downloaded
        case error
        
        init(from downloadStatus: DownloadStatus) {
            switch downloadStatus {
            case .notDownloaded: self = .notDownloaded
            case .downloading: self = .downloading
            case .paused: self = .paused
            case .downloaded: self = .downloaded
            case .error: self = .error
            }
        }
    }
}

// MARK: - ModelDownloadInfo Extension
extension ModelDownloadInfo {
    /// Convert to UI-friendly AIModel
    var asAIModel: AIModel {
        AIModel(
            id: UUID(uuidString: id) ?? UUID(),
            name: name,
            description: description,
            expectedSize: expectedSize,
            status: AIModel.Status(from: status),
            progress: progress,
            provider: inferProvider(),
            isMultilingual: isMultilingual,
            version: inferVersion(),
            ramUsage: status == .downloaded ? estimatedRAM : nil,
            ramPercentage: status == .downloaded ? estimatedRAMPercentage : 0
        )
    }
    
    private func inferProvider() -> ModelProvider {
        let lowercaseName = name.lowercased()
        if lowercaseName.contains("parakeet") { return .nvidia }
        if lowercaseName.contains("whisper") { return .openai }
        if lowercaseName.contains("llama") { return .meta }
        if lowercaseName.contains("mlx") { return .apple }
        return .huggingface
    }
    
    private func inferVersion() -> String? {
        if name.lowercased().contains("v3") { return "v3" }
        if name.lowercased().contains("v2") { return "v2" }
        if name.lowercased().contains("0.6b") { return "0.6B" }
        if name.lowercased().contains("1.1b") { return "1.1B" }
        return nil
    }
    
    private var isMultilingual: Bool {
        description.lowercased().contains("multilingual") ||
        description.lowercased().contains("multi-lingual")
    }
    
    private var estimatedRAM: String {
        // Rough estimation based on model size
        if minSizeBytes > 2_000_000_000 { return "6.4 GB VRAM" }
        if minSizeBytes > 1_000_000_000 { return "3.2 GB VRAM" }
        return "1.6 GB VRAM"
    }
    
    private var estimatedRAMPercentage: CGFloat {
        // Rough estimation (assuming 16GB unified memory)
        if minSizeBytes > 2_000_000_000 { return 0.4 }
        if minSizeBytes > 1_000_000_000 { return 0.2 }
        return 0.1
    }
}

// MARK: - Model Card (Updated to use ModelDownloadInfo)
/// Premium model card with provider branding, specs badges, RAM usage, and download ring
struct ModelCard: View {
    let model: ModelDownloadInfo
    let onDownload: () -> Void
    let onPause: () -> Void
    let onCancel: () -> Void
    let onResume: () -> Void
    
    @State private var isHovered = false
    
    private var aiModel: AIModel { model.asAIModel }
    
    var body: some View {
        VStack(alignment: .leading, spacing: HyperSpacing.md) {
            // Header with provider branding
            HStack {
                // Provider badge
                HStack(spacing: HyperSpacing.xs) {
                    Image(systemName: aiModel.provider.icon)
                        .font(.system(size: 12, weight: .semibold))
                    Text(aiModel.provider.rawValue)
                        .font(.hyperUI(.caption, weight: .semibold))
                }
                .foregroundStyle(aiModel.provider.color)
                .padding(.horizontal, HyperSpacing.sm)
                .padding(.vertical, HyperSpacing.xs)
                .background(aiModel.provider.color.opacity(0.15))
                .clipShape(Capsule())
                
                Spacer()
                
                // Download status / action
                DownloadStatusView(
                    status: aiModel.status,
                    progress: aiModel.progress,
                    onDownload: onDownload,
                    onPause: onPause,
                    onCancel: onCancel,
                    onResume: onResume
                )
            }
            
            // Model name and description
            VStack(alignment: .leading, spacing: HyperSpacing.xs) {
                Text(model.name)
                    .font(.hyperUI(.headline, weight: .semibold))
                    .foregroundStyle(.primary)
                
                Text(model.description)
                    .font(.hyperUI(.caption))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            
            // Specs badges
            HStack(spacing: HyperSpacing.xs) {
                BadgeChip(text: model.expectedSize, color: .blue, style: .subtle)
                
                if aiModel.isMultilingual {
                    BadgeChip(text: "Multilingual", color: .green, style: .subtle)
                }
                
                if let version = aiModel.version {
                    BadgeChip(text: version, color: .orange, style: .subtle)
                }
            }
            
            // RAM usage bar (for downloaded local models)
            if model.status == .downloaded, let ramUsage = aiModel.ramUsage {
                VStack(alignment: .leading, spacing: HyperSpacing.xs) {
                    HStack {
                        Text("Estimated RAM")
                            .font(.hyperData(10))
                            .foregroundStyle(.tertiary)
                        Spacer()
                        Text(ramUsage)
                            .font(.hyperData(10, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                    
                    // RAM bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.secondary.opacity(0.2))
                            
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [aiModel.provider.color, aiModel.provider.color.opacity(0.7)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * aiModel.ramPercentage)
                        }
                    }
                    .frame(height: 6)
                }
            }
        }
        .padding(HyperSpacing.lg)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: HyperRadius.lg)
                    .fill(.ultraThinMaterial)
                
                // Subtle gradient overlay
                RoundedRectangle(cornerRadius: HyperRadius.lg)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.05), Color.clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: HyperRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: HyperRadius.lg)
                .stroke(
                    isHovered ? aiModel.provider.color.opacity(0.5) : Color.glassBorder,
                    lineWidth: isHovered ? 1.5 : 1
                )
        )
        .hyperShadow(radius: isHovered ? 14 : 8, y: isHovered ? 6 : 4)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.hyperSpring, value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Download Status View (Circular Progress Ring)
struct DownloadStatusView: View {
    let status: AIModel.Status
    let progress: Double
    let onDownload: () -> Void
    let onPause: () -> Void
    let onCancel: () -> Void
    let onResume: () -> Void
    
    var body: some View {
        switch status {
        case .notDownloaded:
            Button(action: onDownload) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Color(hex: 0x6366F1))
            }
            .buttonStyle(.plain)
            
        case .downloading:
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 3)
                    .frame(width: 36, height: 36)
                
                // Progress ring
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        Color(hex: 0x6366F1),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 36, height: 36)
                    .rotationEffect(.degrees(-90))
                
                // Pause button
                Button(action: onPause) {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)
            }
            .contextMenu {
                Button("Cancel Download", role: .destructive, action: onCancel)
            }
            
        case .paused:
            Button(action: onResume) {
                ZStack {
                    Circle()
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 3)
                        .frame(width: 36, height: 36)
                    
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(Color.orange, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 36, height: 36)
                        .rotationEffect(.degrees(-90))
                    
                    Image(systemName: "play.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.orange)
                }
            }
            .buttonStyle(.plain)
            
        case .downloaded:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 28))
                .foregroundStyle(.green)
            
        case .error:
            Button(action: onDownload) {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
        }
    }
}
