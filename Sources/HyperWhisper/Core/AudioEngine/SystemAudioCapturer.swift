import Foundation
import ScreenCaptureKit
import AVFoundation
import OSLog

/// Captures system audio using ScreenCaptureKit.
/// Excludes the current application's audio to prevent feedback loops.
class SystemAudioCapturer: NSObject, SCStreamOutput, SCStreamDelegate {
    
    private let logger = Logger(subsystem: "com.hyperwhisper", category: "SystemAudioCapturer")
    
    private var stream: SCStream?
    private let streamOutputQueue = DispatchQueue(label: "com.hyperwhisper.systemAudioOutput")
    
    // Callback for delivering audio buffers
    var onAudioBuffer: ((CMSampleBuffer) -> Void)?
    
    var isCapturing: Bool {
        return stream != nil
    }
    
    /// Starts capturing system audio.
    func startCapturing() async throws {
        // 1. Check for content sharing support (macOS 12.3+)
        // SCShareableContent.current() is async throws
        
        do {
            // 2. Get shareable content (windows, displays, apps)
            // This call usually triggers the Screen Recording permission prompt if not granted.
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            
            // 3. Define exclusion: Exclude our own app
            let currentApp = content.applications.first(where: { $0.bundleIdentifier == Bundle.main.bundleIdentifier })
            
            if currentApp == nil {
                logger.warning("Could not find own app in SCShareableContent to exclude. Proceeding without specific app exclusion.")
            }
            
            try await startStream(with: content, excluding: currentApp)
            
        } catch {
            logger.error("Failed to get SCShareableContent. Likely missing Screen Recording permissions. Error: \(error.localizedDescription)")
            // Bubble up error so UI can potentially warn user
            throw error
        }
    }
    
    private func startStream(with content: SCShareableContent, excluding app: SCRunningApplication?) async throws {
        // Create filter
        let filter: SCContentFilter
        
        // Use the first available display (usually Main)
        guard let display = content.displays.first else {
            throw NSError(domain: "SystemAudioCapturer", code: 2, userInfo: [NSLocalizedDescriptionKey: "No display found to capture audio from."])
        }
        
        if let app = app {
            filter = SCContentFilter(display: display, excludingApplications: [app], exceptingWindows: [])
        } else {
            filter = SCContentFilter(display: display, excludingApplications: [], exceptingWindows: [])
        }
        
        // Configuration
        let config = SCStreamConfiguration()
        config.capturesAudio = true
        config.sampleRate = 16000    // Target 16kHz for Parakeet
        config.channelCount = 1      // Mono
        config.excludesCurrentProcessAudio = true // Native exclusion
        
        // Ensure valid frame size even for audio-only to hint capture engine? 
        // Docs say width/height can be 0 for audio-only, but let's stick to defaults.
        
        // Initialize Stream
        stream = SCStream(filter: filter, configuration: config, delegate: self)
        
        // Add output
        try stream?.addStreamOutput(self, type: .audio, sampleHandlerQueue: streamOutputQueue)
        
        // Start
        try await stream?.startCapture()
        logger.info("System Audio Capture started successfully.")
    }
    
    /// Stops capturing.
    func stopCapturing() async {
        if let stream = stream {
            try? await stream.stopCapture()
            self.stream = nil
            logger.info("System Audio Capture stopped.")
        }
    }
    
    // MARK: - SCStreamOutput
    
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .audio else { return }
        
        // Forward buffer directly
        onAudioBuffer?(sampleBuffer)
    }
    
    // MARK: - SCStreamDelegate
    
    func stream(_ stream: SCStream, didStopWithError error: Error) {
        logger.error("Stream stopped with error: \(error.localizedDescription)")
        self.stream = nil
    }
}
