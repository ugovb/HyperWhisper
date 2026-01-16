import SwiftUI

// MARK: - HyperWhisper Design System
// A "Cyber-Native" glassmorphic design system for premium macOS aesthetics

// MARK: - Color Tokens
extension Color {
    // MARK: Brand Gradients
    static let hyperAccentGradient = LinearGradient(
        colors: [Color(hex: 0x6366F1), Color(hex: 0x8B5CF6)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let hyperRecordingGradient = LinearGradient(
        colors: [Color(hex: 0xEF4444), Color(hex: 0xF97316)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: Provider Brand Colors
    static let providerNVIDIA = Color(hex: 0x76B900)   // NVIDIA Green
    static let providerOpenAI = Color(hex: 0x10A37F)   // OpenAI Teal
    static let providerAnthropic = Color(hex: 0xD97757) // Anthropic Terracotta
    static let providerMeta = Color(hex: 0x0668E1)     // Meta Blue
    static let providerApple = Color(hex: 0xA855F7)    // Apple Purple
    static let providerHuggingFace = Color(hex: 0xFFD21E) // HuggingFace Yellow
    
    // MARK: Semantic Colors
    static let hyperSuccess = Color(hex: 0x22C55E)
    static let hyperWarning = Color(hex: 0xF59E0B)
    static let hyperError = Color(hex: 0xEF4444)
    static let hyperInfo = Color(hex: 0x3B82F6)
    
    // MARK: Glass Colors
    static let glassBorder = Color.white.opacity(0.15)
    static let glassHighlight = Color.white.opacity(0.08)
    static let glassShadow = Color.black.opacity(0.25)
    
    // MARK: Chart Colors
    static let chartGradientTop = Color(hex: 0x6366F1).opacity(0.6)
    static let chartGradientBottom = Color(hex: 0x6366F1).opacity(0.1)
    
    // MARK: Sidebar Icon Colors
    static let sidebarHome = Color(hex: 0xF97316)      // Orange
    static let sidebarHistory = Color(hex: 0x3B82F6)   // Blue
    static let sidebarModes = Color(hex: 0x22C55E)     // Green
    static let sidebarVocabulary = Color(hex: 0xA855F7) // Purple
    static let sidebarSettings = Color(hex: 0x6B7280)  // Gray
    
    // Hex initializer
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 08) & 0xff) / 255,
            blue: Double((hex >> 00) & 0xff) / 255,
            opacity: alpha
        )
    }
}

// MARK: - Typography
extension Font {
    // UI Text - Rounded for friendly, modern feel
    static func hyperUI(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        .system(style, design: .rounded, weight: weight)
    }
    
    // Data/Stats - Monospaced for technical precision
    static func hyperData(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
    
    // Timestamps
    static let hyperTimestamp = Font.system(size: 11, weight: .medium, design: .monospaced)
    
    // Stat numbers
    static let hyperStat = Font.system(size: 28, weight: .bold, design: .rounded)
    
    // Badge text
    static let hyperBadge = Font.system(size: 10, weight: .semibold, design: .rounded)
}

// MARK: - Spacing
enum HyperSpacing {
    static let xxs: CGFloat = 2
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
}

// MARK: - Corner Radius
enum HyperRadius {
    static let sm: CGFloat = 6
    static let md: CGFloat = 10
    static let lg: CGFloat = 14
    static let xl: CGFloat = 20
    static let pill: CGFloat = 100
}

// MARK: - Animation Presets
extension Animation {
    static let hyperSpring = Animation.spring(response: 0.35, dampingFraction: 0.7)
    static let hyperSnappy = Animation.spring(response: 0.25, dampingFraction: 0.8)
    static let hyperSmooth = Animation.easeInOut(duration: 0.2)
    static let hyperPulse = Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)
    static let hyperWaveform = Animation.interactiveSpring(response: 0.08, dampingFraction: 0.6)
}

// MARK: - Shadow Presets
extension View {
    func hyperShadow(radius: CGFloat = 10, y: CGFloat = 4) -> some View {
        self.shadow(color: Color.glassShadow, radius: radius, x: 0, y: y)
    }
    
    func hyperGlow(_ color: Color, radius: CGFloat = 8) -> some View {
        self.shadow(color: color.opacity(0.5), radius: radius, x: 0, y: 0)
    }
    
    func dividerBottom() -> some View {
        self.overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(Color.glassBorder),
            alignment: .bottom
        )
    }
    
    func dividerTop() -> some View {
        self.overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(Color.glassBorder),
            alignment: .top
        )
    }
}

// MARK: - Material Backgrounds
struct HyperMaterial {
    static let ultraThin = Material.ultraThinMaterial
    static let thin = Material.thinMaterial
    static let regular = Material.regularMaterial
    static let thick = Material.thickMaterial
    static let ultraThick = Material.ultraThickMaterial
}

// MARK: - Gradient Helpers
extension LinearGradient {
    static func hyperVertical(_ top: Color, _ bottom: Color) -> LinearGradient {
        LinearGradient(colors: [top, bottom], startPoint: .top, endPoint: .bottom)
    }
    
    static func hyperDiagonal(_ start: Color, _ end: Color) -> LinearGradient {
        LinearGradient(colors: [start, end], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    
    // Animated border gradient
    static func hyperBorder(rotation: Angle = .zero) -> AngularGradient {
        AngularGradient(
            colors: [
                Color(hex: 0x6366F1),
                Color(hex: 0xA855F7),
                Color(hex: 0xEC4899),
                Color(hex: 0xF97316),
                Color(hex: 0x6366F1)
            ],
            center: .center,
            angle: rotation
        )
    }
}

// MARK: - Status Types
enum HyperStatus: String, CaseIterable {
    case micReady = "Mic Ready"
    case parakeetLoaded = "Parakeet Loaded"
    case recording = "Recording"
    case processing = "Processing"
    case offline = "Offline"
    
    var color: Color {
        switch self {
        case .micReady: return .hyperSuccess
        case .parakeetLoaded: return .hyperInfo
        case .recording: return .hyperError
        case .processing: return .hyperWarning
        case .offline: return .gray
        }
    }
    
    var isPulsing: Bool {
        switch self {
        case .recording, .processing: return true
        default: return false
        }
    }
}

// MARK: - Provider Types
enum ModelProvider: String, CaseIterable, Identifiable {
    case nvidia = "NVIDIA"
    case openai = "OpenAI"
    case meta = "Meta"
    case apple = "Apple"
    case huggingface = "Hugging Face"
    
    var id: String { rawValue }
    
    var color: Color {
        switch self {
        case .nvidia: return .providerNVIDIA
        case .openai: return .providerOpenAI
        case .meta: return .providerMeta
        case .apple: return .providerApple
        case .huggingface: return .providerHuggingFace
        }
    }
    
    var icon: String {
        switch self {
        case .nvidia: return "cpu"
        case .openai: return "sparkles"
        case .meta: return "brain"
        case .apple: return "apple.logo"
        case .huggingface: return "face.smiling"
        }
    }
}
