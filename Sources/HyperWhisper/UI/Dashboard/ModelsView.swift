import SwiftUI

struct ModelsView: View {
    @State private var manager = ModelManager.shared
    
    // Grid columns for masonry layout
    private let columns = [
        GridItem(.adaptive(minimum: 300, maximum: 400), spacing: HyperSpacing.lg)
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HyperSpacing.xl) {
                // Header
                VStack(alignment: .leading, spacing: HyperSpacing.xs) {
                    Text("AI Models")
                        .font(.hyperUI(.title, weight: .bold))
                    
                    Text("Download and manage local transcription models")
                        .font(.hyperUI(.subheadline))
                        .foregroundStyle(.secondary)
                }
                
                // Model Grid
                LazyVGrid(columns: columns, spacing: HyperSpacing.lg) {
                    ForEach(manager.models) { model in
                        ModelCard(
                            model: model,
                            onDownload: {
                                manager.startDownload(for: model.id)
                            },
                            onPause: {
                                manager.pauseDownload(for: model.id)
                            },
                            onCancel: {
                                manager.cancelDownload(for: model.id)
                            },
                            onResume: {
                                manager.startDownload(for: model.id)
                            }
                        )
                    }
                }
                
                // Info section
                HStack(spacing: HyperSpacing.sm) {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)
                    
                    Text("Models are stored in ~/Library/Application Support/HyperWhisper/models")
                        .font(.hyperUI(.caption))
                        .foregroundStyle(.tertiary)
                }
                .padding(.top, HyperSpacing.md)
            }
            .padding(HyperSpacing.xl)
        }
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.5))
    }
}
