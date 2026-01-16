# Superwhisper Feature Specification Report
**Reference Application Analysis**

## 1. Core Core Loop (The "How It Works")
The application follows a strict three-step linear process for every interaction:
1.  **Dictation:** Captures raw audio input from the user.
2.  **Transcription:** Uses ASR (Automatic Speech Recognition) to convert audio to raw text.
3.  **Smart Processing (The "Modes" Layer):** Passes the raw text through an LLM (Large Language Model) with specific system instructions to format, summarize, or translate the output based on the user's intent.

## 2. Onboarding & Initial Setup (Critical Path)
The application must include a mandatory "First Run" wizard containing:
*   **System Permissions:** Explicit request UI for:
    *   `Microphone Access` (AVAudioSession).
    *   `Accessibility API` (Required to inject text into other apps).
*   **Language Configuration:** Selection of primary input language.
*   **Model Selection:** Choice between "Cloud" (High Accuracy) or "Local" (Private/Offline).
*   **Audio Check:** Input level verification.
*   **Interactive Tutorial:** A guided "First Dictation" requiring the user to use the global hotkey (e.g., `⌥ Space`) to verify the loop works.

## 3. Intelligent Modes Architecture
The app must support distinct processing "Modes".
*   **Built-in Modes:**
    *   **Voice-to-Text:** Raw transcription (speed-optimized, no LLM formatting).
    *   **Message:** Adds punctuation, fixes grammar, casual tone.
    *   **Email:** Formats as a professional email (Subject line + Body).
    *   **Meeting:** Summarizes audio into key points and action items.
    *   **Note:** Structured hierarchy (bullet points, headers).
*   **Custom Modes:**
    *   User-defined system prompts (System Instructions).
    *   Ability to chain context or specific formatting rules.

## 4. Advanced Technical Features
*   **Context-Awareness:**
    *   The app must detect the **active foreground application** (e.g., Xcode, Mail, Slack).
    *   It uses this context to inform the LLM (e.g., "If in Xcode, format as code comments").
*   **File Transcription:**
    *   Capability to drag-and-drop or select `.mp3` / `.wav` / `.m4a` files.
    *   Process: Upload/Read -> Transcribe -> Process with selected Mode.
*   **Multilingual Support:**
    *   Support for multiple languages.
    *   **"On-the-fly Translation":** Option to dictate in Language A and output in Language B.

## 5. AI & Model Infrastructure
*   **Hybrid Engine:**
    *   **Local:** Support for offline models (e.g., Whisper, Parakeet) running on-device (CoreML/MLX).
    *   **Cloud:** Integration with providers (Deepgram, Nova).
*   **"Bring Your Own Key" (BYOK):**
    *   Secure storage (Keychain) for user-provided API keys:
        *   OpenAI (GPT-4o, GPT-4-Turbo)
        *   Anthropic (Claude 3.5 Sonnet)
        *   Groq
        *   Deepgram

## 6. UX/UI Requirements
*   **Global Hotkey:** System-wide activation (default: `⌥ Space`).
*   **MenuBar App:** Resides in the macOS menu bar for quick settings access.
*   **Floating Window:** A non-intrusive recording HUD.
