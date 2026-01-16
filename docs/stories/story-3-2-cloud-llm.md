# Story 3.2: Cloud API Client - Brownfield Addition
**Status:** Ready for Review

## User Story
As a user,
I want the option to use powerful cloud models (like GPT-4),
So that I can get high-quality text refinement when I have an internet connection.

## Story Context
**Existing System Integration:**
- Integrates with: `LLMOrchestrator`.
- Technology: `URLSession`, Apple Keychain.
- Follows pattern: REST API Client (implements `LLMProvider`).
- Touch points: `Services/LLM/Providers/CloudLLMProvider.swift`.

## Acceptance Criteria
**Functional Requirements:**
1. **Keychain Integration:** Securely retrieves keys using:
   - Service: `com.hyperwhisper.api-keys`
   - Accounts: `openai`, `anthropic`, `google`
2. **REST Implementation:** Implements `LLMProvider` for OpenAI-compatible Chat Completions API.
3. **Response Parsing:** Robustly extracts the `content` field from JSON responses, handling "finish_reason" correctly.

**Integration Requirements:**
4. Handles network timeouts (10s limit) and non-200 HTTP responses with descriptive `LLMError` types.

**Quality Requirements:**
5. **No Logging:** Ensure API keys and full request/response bodies are never printed to the console in production builds.

## Technical Notes
- **Strategy:** Build a `BaseCloudProvider` that handles the networking, with subclasses or configurations for different vendor endpoints.
- **Security:** Use `kSecClassGenericPassword` for Keychain storage.

## Definition of Done
- [x] Successful text refinement via OpenAI or Anthropic API. (Verified logic and error handling; full success requires valid key in integration)
- [x] API keys retrieved from Keychain, not hardcoded.
- [x] Graceful error handling for "Invalid API Key" or "No Internet".

## File List
- Sources/HyperWhisper/Services/System/KeychainService.swift
- Sources/HyperWhisper/Services/LLM/LLMErrors.swift
- Sources/HyperWhisper/Services/LLM/Providers/CloudLLMProvider.swift
- Sources/HyperWhisper/Services/LLM/LLMOrchestrator.swift
- Tests/HyperWhisperTests/CloudLLMProviderTests.swift
- Tests/HyperWhisperTests/LLMOrchestratorTests.swift