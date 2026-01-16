import SwiftUI
import SwiftData

struct DashboardHomeView: View {
    @Binding var selectedTab: DashboardView.Tab
    @Query(sort: \TranscriptionRecord.createdAt, order: .reverse) private var history: [TranscriptionRecord]
    
    // Computed Stats
    private var wordsToday: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return history
            .filter { $0.createdAt >= today }
            .reduce(0) { count, record in
                count + record.processedText.split(separator: " ").count
            }
    }
    
    private var timeSavedString: String {
        // Assumption: Speaking (150 wpm) is ~3x faster than typing (40 wpm).
        // Time saved = Typing Time - Speaking Time
        // Typing Time = Words / 40
        // Speaking Time = Words / 150
        // Simplified: Words * (1/40 - 1/150) ~= Words * 0.0183 minutes
        let minutesSaved = Double(wordsToday) * 0.0183
        
        if minutesSaved < 1 {
            return String(format: "%.1f min", minutesSaved)
        } else if minutesSaved < 60 {
            return String(format: "%.0f min", minutesSaved)
        } else {
             return String(format: "%.1f hrs", minutesSaved / 60)
        }
    }
    
    private var wpm: Int {
        // Just a placeholder or average?
        // Let's use a static "Target" or "Avg" for now, or calculate based on audio duration if available
        return 150 // Standard speaking rate
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                
                // MARK: - Welcome Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Good morning")
                        .font(.hyperUI(.largeTitle, weight: .bold))
                    
                    Text("Ready to transcribe your thoughts?")
                        .font(.hyperUI(.title3))
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 16)
                
                // MARK: - Stats Row
                HStack(spacing: 16) {
                    // StatCard(title: "Speed", value: "\(wpm) WPM", icon: "speedometer", color: .orange)
                    StatCard(title: "Words Today", value: "\(wordsToday)", subValue: "words dictated", icon: "text.quote", color: .blue)
                    StatCard(title: "Time Saved", value: timeSavedString, subValue: "estimated today", icon: "clock.badge.checkmark", color: .green)
                }
                
                // MARK: - Get Started
                VStack(alignment: .leading, spacing: 16) {
                    Text("Actions")
                        .font(.hyperUI(.headline, weight: .semibold))
                        .foregroundStyle(.secondary)
                    
                    GlassCard(padding: 0) {
                        VStack(spacing: 0) {
                            ActionRow(
                                title: "Create Custom Mode",
                                subtitle: "Tailor AI behavior for coding",
                                icon: "slider.horizontal.3",
                                color: .blue,
                                shortcut: nil
                            ) {
                                selectedTab = .modes
                            }
                            
                            Divider()
                                .padding(.leading, 56)
                            
                            ActionRow(
                                title: "Configure Shortcuts",
                                subtitle: "Customize your workflow",
                                icon: "keyboard",
                                color: .gray,
                                shortcut: "⌘ ,"
                            ) {
                                selectedTab = .configuration
                            }
                        }
                    }
                }
            }
            .padding(32)
        }
    }
}

// MARK: - Components

struct StatCard: View {
    let title: String
    let value: String
    var subValue: String? = nil
    let icon: String
    let color: Color
    
    var body: some View {
        GlassCard(padding: 20) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(color.opacity(0.1))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: icon)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(color)
                    }
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(value)
                        .font(.hyperUI(.title2, weight: .bold))
                        .contentTransition(.numericText())
                    
                    HStack(spacing: 4) {
                        Text(title)
                            .font(.hyperUI(.caption, weight: .medium))
                            .foregroundStyle(.secondary)
                        
                        if let sub = subValue {
                            Text("•")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                            Text(sub)
                                .font(.hyperUI(.caption2))
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }
        }
    }
}

struct ActionRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let shortcut: String?
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(color.opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundStyle(color)
                }
                
                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.hyperUI(.body, weight: .medium))
                        .foregroundStyle(.primary)
                    
                    Text(subtitle)
                        .font(.hyperUI(.subheadline))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Shortcut Pill
                if let shortcut = shortcut {
                    Text(shortcut)
                        .font(.hyperData(11, weight: .bold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(6)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundStyle(.tertiary)
                        .opacity(isHovered ? 1 : 0)
                }
            }
            .padding(16)
            .background(isHovered ? Color.secondary.opacity(0.05) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}
