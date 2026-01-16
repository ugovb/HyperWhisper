# Epic 4: Polish & Persistence - Brownfield Enhancement

## Epic Goal
Ensure the application is a complete, user-friendly product with transcription history, settings management, and automated model downloads.

## Epic Description

**Existing System Context:**
- Current relevant functionality: Core transcription/LLM flow is functional.
- Technology stack: SwiftUI, SwiftData, `URLSession` (for downloads).
- Integration points: All previous services, macOS File System.

**Enhancement Details:**
- What's being added/changed: A SwiftData-backed history of all transcriptions, a comprehensive "Dashboard" for settings and model management, and polish (sound effects, refined animations).
- How it integrates: Captures output from the `LLMOrchestrator` to save to history, and provides the UI to configure all other services.
- Success criteria: User can view past transcriptions, change settings, and download new models through a polished interface.

## Stories
1. **Story 4.1: SwiftData Persistence** - History and settings storage.
2. **Story 4.2: Dashboard UI** - The central settings and history window.
3. **Story 4.3: Model Manager** - Automated downloading and management of model weights.

## Compatibility Requirements
- [x] SwiftData schema migration awareness
- [x] Native macOS styling

## Risk Mitigation
- **Primary Risk:** Disk space exhaustion from large models.
- **Mitigation:** Provide clear file sizes and "Delete" options in the UI.
- **Rollback Plan:** None.

## Definition of Done
- [ ] History persists across app restarts
- [ ] Settings window is fully functional
- [ ] Models can be downloaded/deleted via UI
