# Story 1.3: Audio Recorder Service - Brownfield Addition

**Status:** Done

## User Story
As a user,
I want the app to capture my voice clearly from the microphone,
So that it can be transcribed accurately by the ASR engine.

## Story Context
**Existing System Integration:**
- Integrates with: `AVFoundation`.
- Technology: `AVAudioEngine`, `AVAudioSession`.
- Follows pattern: Service-oriented audio capture.
- Touch points: `Services/Audio/AudioEngineService.swift`.

## Acceptance Criteria
**Functional Requirements:**
1. App requests Microphone permissions on the first attempt to record.
2. `AudioEngineService` captures audio from the system default input.
3. Recording starts and stops reliably based on UI triggers.

**Integration Requirements:**
4. Audio is buffered correctly for downstream ASR (16kHz mono).
5. Handles device changes (e.g., plugging in AirPods) gracefully.

**Quality Requirements:**
6. Audio capture latency is minimal.
7. Correctly handles silence and peak amplitude calculation.

## Technical Notes
- **Integration Approach:** Use `AVAudioEngine` with a tap on the input bus.
- **Key Constraints:** Must handle macOS sandbox permissions.

## Definition of Done
- [x] Functional requirements met
- [x] Permissions handling verified
- [x] Audio data is valid and correctly formatted
- [x] Tests for buffer management pass
