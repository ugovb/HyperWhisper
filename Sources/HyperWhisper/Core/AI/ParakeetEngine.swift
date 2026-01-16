import Foundation
@preconcurrency import AVFoundation
import FluidAudio

/// A wrapper around FluidAudio for Parakeet TDT inference.
/// Handles model loading and offline file transcription (Speak2 style).
@MainActor
class ParakeetEngine {
    private var asrManager: AsrManager?
    private var isInitialized = false
    private var isInitializing = false
    private var pendingContinuations: [CheckedContinuation<Void, Error>] = []
    
    enum ParakeetError: Error {
        case notInitialized
        case modelLoadingFailed(Error)
    }

    init() {}
    
    /// Loads the Parakeet TDT 0.6b v3 model using FluidAudio.
    /// Thread-safe: concurrent calls will wait for the first initialization to complete.
    func initialize() async throws {
        // Already initialized - return immediately
        if isInitialized { return }
        
        // Already initializing - wait for completion
        if isInitializing {
            print("ParakeetEngine: Already initializing, waiting...")
            return try await withCheckedThrowingContinuation { continuation in
                pendingContinuations.append(continuation)
            }
        }
        
        // Start initialization
        isInitializing = true
        print("ParakeetEngine: Initializing FluidAudio (Offline Mode)...")
        
        do {
            let models = try await AsrModels.downloadAndLoad(version: .v3)
            
            let manager = AsrManager(config: .default)
            try await manager.initialize(models: models)
            
            self.asrManager = manager
            self.isInitialized = true
            self.isInitializing = false
            print("ParakeetEngine: Model loaded successfully.")
            
            // Resume all waiting callers
            for continuation in pendingContinuations {
                continuation.resume()
            }
            pendingContinuations.removeAll()
        } catch {
            self.isInitializing = false
            print("ParakeetEngine: Failed to load model: \(error)")
            
            // Fail all waiting callers
            for continuation in pendingContinuations {
                continuation.resume(throwing: error)
            }
            pendingContinuations.removeAll()
            
            throw ParakeetError.modelLoadingFailed(error)
        }
    }
    
    /// Transcribes an audio file.
    /// - Parameter url: The file URL to transcribe.
    /// - Returns: The transcribed text.
    func transcribe(url: URL) async throws -> String {
        guard let asrManager = asrManager, isInitialized else {
            throw ParakeetError.notInitialized
        }
        
        // FluidAudio's AsrManager.transcribe(url:) handles reading and resampling
        let result = try await asrManager.transcribe(url)
        return result.text
    }
}
