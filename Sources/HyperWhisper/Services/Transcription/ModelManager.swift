import Foundation
import Combine
import FluidAudio

/// Manages downloading of transcription models.
@MainActor
class ModelDownloader: ObservableObject {
    enum ModelType: String, CaseIterable, Identifiable {
        case parakeet = "Parakeet TDT 0.6b"
        case whisper = "Whisper Large v3"
        var id: String { rawValue }
    }
    
    @Published var isDownloading = false
    @Published var downloadProgress: Double = 0.0
    @Published var lastError: String?
    @Published var isModelReady = false
    
    init() {
        // Check on init if model is already available
        checkModelStatus()
    }
    
    func checkModelStatus() {
        isModelReady = isModelAvailable(type: .parakeet)
    }
    
    func isModelAvailable(type: ModelType) -> Bool {
        // Check if FluidAudio model directory exists with vocab file (indicates complete download)
        let modelPath = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("FluidAudio/Models/parakeet-tdt-0.6b-v3-coreml/parakeet_vocab.json")
        
        if let path = modelPath, FileManager.default.fileExists(atPath: path.path) {
            return true
        }
        return false
    }
    
    func downloadModel(type: ModelType) async {
        isDownloading = true
        downloadProgress = 0.0
        lastError = nil
        isModelReady = false
        
        // Start progress simulation task
        let progressTask = Task {
            // Simulate gradual progress over ~2 minutes (typical download time)
            for i in 1...95 {
                try? await Task.sleep(nanoseconds: 1_200_000_000) // ~1.2s per step
                if Task.isCancelled { break }
                await MainActor.run {
                    self.downloadProgress = Double(i) / 100.0
                }
            }
        }
        
        do {
            // Real FluidAudio model download (~490MB)
            print("ModelDownloader: Starting real FluidAudio model download...")
            
            // This actually downloads the model if not present
            _ = try await AsrModels.downloadAndLoad(version: .v3)
            
            // Cancel progress simulation and set to complete
            progressTask.cancel()
            downloadProgress = 1.0
            isModelReady = true
            print("ModelDownloader: Model downloaded successfully!")
        } catch {
            progressTask.cancel()
            lastError = "Download failed: \(error.localizedDescription)"
            print("ModelDownloader: Download failed: \(error)")
        }
        
        isDownloading = false
    }
}

/// Simple ModelManager to satisfy UI dependencies.
@MainActor
class ModelManager: ObservableObject {
    static let shared = ModelManager()
    
    @Published var models: [ModelDownloadInfo] = ModelRegistry.availableModels
    
    func startDownload(for id: String) {
        if let index = models.firstIndex(where: { $0.id == id }) {
            models[index].status = .downloading
            // Simulate progress
            Task {
                for i in 1...10 {
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    models[index].progress = Double(i) / 10.0
                }
                models[index].status = .downloaded
            }
        }
    }
    
    func cancelDownload(for id: String) {
        if let index = models.firstIndex(where: { $0.id == id }) {
            models[index].status = .notDownloaded
            models[index].progress = 0
        }
    }
    
    func pauseDownload(for id: String) {
        if let index = models.firstIndex(where: { $0.id == id }) {
            models[index].status = .paused
        }
    }
    
    func loadModel(_ model: ModelDownloadInfo) async {
        // Placeholder
    }
}
