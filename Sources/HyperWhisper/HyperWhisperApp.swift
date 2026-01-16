import SwiftUI
import AppKit
import SwiftData
import Combine
import AVFoundation

@main
struct HyperWhisperApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    private let appState = AppState.shared
    
    // Setup SwiftData Container
    let container: ModelContainer
    
    init() {
        // Attempt to create ModelContainer. If schema changed/fails, verify and delete old data.
        let schema = Schema([Mode.self, TranscriptionRecord.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        // Helper to get the correct store URL
        func getStoreURL() -> URL {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let bundleId = Bundle.main.bundleIdentifier ?? "HyperWhisper"
            return appSupport.appendingPathComponent(bundleId)
        }
        
        // MIGRATION FIX: Force reset database due to schema change
        let storeDir = getStoreURL()
        let pathsToRemove = [
            storeDir.appending(path: "default.store"),
            storeDir.appending(path: "default.store-shm"),
            storeDir.appending(path: "default.store-wal"),
            URL.applicationSupportDirectory.appending(path: "default.store"),
            URL.applicationSupportDirectory.appending(path: "default.store-shm"),
            URL.applicationSupportDirectory.appending(path: "default.store-wal")
        ]
        
        for path in pathsToRemove {
            try? FileManager.default.removeItem(at: path)
        }
        
        do {
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            // Inject container into AppState immediately
            AppState.shared.setContainer(container)
            // Seed default modes if this is first launch
            DefaultModesSeeder.seedIfNeeded(context: container.mainContext)
        } catch {
            print("CRITICAL: Failed to create ModelContainer: \(error). Attempting reset...")
            
            // Delete ALL SwiftData files in app support
            let storeDir = getStoreURL()
            let paths = [
                storeDir.appending(path: "default.store"),
                storeDir.appending(path: "default.store-shm"),
                storeDir.appending(path: "default.store-wal"),
                URL.applicationSupportDirectory.appending(path: "default.store"),
                URL.applicationSupportDirectory.appending(path: "default.store-shm"),
                URL.applicationSupportDirectory.appending(path: "default.store-wal")
            ]
            
            for path in paths {
                try? FileManager.default.removeItem(at: path)
                print("Deleted: \(path.path)")
            }
             
            do {
                container = try ModelContainer(for: schema, configurations: [modelConfiguration])
                // Inject container into AppState immediately
                AppState.shared.setContainer(container)
                // Seed default modes if this is first launch
                DefaultModesSeeder.seedIfNeeded(context: container.mainContext)
            } catch {
                fatalError("Failed to create container even after reset: \(error)")
            }
        }
    }
    var body: some Scene {
        MenuBarExtra {
            // 1. Actions
            Button("Toggle Recording") {
                Task {
                    if appState.modelContainer == nil { appState.setContainer(container) }
                    appState.toggleRecording()
                }
            }
            
            Button("Transcribe File...") {
                Task {
                    await appState.importFile()
                }
            }
            
            Divider()
            
            // 2. Navigation
            Button("History...") {
                appDelegate.openDashboard(container: container, appState: appState, tab: .history)
            }
            
            Button("Settings...") {
               appDelegate.openDashboard(container: container, appState: appState, tab: .configuration)
            }
            
            Divider()
            
            // 3. Audio Devices
            InputDeviceMenu(appState: appState, appDelegate: appDelegate, container: container)
            
            // 4. Modes
            DynamicModeMenu(appDelegate: appDelegate, container: container)
            
            Divider()
            
            // 5. Quit
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        } label: {
            Image(systemName: appState.isRecording ? "record.circle.fill" : "waveform.circle")
                .symbolRenderingMode(.palette)
                .foregroundStyle(appState.isRecording ? .red : .primary)
        }
        .modelContainer(container)
    }
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var dashboardWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let bundleId = Bundle.main.bundleIdentifier ?? "Unknown"
        print("DEBUG: App Launching with Bundle ID: \(bundleId)")
        print("DEBUG: Accessibility Trusted: \(AXIsProcessTrusted())")
        
        // Check permissions on every launch
        Task {
            await self.checkPermissions()
        }
    }
    
    private func checkPermissions() async {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        if status == .notDetermined {
            print("Microphone permission not determined. Requesting access...")
            let granted = await AVCaptureDevice.requestAccess(for: .audio)
            print("Microphone access request result: \(granted)")
            // Force refresh devices after permission grant
            if granted {
                // We access the shared state to refresh
                // This is a bit of a workaround since appState is private in App, but it's a singleton effectively
                // Actually AppState.shared is accessible
                await AppState.shared.refreshAudioDevices() 
            }
        } else {
            print("Microphone permission status: \(status.rawValue)")
            // Even if authorized, refresh to be sure we have the list
            if status == .authorized {
                await AppState.shared.refreshAudioDevices()
            }
        }
    }
    
    // Updated to accept an optional tab to open specifically
    func openDashboard(container: ModelContainer, appState: AppState, tab: DashboardView.Tab? = nil) {
        // Switch to regular app mode to ensure focus and menu bar presence
        NSApp.setActivationPolicy(.regular)
        
        NSApp.activate(ignoringOtherApps: true)
        
        // If a specific tab is requested and window already exists, close it to recreate with correct tab
        if let existingWindow = dashboardWindow {
            if tab != nil {
                // Close existing window to navigate to new tab
                existingWindow.close()
                self.dashboardWindow = nil
            } else {
                // No specific tab requested, just bring to front
                existingWindow.level = .normal 
                existingWindow.makeKeyAndOrderFront(nil)
                existingWindow.orderFrontRegardless()
                return
            }
        }
        
        let dashboardView = DashboardView(initialTab: tab ?? .home)
            .modelContainer(container)
            .environmentObject(appState)
            .frame(minWidth: 900, minHeight: 600) // Slightly larger for new UI
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 600),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "HyperWhisper Dashboard"
        window.center()
        window.titlebarAppearsTransparent = true // Modern look
        window.styleMask.insert(.fullSizeContentView) // Glass effect preparation
        window.contentView = NSHostingView(rootView: dashboardView)
        window.isReleasedWhenClosed = false
        window.level = .normal
        window.delegate = self // Handle closing
        
        self.dashboardWindow = window
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
    }
    
    func windowWillClose(_ notification: Notification) {
        if let window = notification.object as? NSWindow, window == dashboardWindow {
            self.dashboardWindow = nil
            // Revert to accessory mode (menu bar only)
            NSApp.setActivationPolicy(.accessory)
        }
    }
    
    func openModes() {
        if let container = AppState.shared.modelContainer {
             openDashboard(container: container, appState: AppState.shared, tab: .modes)
        } else {
             print("Error: AppState container is missing for Modes")
        }
    }
}

