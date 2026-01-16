import SwiftUI

// MARK: - GlassCard
/// A premium frosted glass card container with optional hover effects
struct GlassCard<Content: View>: View {
    let cornerRadius: CGFloat
    let padding: CGFloat
    let hoverEnabled: Bool
    @ViewBuilder let content: () -> Content
    
    @State private var isHovered = false
    
    init(
        cornerRadius: CGFloat = HyperRadius.lg,
        padding: CGFloat = HyperSpacing.lg,
        hoverEnabled: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.hoverEnabled = hoverEnabled
        self.content = content
    }
    
    var body: some View {
        content()
            .padding(padding)
            .background(
                ZStack {
                    // Glass background
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)
                    
                    // Inner highlight (top edge)
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.1), Color.clear],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        isHovered && hoverEnabled
                            ? AnyShapeStyle(GlassCardGradient())
                            : AnyShapeStyle(Color.glassBorder),
                        lineWidth: isHovered && hoverEnabled ? 1.5 : 1
                    )
            )
            .hyperShadow(radius: isHovered ? 16 : 10, y: isHovered ? 6 : 4)
            .scaleEffect(isHovered && hoverEnabled ? 1.02 : 1.0)
            .animation(.hyperSpring, value: isHovered)
            .onHover { hovering in
                if hoverEnabled {
                    isHovered = hovering
                }
            }
    }
}

// Helper gradient for hover state
struct GlassCardGradient: ShapeStyle {
    func resolve(in environment: EnvironmentValues) -> some ShapeStyle {
        LinearGradient(
            colors: [
                Color(hex: 0x6366F1).opacity(0.6),
                Color(hex: 0xA855F7).opacity(0.6),
                Color(hex: 0x6366F1).opacity(0.6)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - GlassCard Modifiers
extension View {
    /// Wraps content in a glass card
    func glassCard(
        cornerRadius: CGFloat = HyperRadius.lg,
        padding: CGFloat = HyperSpacing.lg,
        hoverEnabled: Bool = false
    ) -> some View {
        GlassCard(cornerRadius: cornerRadius, padding: padding, hoverEnabled: hoverEnabled) {
            self
        }
    }
}

// MARK: - Compact Glass Card (for smaller elements)
struct GlassChip<Content: View>: View {
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        content()
            .padding(.horizontal, HyperSpacing.sm)
            .padding(.vertical, HyperSpacing.xs)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.glassBorder, lineWidth: 0.5)
            )
    }
}

// MARK: - Badge Chip (for model specs, tags)
struct BadgeChip: View {
    let text: String
    var color: Color = .secondary
    var style: BadgeStyle = .subtle
    
    enum BadgeStyle {
        case subtle, filled
    }
    
    var body: some View {
        Text(text)
            .font(.hyperBadge)
            .foregroundStyle(style == .filled ? .white : color)
            .padding(.horizontal, HyperSpacing.sm)
            .padding(.vertical, HyperSpacing.xxs + 1)
            .background(
                Capsule()
                    .fill(style == .filled ? color : color.opacity(0.15))
            )
            .overlay(
                Capsule()
                    .stroke(color.opacity(0.3), lineWidth: style == .subtle ? 0.5 : 0)
            )
    }
}

// MARK: - Preview
#Preview("GlassCard") {
    ZStack {
        LinearGradient(
            colors: [Color(hex: 0x1a1a2e), Color(hex: 0x16213e)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        VStack(spacing: 20) {
            GlassCard(hoverEnabled: true) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Glass Card")
                        .font(.hyperUI(.headline, weight: .semibold))
                    Text("Hover for glow effect")
                        .font(.hyperUI(.caption))
                        .foregroundStyle(.secondary)
                }
                .frame(width: 200)
            }
            
            HStack(spacing: 8) {
                BadgeChip(text: "1.2 GB", color: .blue)
                BadgeChip(text: "Multilingual", color: .green)
                BadgeChip(text: "v3", color: .orange, style: .filled)
            }
        }
        .padding()
    }
    .frame(width: 400, height: 300)
}
