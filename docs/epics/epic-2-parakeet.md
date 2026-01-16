# Epic 2: The Brain (Parakeet Integration) - Brownfield Enhancement

## Epic Goal
Integrate NVIDIA Parakeet TDT models using MLX Swift to provide high-speed, local transcription of recorded audio.

## Epic Description

**Existing System Context:**
- Current relevant functionality: Audio capture is functional (from Epic 1).
- Technology stack: MLX Swift, Metal, TDT (Token-and-Duration Transducer).
- Integration points: `AudioEngineService` output, macOS active application (for text injection).

**Enhancement Details:**
- What's being added/changed: Model loading logic for MLX, implementation of the TDT decoding algorithm in Swift, and a transcription service that orchestrates the pipeline.
- How it integrates: Receives audio buffers from the `AudioEngineService`, processes them on the GPU, and sends the result to the `TextInjectionService`.
- Success criteria: Audio is accurately transcribed into text locally with < 200ms latency.

## Stories
1. **Story 2.1: Parakeet Model Loader** - Logic to load weights into MLX.
2. **Story 2.2: TDT Decoding Loop** - Implementation of the search/decoding algorithm.
3. **Story 2.3: Transcription Service Integration** - Pipeline connection.
4. **Story 2.4: Text Injection** - Inserting text into the active app via Accessibility API.

## Compatibility Requirements
- [x] Existing APIs remain unchanged
- [x] Performance impact is minimal (optimized for GPU)

## Risk Mitigation
- **Primary Risk:** TDT decoding complexity in Swift or MLX performance bottlenecks.
- **Mitigation:** Reference existing Python/C++ TDT implementations and optimize Metal kernels if needed.
- **Rollback Plan:** None (new functionality).

## Definition of Done
- [ ] Transcription working locally
- [ ] Latency targets met
- [ ] Text injected correctly into target apps
