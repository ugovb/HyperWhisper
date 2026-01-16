import SwiftUI

// MARK: - StatusPill
/// A sidebar status indicator with pulsing animation for active states
struct StatusPill: View {
    let status: HyperStatus
    
    @State private var isPulsing = false
    
    var body: some View {
        HStack(spacing: HyperSpacing.sm) {
            // Pulsing dot
            ZStack {
                // Pulse ring (visible when active)
                if status.isPulsing {
                    Circle()
                        .stroke(status.color.opacity(0.4), lineWidth: 2)
                        .frame(width: 14, height: 14)
                        .scaleEffect(isPulsing ? 1.6 : 1.0)
                        .opacity(isPulsing ? 0 : 0.8)
                }
                
                // Core dot
                Circle()
                    .fill(status.color)
                    .frame(width: 8, height: 8)
                    .shadow(color: status.color.opacity(0.6), radius: 3, x: 0, y: 0)
            }
            .frame(width: 16, height: 16)
            
            // Status text
            Text(status.rawValue)
                .font(.hyperUI(.caption, weight: .medium))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, HyperSpacing.md)
        .padding(.vertical, HyperSpacing.sm)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.glassBorder, lineWidth: 0.5)
        )
        .onAppear {
            if status.isPulsing {
                withAnimation(.hyperPulse) {
                    isPulsing = true
                }
            }
        }
        .onChange(of: status) { _, newStatus in
            if newStatus.isPulsing {
                isPulsing = false
                withAnimation(.hyperPulse) {
                    isPulsing = true
                }
            } else {
                isPulsing = false
            }
        }
    }
}

// MARK: - Dynamic Status Pill (observes AppState)
struct DynamicStatusPill: View {
    @EnvironmentObject var appState: AppState
    
    var currentStatus: HyperStatus {
        if appState.isRecording {
            return .recording
        } else if appState.audioState.status == .processing {
            return .processing
        } else {
            // Check if Parakeet model is loaded
            // For now, default to micReady
            return .micReady
        }
    }
    
    var body: some View {
        StatusPill(status: currentStatus)
    }
}

// MARK: - Preview
#Preview("StatusPill") {
    ZStack {
        LinearGradient(
            colors: [Color(hex: 0x1a1a2e), Color(hex: 0x16213e)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        VStack(spacing: 16) {
            ForEach(HyperStatus.allCases, id: \.self) { status in
                StatusPill(status: status)
            }
        }
        .padding()
    }
    .frame(width: 200, height: 300)
}
