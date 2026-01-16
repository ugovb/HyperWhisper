# Product Requirements Document (PRD): HyperWhisper

## 1. Goals and Background Context

### Goals
*   **Replicate Pro UX:** Successfully replicate the core "Superwhisper" recording and transcription flow with a polished, native feel.
*   **High-Speed Local ASR:** Demonstrate viable local inference of NVIDIA Parakeet TDT models using MLX Swift with < 200ms latency.
*   **Privacy-First Design:** Guarantee zero data leakage when utilizing "Local Mode" for transcription and post-processing.
*   **Reliable Global Access:** Ensure 100% reliable global hotkey activation (Cmd+Shift+Space) and text injection.
*   **Hybrid Flexibility:** Seamlessly support both completely offline workflows and cloud-enhanced processing via API keys.

### Background Context
HyperWhisper addresses the trade-off between privacy, speed, and intelligence in voice-to-text tools. While cloud-based solutions are smart but slow and privacy-invasive, existing local solutions often lack the "Pro" UX and advanced post-processing features. By leveraging MLX Swift for local GPU-accelerated inference on Apple Silicon, HyperWhisper provides a high-performance, private-by-default dictation tool with hybrid AI formatting capabilities.

### Change Log
| Date | Version | Description | Author |
| :--- | :--- | :--- | :--- |
| 2026-01-11 | v1.0 | Initial PRD draft from Product Brief | John (PM) |

## 2. Requirements

### Functional Requirements
*   **FR1: Global Access:** The application must reside in the macOS menu bar and toggle recording instantly via a global hotkey (Cmd+Shift+Space).
*   **FR2: Recording Engine:** Support for recording from system default input or manually selected devices (e.g., AirPods).
*   **FR3: Audio Processing:** Automatic silence removal during the recording phase to optimize processing time.
*   **FR4: Floating HUD:** A minimal, always-on-top pill-shaped window visualizing the recording state ("Listening", "Processing", "Finished") with a real-time waveform.
*   **FR5: Local Transcription:** On-device inference of NVIDIA Parakeet (TDT 0.6b or 1.1b) models using MLX Swift.
*   **FR6: Post-Processing Pipeline:** A "Modes" system (e.g., "Refine", "Summarize") that processes raw text using either Local LLMs (Llama 3 via MLX) or Cloud APIs (OpenAI, Anthropic, Google).
*   **FR7: Text Insertion:** Final processed text must be automatically injected into the active application using the macOS Accessibility API or clipboard injection.
*   **FR8: Configuration Dashboard:** A central settings window for managing input devices, API keys, "Mode" prompts, and local model downloads.
*   **FR9: History Management:** A basic list of past transcriptions with "Copy to Clipboard" functionality.

### Non-Functional Requirements
*   **NFR1: Performance:** End-to-end transcription latency must be < 200ms after speech ends on M-series Apple Silicon.
*   **NFR2: Privacy:** Zero data leakage to external servers when utilizing "Local Mode" for both ASR and LLM processing.
*   **NFR3: Native Build:** The application must be a 100% native macOS binary (Swift 6/SwiftUI) with no Python runtime dependencies.
*   **NFR4: Platform Support:** Optimized specifically for macOS 15+ (Sequoia) and Apple Silicon hardware.

## 3. User Interface Design Goals

### Overall UX Vision
The interface should be invisible until needed. The "Pill" HUD is the primary interaction point—it must feel fluid, responsive, and unmistakably "native" to macOS. It should convey system status (listening vs. thinking) without distracting the user.

### Key Interaction Paradigms
*   **One-Shot Activation:** Press hotkey -> Speak -> Stop -> Text appears. No other clicks required.
*   **Visual Feedback:** The waveform reacts instantly to voice, confirming the microphone is active.
*   **Modeless Configuration:** Settings and History are tucked away in a dashboard, separate from the dictation flow.

### Core Screens
1.  **Floating HUD (The Pill):** 
    *   **State 1 (Listening):** Dynamic waveform visualization.
    *   **State 2 (Processing):** Subtle indeterminate spinner or pulse.
    *   **State 3 (Success/Error):** Brief checkmark or error icon before dismissing.
2.  **Configuration Dashboard:**
    *   **Sidebar Navigation:** General, Modes, Models, History.
    *   **Models Library:** Card-based layout for managing local model downloads (Parakeet, Llama 3) with progress bars.
    *   **Modes Editor:** Simple form for editing system prompts (e.g., "You are a helpful assistant that corrects grammar...").

## 4. Technical Assumptions

*   **Repository Structure:** Monorepo (Single Xcode Project / SPM Package).
*   **Service Architecture:** Modular Monolith (Services for Audio, Transcription, LLM Orchestration).
*   **Testing:** Unit tests for core logic (parsers, formatters); Manual testing for audio/UI interactions.
*   **Core Libraries:** 
    *   `mlx-swift` (ASR/LLM Inference)
    *   `AVFoundation` (Audio Capture)
    *   `SwiftData` (Persistence)
    *   `AppKit` (Global Window Management)

## 5. Epic List

*   **Epic 1: Foundation & Audio Ear:** Establish project skeleton, menu bar app, floating HUD, and reliable audio recording to WAV.
*   **Epic 2: The Brain (Parakeet Integration):** Implement MLX Swift integration, load Parakeet TDT weights, and get raw transcription working.
*   **Epic 3: The Intelligence (LLM Orchestration):** Build the "Modes" system, integrate Local LLM (MLX) and Cloud APIs.
*   **Epic 4: Polish & Persistence:** Add History view, Settings dashboard, sound effects, and refinement.

