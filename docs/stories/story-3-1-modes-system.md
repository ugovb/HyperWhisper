# Story 3.1: LLM Service & Modes - Brownfield Addition
**Status:** Ready for Review

## User Story
As a user,
I want to choose between different processing "Modes" (e.g., "Summarize", "Fix Grammar"),
So that the app can format my dictation exactly how I need it for different tasks.

## Story Context
**Existing System Integration:**
- Integrates with: `TranscriptionService`.
- Technology: Swift 6, SwiftData (for Mode persistence).
- Follows pattern: Strategy Pattern for LLM providers.
- Touch points: `Services/LLM/LLMOrchestrator.swift`, `Models/Mode.swift`.

## Acceptance Criteria
**Functional Requirements:**
1. **Mode Model:** Define a SwiftData `@Model` for `Mode`:
   - `name: String`
   - `systemPrompt: String`
   - `providerType: ProviderType` (.local, .cloud)
   - `modelIdentifier: String` (e.g., "gpt-4o", "llama-3-8b")
2. **LLMProvider Protocol:** Define a common interface:
   ```swift
   protocol LLMProvider {
       func process(text: String, systemPrompt: String) async throws -> String
   }
   ```
3. **Orchestrator Logic:** `LLMOrchestrator` selects the active `LLMProvider` based on user selection and routes the `transcribe` result through it.
4. **Default Seeding:** On first launch, seed the database with:
   - "Direct Dictation": (No prompt, bypasses LLM)
   - "Refine Grammar": "Fix grammar and punctuation while keeping the original meaning."
   - "Meeting Notes": "Format this transcript into clear bullet points with action items."

**Integration Requirements:**
5. Integrates with `TranscriptionService` (Source) and `TextInjectionService` (Sink).

**Quality Requirements:**
6. Bypasses LLM processing if the "Direct Dictation" mode is selected to minimize latency.

## Technical Notes
- **Prompt Engineering:** Use a standard "User/Assistant" message wrapper internally to ensure compatibility across providers.
- **Persistence:** Use `ModelContext` to fetch the "Active Mode" set in user preferences.

## Definition of Done
- [x] `LLMProvider` protocol defined.
- [x] `Mode` seeding logic verified on first run. (Verified via AppState logic, though hard to test persistence in unit test without mocking context)
- [x] Orchestrator correctly routes text to the selected provider. (Verified via LLMOrchestratorTests)

## File List
- Sources/HyperWhisper/Models/Mode.swift
- Sources/HyperWhisper/Services/LLM/LLMProvider.swift
- Sources/HyperWhisper/Services/LLM/LLMOrchestrator.swift
- Sources/HyperWhisper/HyperWhisperApp.swift
- Tests/HyperWhisperTests/LLMOrchestratorTests.swift