# Project Brief: HyperWhisper

## 1. Executive Summary
HyperWhisper is a high-performance, native macOS voice-to-text application designed to recreate the UX of "Superwhisper" with a strict focus on privacy, speed, and flexibility. It leverages NVIDIA's Parakeet ASR model running locally on Apple Silicon via MLX Swift for near-instant transcription, offering a seamless multi-device input experience and hybrid AI post-processing capabilities.

## 2. Problem Statement
Current voice-to-text solutions often rely heavily on cloud processing, introducing latency and privacy concerns. While local solutions exist, they often lack the sophisticated UX or the advanced post-processing capabilities of cloud-based tools. There is a need for a tool that combines the privacy and speed of local inference (using state-of-the-art models like Parakeet) with the flexibility of LLM-based formatting, all wrapped in a native, polished macOS interface.

## 3. Proposed Solution
HyperWhisper is a native macOS application (Swift 6, SwiftUI + AppKit) that lives in the menu bar.
*   **Core Logic:** It uses `MLX Swift` to run the NVIDIA Parakeet model locally on the GPU for transcription.
*   **Post-Processing:** It employs a strategy pattern to send transcribed text to either local LLMs (Llama 3 via MLX) or cloud providers (OpenAI, Anthropic, Google) for formatting and refinement.
*   **UX:** A minimal, floating "pill" HUD for recording control and a comprehensive dashboard for configuration.

## 4. Target Users
*   **Primary Segment:** Power Users & Developers on macOS who demand high-speed, private dictation and have Apple Silicon hardware.
*   **Secondary Segment:** Professionals requiring automated meeting notes (Zoom/Teams) via system audio capture.

## 5. Goals & Success Metrics
*   **Business Objectives:**
    *   Successfully replicate the core "Superwhisper" recording and transcription flow.
    *   Demonstrate viable local inference of Parakeet TDT models using MLX Swift.
*   **User Success Metrics:**
    *   Transcription latency < 200ms after speech ends.
    *   100% reliable global hotkey activation.
    *   Zero data leakage when using Local Mode.

## 6. MVP Scope
### Core Features (Must Have)
*   **Global Access:** Menu bar app with Global Hotkey (Cmd+Shift+Space) toggle.
*   **Recording Engine:** Input agnostic (Mic/System), Silence removal, Floating HUD with waveform.
*   **Transcription:** Local NVIDIA Parakeet (TDT 0.6b/1.1b) via MLX Swift.
*   **Post-Processing:** Basic "Modes" (Refine, Summarize) using at least one Local LLM and one Cloud API.
*   **Output:** Text injection into active app via Accessibility API.

### Out of Scope for MVP
*   Complex "Vocabulary" regex replacement (Phase 4).
*   Deepgram fallback (unless local fails completely).
*   Full history search/sync (Basic history only for MVP).

## 7. Technical Considerations
*   **Platform:** macOS 15+ (Sequoia), Apple Silicon (M-series) required for MLX.
*   **Language:** Swift 6.
*   **AI Engine:** **MLX Swift** (No Python dependencies).
    *   ASR: Parakeet TDT variants.
    *   LLM: Llama 3 / Mistral quantized.
*   **Audio:** AVFoundation (Capture), AudioToolbox (Conversion).
*   **UI:** SwiftUI for views, AppKit for `NSPanel` (Floating HUD) and Menu Bar status.
*   **Data:** SwiftData for persistence.

## 8. Risks & Open Questions
*   **Risk:** **Parakeet on MLX Swift:** Porting/running NVIDIA's TDT decoding loop purely in Swift/MLX might be non-trivial compared to PyTorch.
    *   *Mitigation:* Prototype this specific component first (Phase 2 priority).
*   **Risk:** **Audio Loopback:** Capturing system audio (Zoom/Teams) often requires virtual audio drivers (like BlackHole) or strict permissions.
    *   *Mitigation:* Focus on Microphone input first; investigate `SCStream` (ScreenCaptureKit) for system audio if standard AVFoundation routing is insufficient.

## 9. Next Steps (Implementation Phases)
1.  **Phase 1 (Skeleton):** macOS Menu bar app, AudioEngineService, Floating HUD.
2.  **Phase 2 (Brain):** MLX Swift integration, Parakeet model loading & inference.
3.  **Phase 3 (Intelligence):** LLM Orchestrator (Local/Cloud), Modes UI.
4.  **Phase 4 (Polish):** History, Settings, Sound effects.
