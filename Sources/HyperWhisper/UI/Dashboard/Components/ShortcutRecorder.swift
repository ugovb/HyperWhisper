import SwiftUI
import Carbon

struct ShortcutRecorder: View {
    let title: String
    @Binding var key: String
    @Binding var modifiers: SwiftUI.EventModifiers
    
    @State private var isRecording = false
    @State private var monitor: Any?
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Button(action: {
                if isRecording {
                    stopRecording()
                } else {
                    startRecording()
                }
            }) {
                HStack(spacing: 4) {
                    if isRecording {
                        Image(systemName: "recordingtape")
                            .symbolEffect(.pulse)
                        Text("Press keys...")
                    } else {
                        if modifiers.contains(.command) { KeyView(symbol: "⌘") }
                        if modifiers.contains(.shift) { KeyView(symbol: "⇧") }
                        if modifiers.contains(.option) { KeyView(symbol: "⌥") }
                        if modifiers.contains(.control) { KeyView(symbol: "⌃") }
                        KeyView(symbol: key.isEmpty ? "None" : key)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isRecording ? Color.accentColor.opacity(0.1) : Color(nsColor: .controlBackgroundColor))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isRecording ? Color.accentColor : Color.primary.opacity(0.1), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }
    
    private func startRecording() {
        isRecording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // Ignore single modifier presses
            if !isValid(event) { return event }
            
            updateShortcut(from: event)
            stopRecording()
            return nil // Consume event
        }
    }
    
    private func stopRecording() {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
        isRecording = false
    }
    
    private func isValid(_ event: NSEvent) -> Bool {
        // Must implement valid check (e.g. not just cmd, but cmd+something)
        return !event.modifierFlags.intersection([.command, .shift, .option, .control]).isEmpty || event.keyCode < 0x3A // Allow single keys for some
    }
    
    private func updateShortcut(from event: NSEvent) {
        var mods: SwiftUI.EventModifiers = []
        if event.modifierFlags.contains(.command) { mods.insert(.command) }
        if event.modifierFlags.contains(.shift) { mods.insert(.shift) }
        if event.modifierFlags.contains(.option) { mods.insert(.option) }
        if event.modifierFlags.contains(.control) { mods.insert(.control) }
        
        self.modifiers = mods
        self.key = mapKey(event)
    }
    
    private func mapKey(_ event: NSEvent) -> String {
        // Handle special keys vs characters
        if let chars = event.charactersIgnoringModifiers?.uppercased(), !chars.isEmpty {
            return chars
        }
        return "?"
    }
}
