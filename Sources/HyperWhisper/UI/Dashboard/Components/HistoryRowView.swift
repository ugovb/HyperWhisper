import SwiftUI

struct HistoryRowView: View {
    let record: TranscriptionRecord
    let isSelected: Bool
    
    // Derived localized date string
    private var dateString: String {
        record.createdAt.formatted(.dateTime.day().month().hour().minute())
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center) {
                // Mode Badge - Pill style
                Text(record.modeName)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(Capsule())
                
                Spacer()
                
                // Timestamp
                Text(dateString)
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
            
            // Content
            Text(record.processedText)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(.primary.opacity(0.9))
                .lineLimit(3)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Footer (Length / Actions)
            if record.audioPath != nil {
                HStack {
                    Spacer()
                    Image(systemName: "waveform")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.accentColor.opacity(0.8))
                }
                .padding(.top, 2)
            }
        } // End Main VStack
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.accentColor.opacity(0.1) : Color(nsColor: .controlBackgroundColor))
        )
        // Only show stroke when selected or hovered (hover logic not here) for cleaner look
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.accentColor.opacity(0.4) : Color.clear, lineWidth: 1)
        )
    }
}
