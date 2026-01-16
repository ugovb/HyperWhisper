import AppKit
import ApplicationServices
import Carbon

public enum InjectionError: Error {
    case permissionDenied
    case applicationNotFound
    case injectionFailed
}

/// Service responsible for injecting text into external applications.
public actor TextInjectionService {
    
    private var lastActiveApplication: NSRunningApplication?
    private var capturedAppPID: pid_t = 0
    
    public init() {}
    
    /// Capture the currently active application. Call this *before* showing the HUD.
    public func captureActiveApplication() {
        let frontmost = NSWorkspace.shared.frontmostApplication
        let ownBundleID = Bundle.main.bundleIdentifier ?? "unknown"
        
        // Don't capture ourselves
        if frontmost?.bundleIdentifier == ownBundleID {
            print("📱 [TextInjection] Frontmost is us, keeping previous: \(lastActiveApplication?.localizedName ?? "None")")
            return
        }
        
        lastActiveApplication = frontmost
        if let app = lastActiveApplication {
            capturedAppPID = app.processIdentifier
            print("📱 [TextInjection] Captured: \(app.localizedName ?? "unknown") (PID: \(capturedAppPID), Bundle: \(app.bundleIdentifier ?? "none"))")
        } else {
            print("📱 [TextInjection] ⚠️ No app captured!")
        }
    }
    
    public func getActiveAppName() -> String? {
        return lastActiveApplication?.localizedName
    }
    
    /// Checks if the app has accessibility permissions.
    public func isAccessibilityTrusted() -> Bool {
        return AXIsProcessTrusted()
    }
    
    /// Attempts to inject text into the previously active application using a tiered strategy.
    public func inject(text: String) async throws {
        print("📝 [TextInjection] Starting injection...")
        print("   Text length: \(text.count) chars")
        print("   Target app: \(lastActiveApplication?.localizedName ?? "none")")
        
        guard isAccessibilityTrusted() else {
            print("   ❌ Permission Denied")
            throw InjectionError.permissionDenied
        }
        
        guard let app = lastActiveApplication else {
            print("   ❌ No active application to inject into.")
            throw InjectionError.applicationNotFound
        }
        
        // Step 1: Activate the target app
        print("   Step 1: Activating target app...")
        let activated = await activateApp(app)
        print("   Activation result: \(activated)")
        
        // Step 2: Wait for focus
        print("   Step 2: Waiting for focus (400ms)...")
        try await Task.sleep(nanoseconds: 400_000_000)
        
        // Verify we activated the right app
        let currentFront = NSWorkspace.shared.frontmostApplication
        print("   Current frontmost: \(currentFront?.localizedName ?? "none") (PID: \(currentFront?.processIdentifier ?? 0))")
        
        if currentFront?.processIdentifier != capturedAppPID {
            print("   ⚠️ Focus might not be on target app!")
        }
        
        // Step 3: Try Accessibility-based insertion
        print("   Step 3: Trying AX insertion...")
        if await attemptAXInjection(text: text, pid: capturedAppPID) {
            print("   ✅ AX insertion succeeded!")
            return
        }
        print("   AX insertion failed, trying paste fallback...")
        
        // Step 4: Fallback to paste
        print("   Step 4: Trying paste fallback...")
        if await attemptPasteInjection(text: text) {
            print("   ✅ Paste succeeded!")
            return
        }
        
        print("   ❌ All injection methods failed!")
        throw InjectionError.injectionFailed
    }
    
    // MARK: - Activate App
    
    private func activateApp(_ app: NSRunningApplication) async -> Bool {
        // Method 1: Standard activation
        var success = app.activate(options: [.activateIgnoringOtherApps])
        print("      Standard activate: \(success)")
        
        if !success {
            // Method 2: Try unhiding first
            if app.isHidden {
                app.unhide()
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
            success = app.activate(options: [.activateIgnoringOtherApps, .activateAllWindows])
            print("      Retry with activateAllWindows: \(success)")
        }
        
        // Method 3: AppleScript fallback
        if !success, let bundleID = app.bundleIdentifier {
            print("      Trying AppleScript activation...")
            success = activateViaAppleScript(bundleID: bundleID)
            print("      AppleScript activate: \(success)")
        }
        
        return success
    }
    
    private func activateViaAppleScript(bundleID: String) -> Bool {
        let script = """
        tell application id "\(bundleID)"
            activate
        end tell
        """
        
        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            appleScript.executeAndReturnError(&error)
            if let error = error {
                print("      AppleScript error: \(error)")
                return false
            }
            return true
        }
        return false
    }
    
    // MARK: - Level 1: AXValue Injection
    
    private func attemptAXInjection(text: String, pid: pid_t) async -> Bool {
        print("      AX: Getting focused element for PID \(pid)...")
        
        // Use nonisolated function to perform AX operations synchronously
        // and avoid memory management issues with CFTypeRef bridging
        return await performAXInjection(text: text, pid: pid)
    }
    
    private func performAXInjection(text: String, pid: pid_t) async -> Bool {
        // Create app element (this is a Create function, so we own it)
        let appElement = AXUIElementCreateApplication(pid)
        
        // Get focused element
        var focusedElementRef: CFTypeRef?
        let focusResult = AXUIElementCopyAttributeValue(appElement, kAXFocusedUIElementAttribute as CFString, &focusedElementRef)
        print("      AX: Focus result: \(axErrorDescription(focusResult))")
        
        guard focusResult == .success, 
              let elementRef = focusedElementRef else {
            print("      AX: Could not get focused element")
            return false
        }
        
        // Safely cast to AXUIElement
        guard CFGetTypeID(elementRef) == AXUIElementGetTypeID() else {
            print("      AX: Focused element is not an AXUIElement")
            return false
        }
        let axElement = elementRef as! AXUIElement
        
        // Check element role
        var roleRef: CFTypeRef?
        AXUIElementCopyAttributeValue(axElement, kAXRoleAttribute as CFString, &roleRef)
        let roleString = roleRef as? String ?? "unknown"
        print("      AX: Element role: \(roleString)")
        
        // Check if we can set value
        var settable: DarwinBoolean = false
        let settableResult = AXUIElementIsAttributeSettable(axElement, kAXValueAttribute as CFString, &settable)
        print("      AX: Value settable: \(settable.boolValue) (result: \(axErrorDescription(settableResult)))")
        
        if settable.boolValue {
            // Get current value
            var currentValueRef: CFTypeRef?
            AXUIElementCopyAttributeValue(axElement, kAXValueAttribute as CFString, &currentValueRef)
            let currentText = (currentValueRef as? String) ?? ""
            print("      AX: Current text length: \(currentText.count)")
            
            // Get selection range
            var selectedRangeRef: CFTypeRef?
            AXUIElementCopyAttributeValue(axElement, kAXSelectedTextRangeAttribute as CFString, &selectedRangeRef)
            
            var insertionPoint = currentText.count
            if let rangeValue = selectedRangeRef,
               CFGetTypeID(rangeValue) == AXValueGetTypeID() {
                var range = CFRange()
                if AXValueGetValue(rangeValue as! AXValue, .cfRange, &range) {
                    insertionPoint = range.location
                    print("      AX: Selection at: \(range.location), length: \(range.length)")
                }
            }
            
            // Build new text as a Swift String first, then convert to CFString
            let newTextString = String(currentText.prefix(insertionPoint)) + text + String(currentText.dropFirst(insertionPoint))
            let setResult = AXUIElementSetAttributeValue(axElement, kAXValueAttribute as CFString, newTextString as CFString)
            print("      AX: Set value result: \(axErrorDescription(setResult))")
            
            if setResult == .success {
                return true
            }
        }
        
        // Method 2: Try setting selected text
        var selectedTextSettable: DarwinBoolean = false
        AXUIElementIsAttributeSettable(axElement, kAXSelectedTextAttribute as CFString, &selectedTextSettable)
        
        if selectedTextSettable.boolValue {
            let setResult = AXUIElementSetAttributeValue(axElement, kAXSelectedTextAttribute as CFString, text as CFString)
            print("      AX: Set selected text result: \(axErrorDescription(setResult))")
            return setResult == .success
        }
        
        return false
    }
    
    private func axErrorDescription(_ error: AXError) -> String {
        switch error {
        case .success: return "success"
        case .failure: return "failure"
        case .illegalArgument: return "illegalArgument"
        case .invalidUIElement: return "invalidUIElement"
        case .invalidUIElementObserver: return "invalidUIElementObserver"
        case .cannotComplete: return "cannotComplete"
        case .attributeUnsupported: return "attributeUnsupported"
        case .actionUnsupported: return "actionUnsupported"
        case .notificationUnsupported: return "notificationUnsupported"
        case .notImplemented: return "notImplemented"
        case .notificationAlreadyRegistered: return "notificationAlreadyRegistered"
        case .notificationNotRegistered: return "notificationNotRegistered"
        case .apiDisabled: return "apiDisabled"
        case .noValue: return "noValue"
        case .parameterizedAttributeUnsupported: return "parameterizedAttributeUnsupported"
        case .notEnoughPrecision: return "notEnoughPrecision"
        @unknown default: return "unknown(\(error.rawValue))"
        }
    }
    
    // MARK: - Level 3: Pasteboard Injection
    
    private func attemptPasteInjection(text: String) async -> Bool {
        print("      Paste: Saving clipboard...")
        
        let pasteboard = NSPasteboard.general
        let oldContents = pasteboard.string(forType: .string)
        
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        print("      Paste: Text set to clipboard")
        
        // Wait a moment
        try? await Task.sleep(nanoseconds: 50_000_000)
        
        // Send Cmd+V
        print("      Paste: Sending Cmd+V...")
        let success = sendPasteKeystroke()
        print("      Paste: Keystroke sent: \(success)")
        
        // Wait for paste to complete
        try? await Task.sleep(nanoseconds: 200_000_000)
        
        // Restore clipboard
        if let old = oldContents {
            pasteboard.clearContents()
            pasteboard.setString(old, forType: .string)
            print("      Paste: Clipboard restored")
        }
        
        return success
    }
    
    private func sendPasteKeystroke() -> Bool {
        let vKeyCode: CGKeyCode = 9
        let source = CGEventSource(stateID: .hidSystemState) // Use HID system state for reliable event recognition
        
        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true) else {
            print("      ❌ Failed to create keyDown event")
            return false
        }
        keyDown.flags = .maskCommand
        
        guard let keyUp = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false) else {
            print("      ❌ Failed to create keyUp event")
            return false
        }
        keyUp.flags = .maskCommand
        
        keyDown.post(tap: .cgAnnotatedSessionEventTap)
        keyUp.post(tap: .cgAnnotatedSessionEventTap)
        
        return true
    }
}
