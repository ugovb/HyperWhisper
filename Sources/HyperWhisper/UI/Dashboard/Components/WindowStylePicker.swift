import SwiftUI

// MARK: - Window Style Picker
/// Graphical previews for recording window style (Solo/Mini/None)
struct WindowStylePicker: View {
    @Binding var selectedStyle: WindowStyle
    
    enum WindowStyle: String, CaseIterable, Identifiable {
        case solo = "Solo"
        case mini = "Mini"
        case none = "None"
        
        var id: String { rawValue }
        
        var description: String {
            switch self {
            case .solo: return "Full window"
            case .mini: return "Compact HUD"
            case .none: return "Hidden"
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: HyperSpacing.sm) {
            Text("Recording Window Style")
                .font(.hyperUI(.subheadline, weight: .medium))
                .foregroundStyle(.secondary)
            
            HStack(spacing: HyperSpacing.md) {
                ForEach(WindowStyle.allCases) { style in
                    WindowStyleCard(
                        style: style,
                        isSelected: selectedStyle == style
                    ) {
                        withAnimation(.hyperSpring) {
                            selectedStyle = style
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Window Style Card
struct WindowStyleCard: View {
    let style: WindowStylePicker.WindowStyle
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: HyperSpacing.sm) {
                // Preview
                ZStack {
                    // Screen background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: 0x1a1a2e))
                        .frame(width: 80, height: 50)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.glassBorder, lineWidth: 0.5)
                        )
                    
                    // Window preview
                    windowPreview
                }
                
                // Label
                VStack(spacing: 2) {
                    Text(style.rawValue)
                        .font(.hyperUI(.caption, weight: isSelected ? .semibold : .regular))
                        .foregroundStyle(isSelected ? .primary : .secondary)
                    
                    Text(style.description)
                        .font(.hyperData(9))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(HyperSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: HyperRadius.md)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: HyperRadius.md)
                    .stroke(
                        isSelected
                            ? Color.accentColor.opacity(0.5)
                            : (isHovered ? Color.glassBorder : Color.clear),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
            .scaleEffect(isHovered ? 1.03 : 1.0)
            .animation(.hyperSpring, value: isHovered)
            .animation(.hyperSpring, value: isSelected)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    @ViewBuilder
    private var windowPreview: some View {
        switch style {
        case .solo:
            // Full window preview
            RoundedRectangle(cornerRadius: 3)
                .fill(.ultraThinMaterial)
                .frame(width: 50, height: 30)
                .overlay(
                    VStack(spacing: 2) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 6, height: 6)
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.secondary.opacity(0.5))
                            .frame(width: 30, height: 3)
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.secondary.opacity(0.3))
                            .frame(width: 20, height: 2)
                    }
                )
            
        case .mini:
            // Compact HUD preview
            Capsule()
                .fill(.ultraThinMaterial)
                .frame(width: 45, height: 14)
                .overlay(
                    HStack(spacing: 3) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 5, height: 5)
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.secondary.opacity(0.5))
                            .frame(width: 20, height: 3)
                    }
                )
            
        case .none:
            // Just a subtle indicator
            Image(systemName: "eye.slash")
                .font(.system(size: 16))
                .foregroundStyle(Color.secondary.opacity(0.5))
        }
    }
}

// MARK: - Preview
#Preview("Window Style Picker") {
    struct PreviewWrapper: View {
        @State private var style: WindowStylePicker.WindowStyle = .mini
        
        var body: some View {
            ZStack {
                Color(hex: 0x1a1a2e)
                    .ignoresSafeArea()
                
                WindowStylePicker(selectedStyle: $style)
                    .padding()
            }
            .frame(width: 400, height: 200)
        }
    }
    
    return PreviewWrapper()
}
