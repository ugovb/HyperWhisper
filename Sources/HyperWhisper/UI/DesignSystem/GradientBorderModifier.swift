import SwiftUI

// MARK: - Animated Gradient Border Modifier
/// Adds an animated rainbow/accent gradient border on hover
struct GradientBorderModifier: ViewModifier {
    let cornerRadius: CGFloat
    let lineWidth: CGFloat
    let isActive: Bool
    
    @State private var rotation: Double = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        AngularGradient(
                            colors: [
                                Color(hex: 0x6366F1),
                                Color(hex: 0x8B5CF6),
                                Color(hex: 0xEC4899),
                                Color(hex: 0xF97316),
                                Color(hex: 0xFACC15),
                                Color(hex: 0x22C55E),
                                Color(hex: 0x06B6D4),
                                Color(hex: 0x6366F1)
                            ],
                            center: .center,
                            startAngle: .degrees(rotation),
                            endAngle: .degrees(rotation + 360)
                        ),
                        lineWidth: lineWidth
                    )
                    .opacity(isActive ? 1 : 0)
            )
            .onChange(of: isActive) { _, active in
                if active {
                    withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                        rotation = 360
                    }
                } else {
                    rotation = 0
                }
            }
    }
}

// MARK: - Static Gradient Border
struct StaticGradientBorderModifier: ViewModifier {
    let cornerRadius: CGFloat
    let lineWidth: CGFloat
    let colors: [Color]
    
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: colors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: lineWidth
                    )
            )
    }
}

// MARK: - Glow Effect Modifier
struct GlowModifier: ViewModifier {
    let color: Color
    let radius: CGFloat
    let isActive: Bool
    
    func body(content: Content) -> some View {
        content
            .shadow(color: isActive ? color.opacity(0.6) : .clear, radius: radius, x: 0, y: 0)
            .shadow(color: isActive ? color.opacity(0.3) : .clear, radius: radius * 2, x: 0, y: 0)
    }
}

// MARK: - View Extensions
extension View {
    /// Adds an animated rainbow border when active (e.g., on hover)
    func animatedGradientBorder(
        cornerRadius: CGFloat = HyperRadius.lg,
        lineWidth: CGFloat = 2,
        isActive: Bool
    ) -> some View {
        modifier(GradientBorderModifier(
            cornerRadius: cornerRadius,
            lineWidth: lineWidth,
            isActive: isActive
        ))
    }
    
    /// Adds a static gradient border
    func gradientBorder(
        cornerRadius: CGFloat = HyperRadius.lg,
        lineWidth: CGFloat = 1,
        colors: [Color] = [Color(hex: 0x6366F1), Color(hex: 0xA855F7)]
    ) -> some View {
        modifier(StaticGradientBorderModifier(
            cornerRadius: cornerRadius,
            lineWidth: lineWidth,
            colors: colors
        ))
    }
    
    /// Adds a glow effect when active
    func glowEffect(
        color: Color = Color(hex: 0x6366F1),
        radius: CGFloat = 8,
        isActive: Bool
    ) -> some View {
        modifier(GlowModifier(
            color: color,
            radius: radius,
            isActive: isActive
        ))
    }
}

// MARK: - Preview
#Preview("Gradient Border") {
    ZStack {
        Color(hex: 0x0f0f1a)
            .ignoresSafeArea()
        
        VStack(spacing: 24) {
            // Animated border
            RoundedRectangle(cornerRadius: HyperRadius.lg)
                .fill(.ultraThinMaterial)
                .frame(width: 200, height: 100)
                .animatedGradientBorder(isActive: true)
                .overlay(
                    Text("Animated Border")
                        .font(.hyperUI(.headline))
                )
            
            // Static gradient
            RoundedRectangle(cornerRadius: HyperRadius.lg)
                .fill(.ultraThinMaterial)
                .frame(width: 200, height: 100)
                .gradientBorder()
                .overlay(
                    Text("Static Gradient")
                        .font(.hyperUI(.headline))
                )
            
            // Glow effect
            Circle()
                .fill(Color(hex: 0x6366F1))
                .frame(width: 60, height: 60)
                .glowEffect(isActive: true)
                .overlay(
                    Image(systemName: "mic.fill")
                        .foregroundStyle(.white)
                )
        }
    }
    .frame(width: 300, height: 400)
}
