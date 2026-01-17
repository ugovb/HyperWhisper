import SwiftUI
import AppKit

struct ConfigurationView: View {
    @EnvironmentObject var appState: AppState
    @State private var settings = SettingsManager.shared
    
    @StateObject private var launchManager = LaunchAtLoginManager.shared
    @StateObject private var permissions = PermissionManager.shared
    @StateObject private var modelDownloader = ModelDownloader()
    
    // Shortcuts Storage
    @AppStorage("toggleRecKey") private var toggleRecKey = "Right" // Default: Right Arrow
    @AppStorage("toggleRecMods") private var toggleRecModsRaw = 524288 // Default: Option
    
    @AppStorage("pttRecKey") private var pttRecKey = ""
    @AppStorage("pttRecMods") private var pttRecModsRaw = 0
    
    @AppStorage("cancelRecKey") private var cancelRecKey = "Esc"
    @AppStorage("cancelRecMods") private var cancelRecModsRaw = 0
    
    @AppStorage("changeModeKey") private var changeModeKey = "K"
    @AppStorage("changeModeMods") private var changeModeModsRaw = 1572864
    
    
    @State private var windowStyle: WindowStylePicker.WindowStyle = .mini
    @State private var alwaysShowWindow = false
    
    // New Logic
    @ObservedObject private var hotkeyManager = HotkeyManager.shared
    
    @State private var isRecordingToggle = false
    @State private var isRecordingPTT = false
    
