# Epic 3: The Intelligence (LLM Orchestration) - Brownfield Enhancement

## Epic Goal
Build a flexible "Modes" system that allows users to process raw transcription using local or cloud LLMs for formatting, summarization, or refinement.

## Epic Description

**Existing System Context:**
- Current relevant functionality: Raw transcription is available (from Epic 2).
- Technology stack: MLX LLM (local), REST APIs (Cloud), Keychain.
- Integration points: `TranscriptionService` output, `TextInjectionService` input.

**Enhancement Details:**
- What's being added/changed: A `Mode` configuration system, an `LLMOrchestrator` to manage different providers, and specific runners for local (Llama 3 via MLX) and cloud (OpenAI/Anthropic) models.
- How it integrates: Sits between the ASR engine and the Text Injector, transforming the "Raw" text into "Processed" text based on the user's active mode.
- Success criteria: User can select a mode (e.g., "Refine Grammar") and have their speech automatically formatted by the chosen LLM.

## Stories
1. **Story 3.1: LLM Service & Modes** - Core orchestrator and configuration.
2. **Story 3.2: Cloud API Client** - Integration with OpenAI/Anthropic.
3. **Story 3.3: Local LLM Runner** - Integration with Llama 3 via MLX.

## Compatibility Requirements
- [x] Existing APIs remain unchanged
- [x] Secure storage for API keys (Keychain)

## Risk Mitigation
- **Primary Risk:** Local LLM memory usage (Llama 3 8B might be too heavy for some Macs).
- **Mitigation:** Use 4-bit quantization and provide clear memory requirements/warnings.
- **Rollback Plan:** None (new functionality).

## Definition of Done
- [ ] Multiple modes selectable in UI
- [ ] Text processing working via Cloud and Local paths
- [ ] API keys stored securely
