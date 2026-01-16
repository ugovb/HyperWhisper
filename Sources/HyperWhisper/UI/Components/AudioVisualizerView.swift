import SwiftUI

// MARK: - Audio Visualizer View
/// Dynamic bar chart waveform that animates based on input amplitude
struct AudioVisualizerView: View {
    let amplitude: Float
    let barCount: Int
    let barSpacing: CGFloat
    let cornerRadius: CGFloat
    var accentColor: Color = Color(hex: 0x6366F1)
    
    init(
        amplitude: Float,
        barCount: Int = 24,
        barSpacing: CGFloat = 3,
        cornerRadius: CGFloat = 2,
        accentColor: Color = Color(hex: 0x6366F1)
    ) {
        self.amplitude = amplitude
        self.barCount = barCount
        self.barSpacing = barSpacing
        self.cornerRadius = cornerRadius
        self.accentColor = accentColor
    }
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: barSpacing) {
                ForEach(0..<barCount, id: \.self) { index in
                    AudioBar(
                        height: barHeight(for: index, maxHeight: geometry.size.height),
                        maxHeight: geometry.size.height,
                        cornerRadius: cornerRadius,
                        color: barColor(for: index)
                    )
                }
            }
        }
    }
    
    private func barHeight(for index: Int, maxHeight: CGFloat) -> CGFloat {
        // Create wave pattern with amplitude influence
        let baseHeight: CGFloat = 8
        let center = CGFloat(barCount) / 2
        let distance = abs(CGFloat(index) - center)
        let normalizedDistance = distance / center
        
        // Wave pattern: higher in center, lower at edges
        let waveMultiplier = 1.0 - (normalizedDistance * 0.5)
        
        // Random variation for liveliness
        let randomFactor = CGFloat.random(in: 0.7...1.3)
        
        // Amplitude influence
        let ampInfluence = CGFloat(amplitude) * maxHeight * 0.8
        
        let height = baseHeight + (ampInfluence * waveMultiplier * randomFactor)
        return max(baseHeight, min(height, maxHeight))
    }
    
    private func barColor(for index: Int) -> Color {
        // Gradient from accent to secondary based on amplitude
        let normalizedAmp = CGFloat(min(amplitude, 1.0))
        
        if normalizedAmp > 0.8 {
            return .red
        } else if normalizedAmp > 0.5 {
            return .orange
        } else {
            return accentColor
        }
    }
}

// MARK: - Audio Bar
struct AudioBar: View {
    let height: CGFloat
    let maxHeight: CGFloat
    let cornerRadius: CGFloat
    let color: Color
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(
                LinearGradient(
                    colors: [color, color.opacity(0.6)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(height: height)
            .frame(maxHeight: maxHeight, alignment: .center)
            .animation(.hyperWaveform, value: height)
    }
}

// MARK: - Audio Level Meter
/// Simple horizontal level meter with color zones
struct AudioLevelMeter: View {
    let amplitude: Float
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                Capsule()
                    .fill(Color.secondary.opacity(0.2))
                
                // Active level with gradient
                Capsule()
                    .fill(levelGradient)
                    .frame(width: max(CGFloat(amplitude) * geometry.size.width, 0))
                    .animation(.hyperWaveform, value: amplitude)
            }
        }
        .frame(height: 8)
    }
    
    private var levelGradient: LinearGradient {
        LinearGradient(
            colors: levelColors,
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    private var levelColors: [Color] {
        if amplitude > 0.8 {
            return [.green, .yellow, .orange, .red]
        } else if amplitude > 0.5 {
            return [.green, .yellow, .orange]
        } else {
            return [.green, .green.opacity(0.8)]
        }
    }
}

// MARK: - Preview
#Preview("Audio Visualizer") {
    struct PreviewWrapper: View {
        @State private var amplitude: Float = 0.3
        
        var body: some View {
            ZStack {
                Color(hex: 0x1a1a2e)
                    .ignoresSafeArea()
                
                VStack(spacing: 32) {
                    // Bar visualizer
                    AudioVisualizerView(amplitude: amplitude)
                        .frame(height: 60)
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Level meter
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Input Level")
                            .font(.hyperUI(.caption))
                            .foregroundStyle(.secondary)
                        
                        AudioLevelMeter(amplitude: amplitude)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Slider to test
                    Slider(value: $amplitude, in: 0...1)
                        .padding()
                }
                .padding()
            }
            .frame(width: 400, height: 350)
        }
    }
    
    return PreviewWrapper()
}
