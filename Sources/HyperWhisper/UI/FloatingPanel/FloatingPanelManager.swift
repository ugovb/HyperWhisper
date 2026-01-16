import AppKit
import SwiftUI

/// Manages the floating HUD window.
@MainActor
class FloatingPanelManager: NSObject, NSWindowDelegate {
    var panel: DictationHUDPanel!
    let audioState: AudioState
    
    init(audioState: AudioState) {
        self.audioState = audioState
        super.init()
        createPanel()
    }
    
    private func createPanel() {
        panel = DictationHUDPanel()
        
        // Use HUDView with the shared state
        let hostingView = NSHostingView(rootView: HUDView(audioState: audioState))
        hostingView.sizingOptions = [.minSize, .maxSize, .preferredContentSize]
        hostingView.frame = NSRect(x: 0, y: 0, width: 180, height: 32)
        hostingView.autoresizingMask = [.width, .height]
        
        panel.contentView = hostingView
        
        positionPanelBottomCenter()
    }
    
    private func positionPanelBottomCenter() {
        guard let screen = NSScreen.main else {
            panel.center()
            return
        }
        
        let screenRect = screen.visibleFrame
        let panelWidth = panel.frame.width
        
        let x = screenRect.midX - (panelWidth / 2)
        let y = screenRect.minY + 60 // 60px padding from bottom
        
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
    
    func toggle() {
        if panel.isVisible {
            hide()
        } else {
            show()
        }
    }
    
    func show() {
        print("🪟 [HUD] Showing...")
        positionPanelBottomCenter() // Re-position in case screen changed
        panel.orderFrontRegardless() // Show without activating (stealing focus)
        
        // Double-check we didn't steal focus
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let front = NSWorkspace.shared.frontmostApplication
            print("🪟 [HUD] After show, frontmost: \(front?.localizedName ?? "none")")
        }
    }
    
    func hide() {
        panel.orderOut(nil)
    }
}

class DictationHUDPanel: NSPanel {
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 180, height: 32),
            styleMask: [.nonactivatingPanel, .titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        // Writable properties
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        self.hidesOnDeactivate = false
        self.isOpaque = false
        self.isFloatingPanel = true
        self.backgroundColor = .clear
        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
        self.hasShadow = true
    }
    
    // CRITICAL: Override to prevent becoming key to ensure we don't steal input focus
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