struct DynamicModeMenu: View {
    @Query(sort: \Mode.name) private var modes: [Mode]
    @State private var settings = SettingsManager.shared
    let appDelegate: AppDelegate
    let container: ModelContainer
    
    var body: some View {
        Menu("Mode") {
            ForEach(modes) { mode in
                Button {
                    settings.activeModeId = mode.id
                } label: {
                    HStack {
                        Text(mode.name)
                        if settings.activeModeId == mode.id {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
            
            Divider()
            
            Button("Manage Modes...") {
                appDelegate.openDashboard(container: container, appState: AppState.shared, tab: .modes)
            }
        }
        .onAppear {
            // Ensure default is selected if none
            if settings.activeModeId == nil, let first = modes.first(where: { $0.isDefault }) {
                settings.activeModeId = first.id
            }
        }
    }
}

struct InputDeviceMenu: View {
    @ObservedObject var appState: AppState
    @ObservedObject var audioState: AudioState
    let appDelegate: AppDelegate
    let container: ModelContainer
    
    init(appState: AppState, appDelegate: AppDelegate, container: ModelContainer) {
        self.appState = appState
        self.audioState = appState.audioState
        self.appDelegate = appDelegate
        self.container = container
    }
    
    var body: some View {
        Menu("Input Device") {
            let devices = audioState.devices
            
            if devices.isEmpty {
                Text("No input devices found").disabled(true)
                Button("Refresh Devices") {
                    Task { await appState.refreshAudioDevices() }
                }
            } else {
                ForEach(devices) { device in
                    Button {
                        Task { await appState.selectInputDevice(id: device.id) }
                    } label: {
                        HStack {
                            Text(device.name)
                            if audioState.selectedDeviceId == device.id {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
            
            Divider()
            
            Button("Sound Settings...") {
                appDelegate.openDashboard(container: container, appState: AppState.shared, tab: .configuration)
            }
        }
    }
}
