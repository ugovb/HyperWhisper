import SwiftUI

struct HUDView: View {
    @ObservedObject var audioState: AudioState
    
    var body: some View {
        HStack(spacing: 8) {
            // Animated Status Indicator
            ZStack {
                Circle()
                    .fill(audioState.isRecording ? Color.red : Color.secondary)
                    .frame(width: 8, height: 8)
                
                if audioState.isRecording {
                    Circle()
                        .stroke(Color.red.opacity(0.4), lineWidth: 2)
                        .frame(width: 14, height: 14)
                        .scaleEffect(audioState.isRecording ? 1.1 : 0.8)
                        .opacity(audioState.isRecording ? 1 : 0)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: audioState.isRecording)
                }
            }
            .padding(.leading, 4)
            
            // Modern Waveform
            if audioState.isRecording {
                ModernWaveformView(amplitude: audioState.amplitude)
                    .frame(width: 60, height: 16)
            } else {
                Text("Ready")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .frame(width: 60)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
    }
}

struct ModernWaveformView: View {
    var amplitude: Float
    // Smooth random seed for "alive" feel
    @State private var phase: CGFloat = 0
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<8) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.primary.opacity(0.8))
                    .frame(width: 3, height: height(for: index))
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: amplitude)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                phase = 1
            }
        }
    }
    
    func height(for index: Int) -> CGFloat {
        // Dynamic height based on amplitude and index
        let baseHeight: CGFloat = 4
        // Center-weighted distribution
        let centerDist = abs(3.5 - CGFloat(index))
        let scale = max(0.2, 1.0 - (centerDist * 0.2))
        
        let ampHeight = CGFloat(amplitude) * 35 * scale
        
        // Add subtle idle movement
        let idle = CGFloat.random(in: 2...4)
        
        return max(baseHeight, min(22, idle + ampHeight))
    }
}


