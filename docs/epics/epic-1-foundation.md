# Epic 1: Foundation & Audio Ear - Brownfield Enhancement

## Epic Goal
Establish the core project skeleton, menu bar interface, floating HUD, and reliable audio recording capabilities to serve as the foundation for local ASR.

## Epic Description

**Existing System Context:**
- Current relevant functionality: Phase 1 Foundation complete (skeleton exists).
- Technology stack: Swift 6, SwiftUI, AppKit, AVFoundation.
- Integration points: macOS Menu Bar, System Audio Input, Window Management.

**Enhancement Details:**
- What's being added/changed: Refinement of the menu bar app, implementation of the "Pill" HUD with focus-less floating behavior, and robust audio capture service.
- How it integrates: Connects UI triggers (hotkeys) to the audio engine and provides visual feedback via the HUD.
- Success criteria: Global hotkey activates recording, HUD displays real-time waveform, and audio is captured correctly.

## Stories
1. **Story 1.1: Project Skeleton & Menu Bar Refinement** - Set up app lifecycle and global hotkey.
2. **Story 1.2: Floating HUD UI** - Implement the focus-less pill-shaped window.
3. **Story 1.3: Audio Recorder Service** - Implement AVAudioEngine for mic capture.
4. **Story 1.4: Waveform Visualization** - Connect audio amplitude to the HUD UI.

## Compatibility Requirements
- [x] Existing APIs remain unchanged
- [x] Database schema changes are backward compatible
- [x] UI changes follow existing patterns
- [x] Performance impact is minimal

## Risk Mitigation
- **Primary Risk:** Global hotkey conflicts or accessibility permission issues.
- **Mitigation:** Use standard AppKit hotkey registration and provide clear onboarding for permissions.
- **Rollback Plan:** Revert to previous skeleton state.

## Definition of Done
- [ ] All stories completed with acceptance criteria met
- [ ] Existing functionality verified through testing
- [ ] Integration points working correctly
- [ ] Documentation updated appropriately
- [ ] No regression in existing features
