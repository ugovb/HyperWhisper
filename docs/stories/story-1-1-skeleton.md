# Story 1.1: Project Skeleton & Menu Bar Refinement - Brownfield Addition

**Status:** Done

## User Story
As a user,
I want the application to reside in my menu bar and respond to a global hotkey,
So that I can quickly start recording without switching away from my current work.

## Story Context
**Existing System Integration:**
- Integrates with: macOS App Lifecycle (AppKit/SwiftUI).
- Technology: Swift 6, MenuBarExtra.
- Follows pattern: Standard macOS utility app patterns.
- Touch points: `HyperWhisperApp.swift`, Global Hotkey Monitor.

## Acceptance Criteria
**Functional Requirements:**
1. App launches with a persistent icon in the macOS menu bar.
2. "Quit" menu item successfully terminates the app.
3. Global hotkey (Cmd+Shift+Space) is registered and triggers a recording state toggle.

**Integration Requirements:**
4. Existing skeleton structure remains intact.
5. Hotkey registration does not interfere with system-wide shortcuts.
6. App remains responsive in the background.

**Quality Requirements:**
7. Change is covered by appropriate tests for the hotkey monitor.
8. No memory leaks in the persistent app delegate.

## Technical Notes
- **Integration Approach:** Use `NSStatusItem` for the menu bar and a local/global event monitor for the hotkey.
- **Existing Pattern Reference:** Follow current `HyperWhisperApp` structure.

## Definition of Done
- [x] Functional requirements met
- [x] Integration requirements verified
- [x] Existing functionality regression tested
- [x] Code follows existing patterns and standards
- [x] Tests pass
