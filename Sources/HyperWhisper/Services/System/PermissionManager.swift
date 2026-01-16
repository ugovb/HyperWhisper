import Foundation
import AVFoundation
import AppKit

@MainActor
class PermissionManager: ObservableObject {
    static let shared = PermissionManager()
    
    @Published var microphoneGranted = false
    @Published var accessibilityGranted = false
    @Published var screenRecordingGranted = false
    
    init() {
        checkPermissions()
    }
    
    func checkPermissions() {
        checkMicrophone()
        checkAccessibility()
        checkScreenRecording()
    }
    
    private func checkMicrophone() {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            microphoneGranted = true
        default:
            microphoneGranted = false
        }
    }
    
    private func checkAccessibility() {
        accessibilityGranted = AXIsProcessTrusted()
    }
    
    private func checkScreenRecording() {
        // CGPreflightScreenCaptureAccess returns true if we can record
        screenRecordingGranted = CGPreflightScreenCaptureAccess()
    }
    
    func requestMicrophone() {
        AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
            Task { @MainActor in
                self?.microphoneGranted = granted
            }
        }
    }
    
    func requestAccessibility() {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        accessibilityGranted = AXIsProcessTrustedWithOptions(options)
        
        // If not immediately granted (which it usually isn't), open settings
        if !accessibilityGranted {
            openSystemSettings(type: .accessibility)
        }
    }
    
    func requestScreenRecording() {
        // CGRequestScreenCaptureAccess() triggers the prompt
        // Returns true if *already* authorized, false if not (but triggers prompt)
        if !CGPreflightScreenCaptureAccess() {
             _ = CGRequestScreenCaptureAccess()
             // It might not update immediately, so we might need to poll or tell user to open settings
             // Usually it opens the prompt.
             
             // Open settings as backup if they denied it previously
             openSystemSettings(type: .screenRcording)
        } else {
            screenRecordingGranted = true
        }
    }
    
    enum PermissionType {
        case accessibility
        case screenRcording
    }
    
    func openSystemSettings(type: PermissionType) {
        // macOS 13+ uses this URL scheme
        let urlString: String
        switch type {
        case .accessibility:
            urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        case .screenRcording:
             urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
        }
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        } else {
            // Fallback: open System Settings directly
            NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/System Settings.app"))
        }
    }
}
