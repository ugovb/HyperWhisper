import SwiftUI
import AppKit

struct DashboardView: View {
    enum Tab: String, CaseIterable, Identifiable {
        case home = "Home"
        case modes = "Modes"
        case configuration = "Configuration"
        case history = "History"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .modes: return "slider.horizontal.3"
            case .configuration: return "gearshape.fill"
            case .history: return "clock.fill"
            }
        }
        
        var iconColor: Color {
            switch self {
            case .home: return .orange
            case .modes: return .blue
            case .configuration: return .gray
            case .history: return .purple
            }
        }
    }
    
    enum SettingsTab: String, CaseIterable, Identifiable {
        case configuration = "General"
        
        var id: String { rawValue }
    }
    
    @State private var selectedTab: Tab = .home
    @State private var selectedSettingsTab: SettingsTab = .configuration
    @EnvironmentObject var appState: AppState // Ensure AppState is available
    
    init(initialTab: Tab = .home) {
        _selectedTab = State(initialValue: initialTab)
    }

    var body: some View {
        NavigationSplitView {
            ZStack(alignment: .bottom) {
                // Main Navigation List
                List(selection: $selectedTab) {
                    Section {
                        NavigationLink(value: Tab.home) {
                            Label {
                                Text(Tab.home.rawValue)
                                    .font(.hyperUI(.body, weight: .medium))
                            } icon: {
                                Image(systemName: Tab.home.icon)
                                    .foregroundStyle(Tab.home.iconColor)
                            }
                        }
                    } header: {
                        Text("Dashboard")
                            .font(.hyperUI(.caption, weight: .bold))
                            .foregroundStyle(.secondary)
                    }
                    
                    Section {
                        NavigationLink(value: Tab.modes) {
                            Label {
                                Text(Tab.modes.rawValue)
                                    .font(.hyperUI(.body, weight: .medium))
                            } icon: {
                                Image(systemName: Tab.modes.icon)
                                    .foregroundStyle(Tab.modes.iconColor)
                            }
                        }
                        
                        NavigationLink(value: Tab.history) {
                            Label {
                                Text(Tab.history.rawValue)
                                    .font(.hyperUI(.body, weight: .medium))
                            } icon: {
                                Image(systemName: Tab.history.icon)
                                    .foregroundStyle(Tab.history.iconColor)
                            }
                        }
                        
                    } header: {
                        Text("Intelligence")
                            .font(.hyperUI(.caption, weight: .bold))
                            .foregroundStyle(.secondary)
                    }
                    
                    Section {
                        NavigationLink(value: Tab.configuration) {
                            Label {
                                Text(Tab.configuration.rawValue)
                                    .font(.hyperUI(.body, weight: .medium))
                            } icon: {
                                Image(systemName: Tab.configuration.icon)
                                    .foregroundStyle(Tab.configuration.iconColor)
                            }
                        }
                        

                    } header: {
                        Text("Settings")
                            .font(.hyperUI(.caption, weight: .bold))
                            .foregroundStyle(.secondary)
                    }
                }
                .listStyle(.sidebar)
                .scrollContentBackground(.hidden)
                .padding(.bottom, 100) // Space for footer
                
                // Sidebar Footer with Pro Badge and Status Pill
                VStack(spacing: 12) {

                    
                    DynamicStatusPill()
                }
                .padding()
                .background(
                    VisualEffectView(material: .sidebar, blendingMode: .behindWindow)
                        .mask(
                            LinearGradient(
                                stops: [
                                    .init(color: .clear, location: 0),
                                    .init(color: .black, location: 0.2)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
            }
            .navigationSplitViewColumnWidth(min: 220, ideal: 240, max: 300)
            .background(VisualEffectView(material: .sidebar, blendingMode: .behindWindow).ignoresSafeArea())
            
        } detail: {
            ZStack {
                // Background
                Color(nsColor: .windowBackgroundColor)
                    .ignoresSafeArea()
                
                // Content
                switch selectedTab {
                case .home:
                    DashboardHomeView(selectedTab: $selectedTab)
                case .modes:
                    ModesView()
                case .configuration:
                    ConfigurationView()
                case .history:
                    HistoryView()
                }
            }
        }
    }
}

// Custom Settings Tab Button
struct SettingsTabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(title)
                    .font(.system(size: 13, weight: .medium))
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(isSelected ? Color.secondary.opacity(0.1) : Color.clear)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.secondary.opacity(0.2) : Color.clear, lineWidth: 0.5)
            )
            .foregroundStyle(isSelected ? .primary : .secondary)
        }
        .buttonStyle(.plain)
    }
}

// Helper for NSVisualEffectView in SwiftUI
struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
        visualEffectView.state = .active
        return visualEffectView
    }
    
    func updateNSView(_ visualEffectView: NSVisualEffectView, context: Context) {
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
    }
}
