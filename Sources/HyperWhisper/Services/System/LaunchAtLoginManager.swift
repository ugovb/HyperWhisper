import Foundation
import ServiceManagement

@MainActor
class LaunchAtLoginManager: ObservableObject {
    static let shared = LaunchAtLoginManager()
    
    @Published var isEnabled: Bool {
        didSet {
            updateRegistration()
        }
    }
    
    init() {
        self.isEnabled = SMAppService.mainApp.status == .enabled
    }
    
    private func updateRegistration() {
        do {
            if isEnabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                }
            }
        } catch {
            print("Failed to update Launch at Login: \(error)")
        }
    }
}