    // Volume Control
    @State private var inputVolume: Float = 0.5
    @State private var inputVolumeCheckTimer: Timer?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HyperSpacing.xl) {
                // MARK: - Permissions
                GlassCard(padding: HyperSpacing.lg) {
                    VStack(alignment: .leading, spacing: HyperSpacing.md) {
                        Text("Permissions")
                             .font(.hyperUI(.headline, weight: .semibold))
                        
                        Divider()
                        
                        // Accessibility
                        HStack {
                            Image(systemName: permissions.accessibilityGranted ? "checkmark.shield.fill" : "exclamationmark.shield")
                                .font(.system(size: 20))
                                .foregroundStyle(permissions.accessibilityGranted ? .green : .orange)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Accessibility")
                                    .font(.hyperUI(.body, weight: .medium))
                                if !permissions.accessibilityGranted {
                                    Text("Required for text injection.")
                                        .font(.hyperUI(.caption))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            if !permissions.accessibilityGranted {
                                Button("Authorize") { permissions.requestAccessibility() }
                                    .buttonStyle(.bordered)
                            }
                        }
                        
                        Divider()
                        
                        // Microphone
                        HStack {
                            Image(systemName: permissions.microphoneGranted ? "checkmark.shield.fill" : "exclamationmark.shield")
                                .font(.system(size: 20))
                                .foregroundStyle(permissions.microphoneGranted ? .green : .orange)
                                
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Microphone")
                                    .font(.hyperUI(.body, weight: .medium))
                            }
                            Spacer()
                            if !permissions.microphoneGranted {
                                Button("Authorize") { permissions.requestMicrophone() }
                                    .buttonStyle(.bordered)
                            }
                        }
                    }
                }
                
                // MARK: - AI Model
                GlassCard(padding: HyperSpacing.lg) {
                    VStack(alignment: .leading, spacing: HyperSpacing.md) {
                        Text("AI Model")
                            .font(.hyperUI(.headline, weight: .semibold))
                        
                        HStack {
                            Image(systemName: modelDownloader.isModelReady ? "checkmark.circle.fill" : "arrow.down.circle")
                                .font(.system(size: 20))
                                .foregroundStyle(modelDownloader.isModelReady ? .green : .blue)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Parakeet TDT 0.6b")
                                    .font(.hyperUI(.body, weight: .medium))
                                Text(modelDownloader.isModelReady ? "Installed locally" : "~490MB, runs offline")
                                    .font(.hyperUI(.caption))
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            if modelDownloader.isDownloading {
                                HStack(spacing: 8) {
                                    ProgressView(value: modelDownloader.downloadProgress)
                                        .frame(width: 100)
                                    Text("\(Int(modelDownloader.downloadProgress * 100))%")
                                        .font(.hyperUI(.caption))
                                        .foregroundStyle(.secondary)
                                        .frame(width: 35, alignment: .trailing)
                                }
                            } else if modelDownloader.isModelReady {
                                Text("Ready")
                                    .font(.hyperUI(.caption))
                                    .foregroundStyle(.green)
                            } else {
                                Button("Download") {
                                    Task { await modelDownloader.downloadModel(type: .parakeet) }
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                        
                        if let error = modelDownloader.lastError {
                            Text(error)
                                .font(.hyperUI(.caption))
                                .foregroundStyle(.red)
                        }
                    }
                }
                
                // MARK: - Audio Settings
                GlassCard(padding: HyperSpacing.lg) {
                    VStack(alignment: .leading, spacing: HyperSpacing.md) {
                        Text("Audio Configuration")
                            .font(.hyperUI(.headline, weight: .semibold))
                        
                        // Input Device
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Input Device")
                                .font(.hyperUI(.caption))
                                .foregroundStyle(.secondary)
                            
                            DevicePicker(
                                devices: appState.audioState.devices,
                                selectedDeviceId: Binding(
                                    get: { appState.audioState.selectedDeviceId },
                                    set: { id in Task { await appState.selectInputDevice(id: id) } }
                                )
                            ) { id in
                                Task { await appState.selectInputDevice(id: id) }
                            }
                        }
                        
                        Divider()
                        
                        // Volume
                        HStack {
                            Image(systemName: "speaker.wave.2.fill")
                                .foregroundStyle(.secondary)
                            
                            Slider(value: $inputVolume, in: 0...1) {
                                Text("Input Volume")
                            } minimumValueLabel: {
                                Image(systemName: "speaker.fill").font(.caption)
                            } maximumValueLabel: {
                                Image(systemName: "speaker.wave.3.fill").font(.caption)
                            }
                            .onChange(of: inputVolume) { _, newValue in
                                Task { await appState.setInputVolume(newValue) }
                            }
                        }
                    }
                }
                
                // MARK: - Audio Processing
                GlassCard(padding: HyperSpacing.lg) {
                    VStack(alignment: .leading, spacing: HyperSpacing.md) {
                         Text("Processing & Effects")
                            .font(.hyperUI(.headline, weight: .semibold))
                            
                        Toggle(isOn: Binding(get: { settings.autoGain }, set: { settings.autoGain = $0 })) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Automatic Gain Control")
                                    .font(.hyperUI(.body, weight: .medium))
                                Text("Adjust volume automatically")
                                    .font(.hyperUI(.caption))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .toggleStyle(.switch)
                        
                        Toggle(isOn: Binding(get: { settings.silenceRemoval }, set: { settings.silenceRemoval = $0 })) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Silence Removal")
                                    .font(.hyperUI(.body, weight: .medium))
                                Text("Trim silent sections")
                                    .font(.hyperUI(.caption))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .toggleStyle(.switch)
                        
                        /* Toggle(isOn: Binding(get: { settings.soundEffects }, set: { settings.soundEffects = $0 })) { // Assuming soundEffects in settings or local
                             // User asked for contents of sound menu. 
                             // SoundSettingsView had a local state for 'soundEffects'. 
                             // If it's not in SettingsManager, I should check. 
                             // Based on SoundSettingsView line 26: @State private var soundEffects = true. 
                             // It seems it wasn't persisted? 
                             // I'll skip it or add it if important. User said "contents of menu".
                             // I'll add a dummy toggle or link to real setting if I find it.
                        } */
                    }
                }
                
                // MARK: - Keyboard Shortcuts
                GlassCard(padding: HyperSpacing.lg) {
                    VStack(alignment: .leading, spacing: HyperSpacing.md) {
                        Text("Keyboard Shortcuts")
                            .font(.hyperUI(.headline, weight: .semibold))
                        
                        Picker("Recording Hotkey", selection: $hotkeyManager.hotkeyOption) {
                            ForEach(HotkeyOption.allCases) { option in
                                Text(option.displayName).tag(option)
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: hotkeyManager.hotkeyOption) { _, newValue in
                            hotkeyManager.updateOption(newValue)
                        }
                        
                        Text("Hold the selected key to record. Release to stop and transcribe.")
                            .font(.hyperUI(.caption))
                            .foregroundStyle(.secondary)
                    }
                }
                
                // MARK: - Application
                GlassCard(padding: HyperSpacing.lg) {
                    VStack(alignment: .leading, spacing: HyperSpacing.md) {
                        Text("Application")
                            .font(.hyperUI(.headline, weight: .semibold))
                        
                        Toggle(isOn: $launchManager.isEnabled) {
                            Text("Launch at login")
                        }
                        .toggleStyle(.switch)
                    }
                }
            }
            .padding(HyperSpacing.xl)
        }
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.5))
        .onAppear {
            permissions.checkPermissions() 
            Task {
                 let vol = await appState.getInputVolume()
                 inputVolume = vol
            }
        }
    }
}

