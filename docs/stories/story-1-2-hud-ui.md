# Story 1.2: Floating HUD UI - Brownfield Addition

**Status:** Done

## User Story
As a user,
I want to see a floating visual indicator when I am recording,
So that I know the application is listening without it stealing focus from my work.

## Story Context
**Existing System Integration:**
- Integrates with: `FloatingPanelManager` (AppKit integration).
- Technology: SwiftUI, AppKit (NSPanel).
- Follows pattern: Focus-less floating windows.
- Touch points: `UI/HUD/`, `App/WindowManagement/`.

## Acceptance Criteria
**Functional Requirements:**
1. Toggling the hotkey shows/hides a pill-shaped floating window.
2. Window stays on top of all other windows (including full-screen apps).
3. Clicking the window or showing it does NOT steal keyboard focus from the active app.

**Integration Requirements:**
4. Integrates with the hotkey trigger from Story 1.1.
5. Window background uses standard macOS translucency (vibrancy).

**Quality Requirements:**
6. HUD positioning is consistent and avoids covering critical system UI (like the notch).
7. Animations for showing/hiding are smooth.

## Technical Notes
- **Integration Approach:** Use `NSPanel` with `.nonactivatingPanel` style and `.floating` level.
- **Key Constraints:** Must ensure accessibility remains unaffected.

## Definition of Done
- [x] Functional requirements met
- [x] Integration requirements verified
- [x] UI follows design specs (pill shape, translucency)
- [x] No focus stealing verified
