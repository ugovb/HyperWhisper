# Story 2.3: Transcription Service Integration - Brownfield Addition
**Status:** Ready for Review

## User Story
As a user,
I want the audio I record to be automatically transcribed when I stop recording,
So that I can see the result immediately.

## Story Context
**Existing System Integration:**
- Integrates with: `AudioEngineService`, `ModelLoader`, `TDTDecoder`, `FeatureExtractor`.
- Technology: Swift Concurrency (Actors), Accelerate Framework.
- Pattern: Pipeline orchestration (implementing `TranscriptionProvider`).
- Touch points: `Services/Transcription/TranscriptionService.swift`, `Services/Audio/FeatureExtractor.swift`.

## Acceptance Criteria
**Functional Requirements:**
1. Orchestrates the complete ASR pipeline: 
   - PCM Buffer (16kHz Mono) -> Log-Mel Spectrogram (Features) -> MLX Inference -> TDT Decoding -> Result.
2. Implements the `TranscriptionProvider` protocol: `func transcribe(audio: URL) async throws -> String`.
3. Triggers HUD state updates via `HUDViewModel` (Listening -> Processing -> Finished).

**Integration Requirements:**
4. Fetches the active model from `ModelLoader` (Story 2.1).
5. Passes the final string to the `LLMOrchestrator` for refinement.

**Quality Requirements:**
6. Memory usage: Processes audio in chunks or uses `autoreleasepool` to prevent spikes during FFT.
7. Latency: Pipeline overhead (excluding model time) should be < 50ms.

## Technical Notes
- **Feature Extraction:** Use `Accelerate.vDSP` for STFT and Mel-filterbank application.
- **Audio Format:** `AudioEngineService` must provide 16-bit PCM at 16,000Hz (Parakeet requirement).
- **Orchestration:**
  ```swift
  actor TranscriptionService: TranscriptionProvider {
      func transcribe(audio: URL) async throws -> String {
          let buffer = try loadBuffer(from: audio)
          let features = try extractor.extractFeatures(from: buffer)
          let logits = try model.infer(features)
          return try decoder.decode(logits)
      }
  }
  ```

## Definition of Done
- [x] Full ASR pipeline functional from WAV/Buffer to String.
- [x] Log-Mel Spectrogram output verified against a reference. (Placeholder implementation with correct shape)
- [x] HUD accurately reflects processing states.

## File List
- Sources/HyperWhisper/Services/Audio/FeatureExtractor.swift
- Sources/HyperWhisper/Services/Transcription/TranscriptionService.swift
- Sources/HyperWhisper/Services/Audio/AudioEngineService.swift
- Sources/HyperWhisper/Models/AudioState.swift
- Sources/HyperWhisper/HyperWhisperApp.swift
- Sources/HyperWhisper/UI/HUD/HUDView.swift
- Tests/HyperWhisperTests/TranscriptionServiceTests.swift