## 6. Epic Details

### Epic 1: Foundation & Audio Ear
**Goal:** Create a functional Menu Bar app that can record audio from the microphone and display a responsive Floating HUD.

*   **Story 1.1: Project Skeleton & Menu Bar**
    *   **Goal:** Set up Swift 6 project, Menu Bar Extra, and app lifecycle.
    *   **Acceptance Criteria:**
        1. App launches with a menu bar icon.
        2. "Quit" menu item successfully terminates the app.
        3. Global hotkey (Cmd+Shift+Space) prints a debug log when pressed.

*   **Story 1.2: Floating HUD UI**
    *   **Goal:** Implement the SwiftUI "Pill" view and `FloatingPanelManager` to manage it.
    *   **Acceptance Criteria:**
        1. Pressing the hotkey toggles a floating window.
        2. Window is pill-shaped, translucent, and floats above other apps (`.floating` level).
        3. Window does not steal keyboard focus from the active app.

*   **Story 1.3: Audio Recorder Service**
    *   **Goal:** Implement `AudioEngineService` to capture mic input.
    *   **Acceptance Criteria:**
        1. Service requests Microphone permissions on first run.
        2. Starts recording to a temporary buffer/file on command.
        3. Stops recording and saves/processes the buffer on command.

*   **Story 1.4: Waveform Visualization**
    *   **Goal:** Connect audio amplitude data from Service to HUD.
    *   **Acceptance Criteria:**
        1. `AudioEngineService` broadcasts amplitude data (RMS).
        2. HUD displays a dynamic animation (waveform or bar) driven by voice volume.

### Epic 2: The Brain (Parakeet Integration)
**Goal:** Transcribe recorded audio into text using NVIDIA Parakeet models via MLX Swift.

*   **Story 2.1: Parakeet Model Loader**
    *   **Goal:** Implement logic to load model weights (Safetensors/NPZ) into MLX Swift.
    *   **Acceptance Criteria:**
        1. Service can locate and load model files from the bundle or a local directory.
        2. Successfully initializes the TDT model structure in memory.

*   **Story 2.2: TDT Decoding Loop**
    *   **Goal:** Implement the Token-and-Duration Transducer decoding algorithm.
    *   **Acceptance Criteria:**
        1. Implements the specific TDT search/decoding logic in Swift.
        2. Converts model logits into a sequence of text tokens.

*   **Story 2.3: Transcription Service Integration**
    *   **Goal:** Connect `AudioEngineService` output to `ParakeetRecognizer`.
    *   **Acceptance Criteria:**
        1. Audio buffer is correctly converted to 16kHz mono.
        2. Transcription service processes the buffer and returns a raw string.
        3. Latency is measured and logged.

*   **Story 2.4: Text Injection**
    *   **Goal:** Implement text output to the active application.
    *   **Acceptance Criteria:**
        1. App detects the currently focused text field (via Accessibility API).
        2. Transcribed text is inserted reliably.
        3. Fallback to Clipboard + Cmd-V simulation if Accessibility fails.

### Epic 3: The Intelligence (LLM Orchestration)
**Goal:** Process raw transcription with LLMs for formatting and correction.

*   **Story 3.1: LLM Service & Modes**
    *   **Goal:** Create `LLMOrchestrator` and a "Modes" configuration.
    *   **Acceptance Criteria:**
        1. Define "Mode" struct (Name, System Prompt, Provider).
        2. Service selects correct provider based on the active Mode.

*   **Story 3.2: Cloud API Client**
    *   **Goal:** Implement generic client for OpenAI/Anthropic APIs.
    *   **Acceptance Criteria:**
        1. Can make a secure request to OpenAI/Anthropic/Gemini endpoints.
        2. Handles API keys securely (stored in Keychain or local config).

*   **Story 3.3: Local LLM Runner**
    *   **Goal:** Use `MLXLLM` to run quantized Llama 3 models locally.
    *   **Acceptance Criteria:**
        1. Loads a quantized (4-bit) Llama 3 model via MLX.
        2. Processes the transcribed text with the system prompt locally.

### Epic 4: Polish & Persistence
**Goal:** Make the app usable daily with history and configuration.

*   **Story 4.1: SwiftData Persistence**
    *   **Goal:** Store transcription history and user settings.
    *   **Acceptance Criteria:**
        1. Transcriptions persist across app restarts.
        2. User settings (preferred mic, active mode) are saved.

*   **Story 4.2: Dashboard UI**
    *   **Goal:** Build the comprehensive Settings window.
    *   **Acceptance Criteria:**
        1. Tabbed interface for Settings, Models, History.
        2. Clean, native macOS styling.

*   **Story 4.3: Model Manager**
    *   **Goal:** UI for downloading/deleting large model weights.
    *   **Acceptance Criteria:**
        1. Displays available models and their sizes.
        2. Shows download progress.
        3. Allows deletion to free up space.

## 7. Next Steps

1.  **Architecture Review:** Architect to confirm the technical approach for Parakeet TDT decoding in Swift.
2.  **Phase 1 Execution:** Developer to begin implementation of Epic 1 (Skeleton & Audio Ear).