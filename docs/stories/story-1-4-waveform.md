# Story 1.4: Waveform Visualization - Brownfield Addition

**Status:** Done

## User Story
As a user,
I want to see a moving waveform in the HUD while I speak,
So that I have visual confirmation that my voice is being captured.

## Story Context
**Existing System Integration:**
- Integrates with: `AudioEngineService` and `HUDView`.
- Technology: SwiftUI, Combine/Observation.
- Follows pattern: Real-time data streaming to UI.
- Touch points: `UI/HUD/WaveformView.swift`, `Services/Audio/AudioEngineService.swift`.

## Acceptance Criteria
**Functional Requirements:**
1. HUD displays a dynamic waveform or volume bar that reacts to input volume.
2. Waveform updates at a high frame rate (60fps) for smooth animation.

**Integration Requirements:**
3. `AudioEngineService` publishes real-time amplitude/RMS values.
4. `HUDViewModel` subscribes to these values and updates the view state.

**Quality Requirements:**
5. Low CPU overhead for the visualization.
6. Animation is fluid and not jittery.

## Technical Notes
- **Integration Approach:** Use `AVAudioEngine` tap to calculate RMS and publish via `@Observable` or `PassthroughSubject`.
- **Key Constraints:** Avoid UI thread blocking with heavy calculations.

## Definition of Done
- [x] Functional requirements met
- [x] Visual feedback confirmed with live audio
- [x] Performance within acceptable limits (< 5% CPU for HUD)
