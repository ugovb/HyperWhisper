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
    
    init() {}
    
    func isModelAvailable(type: ModelType) -> Bool {
        // Check if FluidAudio model directory exists
        let modelPath = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("FluidAudio/Models/parakeet-tdt-0.6b-v3-coreml")
        
        if let path = modelPath, FileManager.default.fileExists(atPath: path.path) {
            return true
        }
        return false
    }
    
    func downloadModel(type: ModelType) async {
        isDownloading = true
        downloadProgress = 0.1
        lastError = nil
        
        do {
            // Real FluidAudio model download (~490MB)
            print("ModelDownloader: Starting real FluidAudio model download...")
            downloadProgress = 0.2
            
            // This actually downloads the model if not present
            _ = try await AsrModels.downloadAndLoad(version: .v3)
            
            downloadProgress = 1.0
            print("ModelDownloader: Model downloaded successfully!")
        } catch {
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
