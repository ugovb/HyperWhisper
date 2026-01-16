import AppKit
import Carbon.HIToolbox
import ApplicationServices
import SwiftUI

enum HotkeyOption: String, CaseIterable, Identifiable {
    case fnKey = "fn"
    case rightOption = "rightOption"
    case rightCommand = "rightCommand"
    case hyperKey = "hyperKey"
    case ctrlOptionSpace = "ctrlOptionSpace"
    
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fnKey: return "Fn (hold)"
        case .rightOption: return "Right Option (hold)"
        case .rightCommand: return "Right Command (hold)"
        case .hyperKey: return "Hyper Key (hold) – Ctrl+Opt+Cmd+Shift"
        case .ctrlOptionSpace: return "Ctrl+Option+Space (hold)"
        }
    }

    static var saved: HotkeyOption {
        get {
            if let raw = UserDefaults.standard.string(forKey: "hotkeyOption"),
               let option = HotkeyOption(rawValue: raw) {
                return option
            }
            return .rightOption
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "hotkeyOption")
        }
    }
}

@MainActor
class HotkeyManager: ObservableObject {
    static let shared = HotkeyManager()
    
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var nsEventMonitor: Any?
    
    @Published var isHotkeyActive = false
    @Published var hotkeyOption: HotkeyOption = .saved
    
    // Callbacks
    var onPTTDown: (() -> Void)?
    var onPTTUp: (() -> Void)?
    
    // Keycodes
    private let kVK_RightOption: Int64 = 0x3D // 61
    private let kVK_RightCommand: Int64 = 0x36
    private let kVK_Space: Int64 = 0x31
    
    // Thread-safe mirrors
    private nonisolated(unsafe) var unsafeConfigOption: HotkeyOption = .rightOption
    private nonisolated(unsafe) var unsafeIsActive: Bool = false
    
    private init() {
        start()
    }
    
    func updateOption(_ option: HotkeyOption) {
        if option != self.hotkeyOption {
            self.hotkeyOption = option
            HotkeyOption.saved = option
            stop()
            start()
        }
    }
    
    func start() {
        print("🎹 [HotkeyManager] Starting...")
        requestAccessibility()
        
        let trusted = AXIsProcessTrusted()
        print("   AXIsProcessTrusted: \(trusted)")
        
        guard trusted else {
            print("   ❌ Accessibility not trusted. Tap skipped.")
            return
        }
        
        // Check Input Monitoring by attempting tap creation
        let inputMonitoringAvailable = checkInputMonitoring()
        print("   Input Monitoring available: \(inputMonitoringAvailable)")
        
        // Define mask based on option
        var eventMask = (1 << CGEventType.flagsChanged.rawValue)
        
        if hotkeyOption == .ctrlOptionSpace {
            eventMask |= (1 << CGEventType.keyDown.rawValue)
            eventMask |= (1 << CGEventType.keyUp.rawValue)
        }
        
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { proxy, type, event, refcon in
                guard let refcon = refcon else { return Unmanaged.passRetained(event) }
                let manager = Unmanaged<HotkeyManager>.fromOpaque(refcon).takeUnretainedValue()
                return manager.handleEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            print("   ❌ FAILED to create CGEvent tap!")
            print("   🔧 Falling back to NSEvent monitor...")
            setupNSEventMonitor()
            return
        }
        
        self.eventTap = tap
        self.runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        
        let isEnabled = CGEvent.tapIsEnabled(tap: tap)
        print("   ✅ CGEvent tap STARTED for \(hotkeyOption.rawValue). Enabled: \(isEnabled)")
        
        updateMirrors()
    }
    
