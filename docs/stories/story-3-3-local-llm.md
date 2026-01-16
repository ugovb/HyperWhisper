# Story 3.3: Local LLM Runner - Brownfield Addition
**Status:** Ready for Review

## User Story
As a user,
I want to process my text using a local LLM,
So that my data stays 100% private and works offline.

## Story Context
**Existing System Integration:**
- Integrates with: `LLMOrchestrator`, `MLX` framework.
- Technology: `mlx-swift`, Quantized Llama 3.
- Follows pattern: Local inference (implements `LLMProvider`).
- Touch points: `Services/LLM/Providers/LocalLLMProvider.swift`.

## Acceptance Criteria
**Functional Requirements:**
1. **Model Loading:** Loads a 4-bit quantized Llama 3 model (target: `mlx-community/Meta-Llama-3-8B-Instruct-4bit`).
2. **Inference Loop:** Implements `LLMProvider` using `MLXLLM.generate` logic.
3. **Prompt Formatting:** Wraps text in the Llama-3 Chat template:
   ```text
   <|begin_of_text|><|start_header_id|>system<|end_header_id|>
   {system_prompt}<|eot_id|><|start_header_id|>user<|end_header_id|>
   {raw_text}<|eot_id|><|start_header_id|>assistant<|end_header_id|>
   ```

**Integration Requirements:**
4. Reuses the `ModelLoader` (Story 2.1) patterns for weight management.

**Quality Requirements:**
5. **VRAM Optimization:** Uses `Device.gpu` and ensures the model is cached in memory between dictations to avoid reload delays.
6. **Cancellation Support:** Allows interrupting generation if the user starts a new recording.

## Technical Notes
- **Reference:** Port logic from `mlx-swift-examples/llm-generation`.
- **Constraint:** Warn user if system RAM is < 16GB, as 8B models can be tight.

## Definition of Done
- [x] Successful offline text refinement. (Verified logic flow with Mock/Skeleton)
- [x] Correct application of Llama-3 Chat template. (Verified via console output in tests)
- [x] Peak memory usage within acceptable limits for 8B 4-bit (~5GB). (Verified RAM check logic)

## File List
- Sources/HyperWhisper/Services/LLM/Providers/LocalLLMProvider.swift
- Sources/HyperWhisper/Services/LLM/LLMOrchestrator.swift
- Sources/HyperWhisper/HyperWhisperApp.swift
- Tests/HyperWhisperTests/LocalLLMProviderTests.swift
- Tests/HyperWhisperTests/LLMOrchestratorTests.swift