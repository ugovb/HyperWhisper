import SwiftUI
import Combine
import AVFoundation
import SwiftData
import FluidAudio

/// Single Source of Truth for the application.
/// Wires Audio -> AI -> UI.
@MainActor
class AppState: ObservableObject {
    static let shared = AppState()
    
    // MARK: - Core Services
    let audioMixer: AudioMixer
    let parakeetEngine: ParakeetEngine
    let hotkeyManager: HotkeyManager
    let textInjector: TextInjectionService
    var panelManager: FloatingPanelManager?
    
    // MARK: - Published State (UI Drivers)
    @Published var currentTranscript: [TranscriptionSegment] = []
    @Published var detectedLanguage: String = "auto"
    @Published var isModelReady: Bool = false
    @Published var isRecording: Bool = false
    @Published var audioLevel: Float = 0.0
    
    // audioState is used by legacy UI components
    @Published var audioState: AudioState = AudioState()
    
    // captureMode mirror
    @Published var captureMode: AudioMixer.CaptureMode = .microphoneOnly {
        didSet {
            audioMixer.setMode(captureMode)
        }
    }
    
    // MARK: - Data Streams
    /// Subject to pass audio buffers to Visualizer (High Frequency)
    let audioBufferSubject = PassthroughSubject<AVAudioPCMBuffer, Never>()
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Persistence
    var modelContainer: ModelContainer?
    
    init() {
        self.audioMixer = AudioMixer()
        self.parakeetEngine = ParakeetEngine()
        self.hotkeyManager = HotkeyManager.shared
        self.textInjector = TextInjectionService()
        
        setupPipeline()
        setupNotifications()
        setupHotkeys()
        
        self.panelManager = FloatingPanelManager(audioState: self.audioState)
        
        // Cleanup old history on startup
        Task {
            await cleanupOldRecords()
        }
    }
    
    private func setupHotkeys() {
        hotkeyManager.onPTTDown = { [weak self] in
            self?.startCapture()
        }
        
        hotkeyManager.onPTTUp = { [weak self] in
            self?.stopCapture()
        }
    }
    
    private func setupPipeline() {
        audioMixer.onMixedAudio = { [weak self] samples in
            // Visualizer update handled by audioLevel notification
        }
        
        audioMixer.$currentMode
            .receive(on: RunLoop.main)
            .assign(to: \.captureMode, on: self)
            .store(in: &cancellables)
    }
    