// MARK: - Recorder Logic

struct RecorderButton: View {
    @Binding var isRecording: Bool
    let currentKey: String
    let currentMods: Int
    let onRecord: (UInt16, NSEvent.ModifierFlags) -> Void
    
    var body: some View {
        Button(action: { isRecording = true }) {
            if isRecording {
                Text("Press Keys...")
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(6)
            } else {
                if currentKey.isEmpty {
                     Text("Not Set")
                        .font(.hyperUI(.caption))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial)
                        .cornerRadius(6)
                } else {
                    HStack(spacing: 4) {
                        KeyView_Modifiers(modifiers: NSEvent.ModifierFlags(rawValue: UInt(currentMods)))
                        KeyView(symbol: currentKey)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .modifier(RecorderModifier(isRecording: $isRecording, onRecord: onRecord))
    }
}

struct RecorderModifier: ViewModifier {
    @Binding var isRecording: Bool
    let onRecord: (UInt16, NSEvent.ModifierFlags) -> Void
    
    @State private var monitor: Any?
    
    func body(content: Content) -> some View {
        content
            .background(WindowAccessor { _ in })
            .onChange(of: isRecording) { _, newValue in
                if newValue { startCapture() } else { stopCapture() }
            }
    }
    
    func startCapture() {
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // Stop on Escape
            if event.keyCode == 53 {
                isRecording = false
                return nil
            }
            
            onRecord(event.keyCode, event.modifierFlags)
            isRecording = false
            return nil
        }
    }
    
    func stopCapture() {
        if let m = monitor { NSEvent.removeMonitor(m); monitor = nil }
    }
}

// MARK: - Subviews & Helpers

struct ShortcutRow: View {
    let title: String
    let shortcut: String
    let modifiers: SwiftUI.EventModifiers
    
    var body: some View {
        HStack {
            Text(title)
                .font(.hyperUI(.body, weight: .medium))
            Spacer()
            HStack(spacing: HyperSpacing.xs) {
                if modifiers.contains(.command) { KeyView(symbol: "⌘") }
                if modifiers.contains(.shift) { KeyView(symbol: "⇧") }
                if modifiers.contains(.option) { KeyView(symbol: "⌥") }
                if modifiers.contains(.control) { KeyView(symbol: "⌃") }
                KeyView(symbol: shortcut)
            }
        }
    }
}

struct KeyView: View {
    let symbol: String
    
    var body: some View {
        Text(symbol)
            .font(.hyperData(11, weight: .bold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, HyperSpacing.sm)
            .padding(.vertical, HyperSpacing.xs)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: HyperRadius.sm))
            .overlay(
                RoundedRectangle(cornerRadius: HyperRadius.sm)
                    .stroke(Color.glassBorder, lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.15), radius: 1, y: 1)
    }
}

struct KeyView_Modifiers: View {
     let modifiers: NSEvent.ModifierFlags
     var body: some View {
         HStack(spacing: 2) {
             if modifiers.contains(.command) { KeyView(symbol: "⌘") }
             if modifiers.contains(.shift) { KeyView(symbol: "⇧") }
             if modifiers.contains(.option) { KeyView(symbol: "⌥") }
             if modifiers.contains(.control) { KeyView(symbol: "⌃") }
         }
     }
}

// MARK: - Extensions

extension ConfigurationView {
    // Note: isModelInstalled removed as user requested
    
    func keyCodeToString(_ code: Int) -> String {
        switch code {
        case 49: return "Space"
        case 123: return "Left"
        case 124: return "Right"
        case 126: return "Up"
        case 125: return "Down"
        case 36: return "Return"
        case 53: return "Esc"
        default: return UnicodeScalar(code)?.description.uppercased() ?? "?"
        }
    }
}

struct WindowAccessor: NSViewRepresentable {
    var callback: (NSWindow?) -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { self.callback(view.window) }
        return view
    }
    func updateNSView(_ nsView: NSView, context: Context) {}
}
