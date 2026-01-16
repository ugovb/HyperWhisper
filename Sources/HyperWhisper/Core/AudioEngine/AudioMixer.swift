import Foundation
@preconcurrency import AVFoundation
import CoreMedia
import OSLog
import Combine

/// Coordinator for Audio Inputs.
/// Mixes Microphone and System Audio streams into a single stream for transcription based on correct mode.
@MainActor
class AudioMixer: ObservableObject {
    private let logger = Logger(subsystem: "com.hyperwhisper", category: "AudioMixer")
    
    // Inputs
    private nonisolated(unsafe) let micCapturer = AudioRecorderService()
    private nonisolated(unsafe) let systemCapturer = SystemAudioCapturer()
    
    // Processor
    private let processor = AudioProcessor()
    
    // Output Delegate
    var onMixedAudio: (([Float]) -> Void)?
    
    // File Recording
    private nonisolated(unsafe) var audioFile: AVAudioFile?
    private nonisolated(unsafe) var recordingURL: URL?
    
    // Mixing Logic
    enum CaptureMode: Hashable {
        case microphoneOnly
        case systemOnly
        case both(mixRatio: Float)
    }
    
    @Published var currentMode: CaptureMode = .microphoneOnly
    
    private let mixQueue = DispatchQueue(label: "com.hyperwhisper.audioMixer")
    
    init() {
        setupCallbacks()
    }
    
    private func setupCallbacks() {
        // Handle Microphone Input
        micCapturer.onAudioBuffer = { [weak self] buffer in
            guard let self = self else { return }
            self.handleMicInput(buffer: buffer)
        }
        
        // Handle System Input
        systemCapturer.onAudioBuffer = { [weak self] sampleBuffer in
            guard let self = self else { return }
            self.handleSystemInput(sampleBuffer: sampleBuffer)
        }
    }
    
    // MARK: - Control
    
    private nonisolated(unsafe) var _safeMode: CaptureMode = .microphoneOnly
    
    func setMode(_ mode: CaptureMode) {
        self.currentMode = mode
        self._safeMode = mode
        logger.info("AudioMixer mode set to: \(String(describing: mode))")
    }
    
    func startRecordingToFile() async throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "hyperwhisper_\(UUID().uuidString).wav"
        let url = tempDir.appendingPathComponent(fileName)
        self.recordingURL = url
        
        // 16kHz Float32 Mono
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: 16000.0,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 32,
            AVLinearPCMIsFloatKey: true,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsNonInterleaved: false
        ]
        
        self.audioFile = try AVAudioFile(forWriting: url, settings: settings, commonFormat: .pcmFormatFloat32, interleaved: false)
        
        // Start inputs
        try await start()
        
        return url
    }
    
    // ...
    
    func stopRecordingToFile() async -> URL? {
        await stop()
        self.audioFile = nil // Close file
        return self.recordingURL
    }
    
    func start() async throws {
        switch currentMode {
        case .microphoneOnly:
            try micCapturer.startRecording()
        case .systemOnly:
            try await systemCapturer.startCapturing()
        case .both:
            try micCapturer.startRecording()
            try await systemCapturer.startCapturing()
        }
    }
    
    func stop() async {
        switch currentMode {
        case .microphoneOnly:
            micCapturer.stopRecording()
        case .systemOnly:
            await systemCapturer.stopCapturing()
        case .both:
            micCapturer.stopRecording()
            await systemCapturer.stopCapturing()
        }
    }
    
    // MARK: - Mixing & Writing
    
    private func handleMicInput(buffer: AVAudioPCMBuffer) {
        guard let processedSamples = self.processor.process(buffer: buffer) else { return }
        
        mixQueue.async { [weak self] in
            guard let self = self else { return }
            
            var finalSamples: [Float] = []
            
            switch self._safeMode {
            case .microphoneOnly:
                finalSamples = processedSamples
            case .both(let ratio):
                finalSamples = processedSamples.map { $0 * ratio }
            case .systemOnly:
                break
            }
            
            if !finalSamples.isEmpty {
                self.processOutput(samples: finalSamples)
            }
        }
    }
    
    private func handleSystemInput(sampleBuffer: CMSampleBuffer) {
        guard let processedSamples = self.processor.process(sampleBuffer: sampleBuffer) else { return }
        
        mixQueue.async { [weak self] in
            guard let self = self else { return }
            
            var finalSamples: [Float] = []
            
            switch self._safeMode {
            case .systemOnly:
                finalSamples = processedSamples
            case .both(let ratio):
                let systemRatio = 1.0 - ratio
                finalSamples = processedSamples.map { $0 * systemRatio }
            case .microphoneOnly:
                break
            }
            
            if !finalSamples.isEmpty {
                self.processOutput(samples: finalSamples)
            }
        }
    }
    
    nonisolated private func processOutput(samples: [Float]) {
        // 1. Send to Visualizer (Main Thread)
        DispatchQueue.main.async {
            self.onMixedAudio?(samples)
        }
        
        // 2. Write to File (Mix Queue - Serial)
        // audioFile is nonisolated(unsafe), accessed serially on mixQueue
        if let file = self.audioFile {
            do {
                if let buffer = audioBuffer(from: samples) {
                    try file.write(from: buffer)
                }
            } catch {
                print("AudioMixer: Write failed: \(error)")
            }
        }
    }
    
    nonisolated private func audioBuffer(from samples: [Float]) -> AVAudioPCMBuffer? {
        guard !samples.isEmpty else { return nil }
        let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 16000, channels: 1, interleaved: false)!
        let frameCount = AVAudioFrameCount(samples.count)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        
        buffer.frameLength = frameCount
        if let channelData = buffer.floatChannelData?[0] {
            samples.withUnsafeBufferPointer { ptr in
                channelData.update(from: ptr.baseAddress!, count: samples.count)
            }
        }
        return buffer
    }
    
    // MARK: - Device Management Wrappers
    
    func listDevices() async -> [AudioRecorderService.AudioDevice] {
        return await micCapturer.listDevices()
    }
    
    func setInputDevice(id: String) async throws {
        try await micCapturer.setInputDevice(id: id)
    }
    
    func refreshDevices() async -> [AudioRecorderService.AudioDevice] {
        return await micCapturer.listDevices()
    }
    
    func getInputVolume() async -> Float {
        return await micCapturer.getInputVolume()
    }
    
    func setInputVolume(_ volume: Float) async {
        await micCapturer.setInputVolume(volume)
    }
    
    func startMonitoring() async throws {
        try await micCapturer.startMonitoring()
    }
    
    func stopMonitoring() async {
        await micCapturer.stopMonitoring()
    }
}
