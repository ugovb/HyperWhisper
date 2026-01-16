import SwiftUI

struct TranscriptLiveView: View {
    @EnvironmentObject var appState: AppState
    
    // Color mapping for speakers
    private let speakerColors: [Color] = [
        .blue, .green, .orange, .purple, .pink, .yellow
    ]
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(appState.currentTranscript) { segment in
                        TranscriptRow(segment: segment, color: speakerColor(for: segment.speakerID))
                            .id(segment.id)
                    }
                }
                .padding()
            }
            .onChange(of: appState.currentTranscript.count) { _ in
                scrollLast(proxy: proxy)
            }
        }
        .overlay(alignment: .topTrailing) {
            LanguageOverlay(language: appState.detectedLanguage)
        }
        .overlay(alignment: .bottom) {
            LoadingOverlay(isReady: appState.isModelReady)
        }
    }
    
    private func scrollLast(proxy: ScrollViewProxy) {
        withAnimation {
            if let lastID = appState.currentTranscript.last?.id {
                proxy.scrollTo(lastID, anchor: .bottom)
            }
        }
    }
    
    private func speakerColor(for speaker: String) -> Color {
        let speakerNumber = Int(speaker.filter(\.isNumber)) ?? 0
        return speakerColors[speakerNumber % speakerColors.count]
    }
}

struct TranscriptRow: View {
    let segment: TranscriptionSegment
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Speaker badge
            Text(segment.speakerID)
                .font(.caption)
                .fontWeight(.semibold)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(color)
                .foregroundColor(.white)
                .cornerRadius(6)
            
            // Transcript text
            VStack(alignment: .leading, spacing: 4) {
                Text(segment.text)
                    .font(.body)
                
                Text(formatTimestamp(segment.startTime))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    private func formatTimestamp(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct LanguageOverlay: View {
    let language: String
    
    var body: some View {
        if language != "auto" {
            Text("🌐 \(language.uppercased())")
                .font(.caption)
                .padding(8)
                .background(.ultraThinMaterial)
                .cornerRadius(8)
                .padding()
        }
    }
}

struct LoadingOverlay: View {
    let isReady: Bool
    
    var body: some View {
        if !isReady {
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                Text("Loading Whisper model...")
                    .font(.caption)
            }
            .padding(8)
            .background(.regularMaterial)
            .cornerRadius(8)
            .padding()
        }
    }
}