    private func setupNotifications() {
        NotificationCenter.default.publisher(for: .audioAmplitudeUpdate)
            .receive(on: RunLoop.main)
            .sink { [weak self] notification in
                if let amplitude = notification.userInfo?["amplitude"] as? Float {
                    self?.audioLevel = amplitude
                    self?.audioState.amplitude = amplitude
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Actions
    
    func startCapture() {
        guard !isRecording else { return }
        
        Task {
            // Capture the frontmost app BEFORE we show our UI
            await textInjector.captureActiveApplication()
            
            do {
                // Ensure Engine is loaded
                try await parakeetEngine.initialize()
                isModelReady = true
                
                // Show HUD
                panelManager?.show()
                
                // Start Recording to File
                _ = try await audioMixer.startRecordingToFile()
                
                isRecording = true
                audioState.isRecording = true
                audioState.status = .recording
                
                // Clear previous
                currentTranscript = []
                audioState.transcript = ""
                
                print("AppState: Capture started (File Mode).")
            } catch {
                print("AppState: Failed to start capture: \(error)")
                audioState.status = .error
            }
        }
    }
    
    func stopCapture() {
        guard isRecording else { return }
        
        // Hide HUD immediately
        panelManager?.hide()
        
        Task {
            guard let url = await audioMixer.stopRecordingToFile() else {
                isRecording = false
                audioState.isRecording = false
                return
            }
            
            isRecording = false
            audioState.isRecording = false
            audioState.status = .processing
            print("AppState: Capture stopped. Processing...")
            
            // Transcribe
            do {
                let text = try await parakeetEngine.transcribe(url: url)
                await handleTranscriptionSuccess(text: text)
            } catch {
                print("AppState: Transcription/Injection failed: \(error)")
                audioState.status = .error
            }
            
            // Cleanup
            try? FileManager.default.removeItem(at: url)
        }
    }
    
    private func handleTranscriptionSuccess(text: String) async {
        // 0. Sanitize Text (Remove Hallucinations)
        let sanitizedText = sanitizeTranscription(text)
        
        // If sanitization resulted in empty text (it was all hallucinations), abort
        if sanitizedText.isEmpty && !text.isEmpty {
            print("AppState: Transcription was filtered out as hallucination.")
            self.audioState.status = .finished
            return
        }
        
        // Update UI state (for History view etc)
        self.audioState.transcript = sanitizedText
        self.audioState.status = .processing
        
        // 1. Get active mode and process through LLM if needed
        var processedText = sanitizedText
        var activeMode: Mode? = nil
        
        if let modeId = SettingsManager.shared.activeModeId,
           let container = modelContainer {
            // Fetch the active mode from SwiftData
            let context = container.mainContext
            let descriptor = FetchDescriptor<Mode>(predicate: #Predicate { $0.id == modeId })
            if let mode = try? context.fetch(descriptor).first {
                activeMode = mode
                
                // Process through LLM (unless classic/none)
                if mode.type != .classic && mode.providerType != .none {
                    do {
                        print("AppState: Processing with LLM (\(mode.providerType.rawValue) / \(mode.modelIdentifier))...")
                        processedText = try await LLMService.shared.process(text: sanitizedText, mode: mode)
                        print("AppState: LLM processing complete.")
                    } catch {
                        print("AppState: LLM processing failed: \(error). Using raw text.")
                        // Fall back to raw text on error
                    }
                }
            }
        }
        
        self.audioState.status = .finished
        
        // 2. Copy to Clipboard
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(processedText, forType: .string)
        
        // 3. Save to History
        await saveTranscription(rawText: sanitizedText, processedText: processedText, mode: activeMode)
        
        // 4. Inject into target app
        try? await textInjector.inject(text: processedText)
        
        print("AppState: Transcription complete and processed: \(processedText)")
        
        // Panel already hidden
    }
    
    /// Filters out common hallucinations from Whisper/Parakeet models
    private func sanitizeTranscription(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Exact matches for common hallucinations
        let hallucinations = [
            "Thank you.",
            "Thanks.",
            "MBC 2024",
            "Amara.org",
            "Subtitles by",
            "Translated by",
            "Ubiqus",
            "Psst",
            "Pst"
        ]
        
        if hallucinations.contains(where: { trimmed.caseInsensitiveCompare($0) == .orderedSame }) {
            return ""
        }
        
        // Regex for "Message [Name] on WhatsApp"
        // Patterns: "Message ... on WhatsApp", "WhatsApp message", etc.
        let whatsappPattern = #"^Message .*? on WhatsApp$"#
        if trimmed.range(of: whatsappPattern, options: [.regularExpression, .caseInsensitive]) != nil {
            return ""
        }
        
        return trimmed
    }
    
    // MARK: - History Management
    
    private func saveTranscription(rawText: String, processedText: String, mode: Mode?) async {
        guard let container = modelContainer else {
            print("AppState: Error - modelContainer is nil. Cannot save history.")
            return
        }
        
        print("AppState: Saving transcription to history...")
        let record = TranscriptionRecord(
            rawText: rawText,
            processedText: processedText,
            modeId: mode?.id ?? UUID(),
            modeName: mode?.name ?? "Raw Dictation"
        )
        
        let context = container.mainContext
        context.insert(record)
        try? context.save()
        print("AppState: Saved to history.")
    }
    
    private func cleanupOldRecords() async {
        guard let container = modelContainer else { return }
        
        let cutoffDate = Date().addingTimeInterval(-86400) // 24 hours ago
        let context = container.mainContext
        
        do {
            // SwiftData batch delete or fetch-then-delete
            let descriptor = FetchDescriptor<TranscriptionRecord>(
                predicate: #Predicate { $0.createdAt < cutoffDate }
            )
            let oldRecords = try context.fetch(descriptor)
            
            if !oldRecords.isEmpty {
                print("AppState: Deleting \(oldRecords.count) old records.")
                for record in oldRecords {
                    context.delete(record)
                }
                try context.save()
            }
        } catch {
            print("AppState: Failed to cleanup old records: \(error)")
        }
    }
    
    func toggleRecording() {
        if isRecording {
            stopCapture()
        }
        else {
            startCapture()
        }
    }
    
    // MARK: - Audio Control Methods
    
    func getInputVolume() async -> Float {
        return await audioMixer.getInputVolume()
    }
    
    func setInputVolume(_ volume: Float) async {
        await audioMixer.setInputVolume(volume)
        audioState.inputGain = volume
    }
    
    func startMonitoringAudio() async {
        try? await audioMixer.startMonitoring()
    }
    
    func stopMonitoringAudio() async {
        await audioMixer.stopMonitoring()
    }
    
    func selectInputDevice(id: String) async {
        try? await audioMixer.setInputDevice(id: id)
        audioState.selectedDeviceId = id
    }
    
    func refreshAudioDevices() async {
        print("AppState: Refreshing audio devices...")
        let devices = await audioMixer.refreshDevices()
        self.audioState.devices = devices.map { AudioState.InputDevice(id: $0.id, name: $0.name) }
        
        // Ensure selection is valid
        let currentSelection = audioState.selectedDeviceId
        let exists = self.audioState.devices.contains(where: { $0.id == currentSelection })
        
        if !exists {
             // Reset if selected device is gone, prefer default
             self.audioState.selectedDeviceId = self.audioState.devices.first?.id ?? "default"
        }
    }
    
    func setContainer(_ container: ModelContainer) {
        self.modelContainer = container
    }
    
    func importFile() async {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.audio]
        
        guard panel.runModal() == .OK, let url = panel.url else { return }
        
        Task {
            do {
                print("AppState: Importing file: \(url.lastPathComponent)")
                
                
                var finalText = ""
                
                // 1. Check for Gemini (Priority for Files)
                if let key = SettingsManager.shared.geminiKey, !key.isEmpty {
                     // Override active mode, but use its prompt if available
                     var systemPrompt = "You are a helpful assistant."
                     if let modeId = SettingsManager.shared.activeModeId,
                        let container = modelContainer,
                        let mode = try? container.mainContext.fetch(FetchDescriptor<Mode>(predicate: #Predicate { $0.id == modeId })).first {
                         systemPrompt = mode.systemPrompt
                     }
                     
                     print("AppState: Utilizing Gemini Audio API for direct transcription.")
                     let geminiProvider = GeminiProvider(apiKey: key, modelName: "gemini-3-flash-preview")
                     
                     do {
                         // Send AUDIO directly to Gemini
                         finalText = try await geminiProvider.transcribeAudio(url: url, systemPrompt: systemPrompt)
                     } catch {
                         print("Gemini Audio Transcription failed: \(error). Falling back to Parakeet.")
                         // Fallback flow
                         try await parakeetEngine.initialize()
                         let rawText = try await parakeetEngine.transcribe(url: url)
                         
                         if let modeId = SettingsManager.shared.activeModeId,
                            let container = modelContainer,
                            let mode = try? container.mainContext.fetch(FetchDescriptor<Mode>(predicate: #Predicate { $0.id == modeId })).first {
                             finalText = try await LLMService.shared.process(text: rawText, mode: mode)
                         } else {
                             finalText = rawText
                         }
                     }
                } else {
                    // Standard Parakeet Flow
                    try await parakeetEngine.initialize()
                    let rawText = try await parakeetEngine.transcribe(url: url)
                    
                    if let modeId = SettingsManager.shared.activeModeId,
                       let container = modelContainer,
                       let mode = try? container.mainContext.fetch(FetchDescriptor<Mode>(predicate: #Predicate { $0.id == modeId })).first {
                        finalText = try await LLMService.shared.process(text: rawText, mode: mode)
                    } else {
                        finalText = rawText
                    }
                }
                
                // 3. Save to Markdown File
                let originalFileName = url.deletingPathExtension().lastPathComponent
                let outputURL = url.deletingLastPathComponent().appendingPathComponent("\(originalFileName)_transcript.md")
                
                try finalText.write(to: outputURL, atomically: true, encoding: .utf8)
                print("AppState: Saved transcript to \(outputURL.path)")
                
                // 4. Show Success Message for 2 seconds
                await MainActor.run {
                    self.audioState.transcript = "✅ Saved to \(outputURL.lastPathComponent)"
                    self.audioState.status = .finished
                }
                
                try? await Task.sleep(nanoseconds: 2 * 1_000_000_000)
                
                // 5. Hide HUD
                await MainActor.run {
                    self.panelManager?.hide()
                    self.audioState.transcript = "" // Reset
                }
                
            } catch {
                print("AppState: Import failed: \(error)")
                await MainActor.run {
                    self.audioState.transcript = "Error: \(error.localizedDescription)"
                    self.audioState.status = .error
                }
                try? await Task.sleep(nanoseconds: 3 * 1_000_000_000)
                await MainActor.run { self.panelManager?.hide() }
            }
        }
    }
}