    private func checkInputMonitoring() -> Bool {
        let testMask: CGEventMask = 1 << CGEventType.keyDown.rawValue
        if let testTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: testMask,
            callback: { _, _, event, _ in Unmanaged.passRetained(event) },
            userInfo: nil
        ) {
            CFMachPortInvalidate(testTap)
            return true
        }
        return false
    }
    
    private func setupNSEventMonitor() {
        print("   🔄 Setting up NSEvent.addGlobalMonitorForEvents...")
        
        // Monitor flags changed (for Option key)
        nsEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleNSFlagsChanged(event)
        }
        
        if nsEventMonitor != nil {
            print("   ✅ NSEvent monitor installed (Note: cannot distinguish left/right modifiers)")
        } else {
            print("   ❌ NSEvent monitor FAILED to install!")
        }
    }
    
    private func handleNSFlagsChanged(_ event: NSEvent) {
        let flags = event.modifierFlags
        
        // Use Option key (cannot distinguish left/right with NSEvent)
        let optionPressed = flags.contains(.option)
        
        if optionPressed && !unsafeIsActive {
            unsafeIsActive = true
            Task { @MainActor in
                self.isHotkeyActive = true
                print("🎹 [NSEvent] Option DOWN - triggering PTT")
                self.onPTTDown?()
            }
        } else if !optionPressed && unsafeIsActive {
            unsafeIsActive = false
            Task { @MainActor in
                self.isHotkeyActive = false
                print("🎹 [NSEvent] Option UP - stopping PTT")
                self.onPTTUp?()
            }
        }
    }
    
    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            if let source = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
            }
            CFMachPortInvalidate(tap)
            eventTap = nil
            runLoopSource = nil
            print("🎹 [HotkeyManager] CGEvent tap stopped.")
        }
        
        if let monitor = nsEventMonitor {
            NSEvent.removeMonitor(monitor)
            nsEventMonitor = nil
            print("🎹 [HotkeyManager] NSEvent monitor stopped.")
        }
        
        isHotkeyActive = false
        updateMirrors()
    }
    
    nonisolated func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            print("⚠️ [HotkeyManager] Tap was disabled! Re-enabling...")
            Task { @MainActor in self.reenableTap() }
            return Unmanaged.passRetained(event)
        }
        
        let flags = event.flags
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        
        var hotkeyPressed = false
        
        let currentOption = self.unsafeConfigOption
        let currentActive = self.unsafeIsActive
        
        switch currentOption {
        case .fnKey:
            if type == .flagsChanged {
                hotkeyPressed = flags.contains(.maskSecondaryFn)
            }
            
        case .rightOption:
            if type == .flagsChanged {
                hotkeyPressed = flags.contains(.maskAlternate) && keyCode == kVK_RightOption
                if !hotkeyPressed && currentActive && flags.contains(.maskAlternate) {
                    hotkeyPressed = true
                }
            }
            
        case .rightCommand:
            if type == .flagsChanged {
                hotkeyPressed = flags.contains(.maskCommand) && keyCode == kVK_RightCommand
                if !hotkeyPressed && currentActive && flags.contains(.maskCommand) {
                    hotkeyPressed = true
                }
            }
            
        case .hyperKey:
             if type == .flagsChanged {
                let hyperFlags: CGEventFlags = [.maskControl, .maskAlternate, .maskCommand, .maskShift]
                hotkeyPressed = flags.contains(hyperFlags)
             }
             
        case .ctrlOptionSpace:
             let hasCtrlOption = flags.contains(.maskControl) && flags.contains(.maskAlternate)
             
             if type == .keyDown && keyCode == kVK_Space && hasCtrlOption {
                 hotkeyPressed = true
             } else if type == .keyUp && keyCode == kVK_Space && currentActive {
                 hotkeyPressed = false
             } else if currentActive && hasCtrlOption {
                 hotkeyPressed = true
             }
        }
        
        // State Transitions
        if hotkeyPressed && !currentActive {
            self.unsafeIsActive = true
            Task { @MainActor in
                self.isHotkeyActive = true
                print("🎹 [CGEvent] Hotkey DOWN - triggering PTT")
                self.onPTTDown?()
            }
        } else if !hotkeyPressed && currentActive {
            self.unsafeIsActive = false
             Task { @MainActor in
                self.isHotkeyActive = false
                print("🎹 [CGEvent] Hotkey UP - stopping PTT")
                self.onPTTUp?()
            }
        }
        
        return Unmanaged.passRetained(event)
    }
    
    private func updateMirrors() {
        unsafeConfigOption = hotkeyOption
        unsafeIsActive = isHotkeyActive
    }
    
    func reenableTap() {
         if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: true)
            print("🎹 [HotkeyManager] Tap re-enabled.")
         }
    }
    
    func requestAccessibility() {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }
}
