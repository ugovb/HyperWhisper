import Foundation
import ScreenCaptureKit
import AppKit
import OSLog

/// Handles the macOS 15+ recurring permission nag screen.
/// Detects if system audio capture fails due to revoked/nagged permission.
@MainActor
class PermissionReminderHandler {
    static let shared = PermissionReminderHandler()
    private let logger = Logger(subsystem: "com.hyperwhisper", category: "PermissionReminderHandler")
    
    /// Checks validity of Screen Recording permission.
    /// If false but we previously had access, it likely means the monthly reminder was ignored or permission revoked.
    func checkAndRemind() async {
        guard #available(macOS 15.0, *) else { return }
        
        // CGPreflightScreenCaptureAccess returns true if authorised
        let status = CGPreflightScreenCaptureAccess()
        
        logger.info("Screen Capture Access Status: \(status)")
        
        if !status {
            // If the user *should* have access (e.g., they passed onboarding), prompt them code logic would track state.
            // For now, we assume if this is called, we expect to be able to capture.
            
            // Show Alert
            await MainActor.run {
                showPermissionAlert()
            }
        }
    }
    
    @MainActor
    private func showPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "Screen Recording Permission Required"
        alert.informativeText = "macOS requires you to re-approve Screen Recording access periodically. Please check System Settings if capture fails."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open Settings")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            // Open System Settings -> Privacy -> Screen Recording
             let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!
             NSWorkspace.shared.open(url)
        }
    }
}
