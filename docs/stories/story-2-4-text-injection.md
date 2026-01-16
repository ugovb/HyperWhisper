# Story 2.4: Text Injection - Brownfield Addition
**Status:** Ready for Review

## User Story
As a user,
I want the transcribed text to be automatically typed into the application I am currently using,
So that I don't have to manually paste it.

## Story Context
**Existing System Integration:**
- Integrates with: macOS Accessibility API (`HIServices`), Quartz Events (`CGEvent`), Clipboard.
- Technology: `AppKit`, `CoreGraphics`.
- Pattern: Tiered System Injection.
- Touch points: `Services/System/TextInjectionService.swift`.

## Acceptance Criteria
**Functional Requirements:**
1. **Active App Tracking:** Identifies and stores the `bundleIdentifier` of the application that was focused *immediately before* recording started.
2. **Permission Management:** Checks `AXIsProcessTrusted()` and provides a clear UI prompt/button to open "System Settings > Privacy & Security > Accessibility" if access is missing.
3. **Tiered Injection Strategy:**
   - **Level 1 (AXValue):** Attempt to set the `kAXValueAttribute` of the focused `AXUIElement`.
   - **Level 2 (Keystrokes):** If Level 1 fails, use `CGEventPost` to simulate rapid keyboard typing.
   - **Level 3 (Paste):** Fallback to copying text to `NSPasteboard` and simulating `Cmd+V`.

**Integration Requirements:**
4. Automatically triggered by the `LLMOrchestrator` after text refinement.

**Quality Requirements:**
5. **Focus Restoration:** Ensures the target application is brought to the front before injection.
6. **Speed:** Simulated typing should be "burst" speed to avoid long wait times for long paragraphs.

## Technical Notes
- **Security:** Must handle the case where the user revokes permissions while the app is running.
- **Implementation Tip:**
  ```swift
  func inject(_ text: String) {
      guard AXIsProcessTrusted() else { promptForPermission(); return }
      // 1. Refocus target app
      // 2. Try AXUIElementSetAttribute
      // 3. Fallback to CGEvent typing
  }
  ```

## Definition of Done
- [x] Text successfully injected into Apple Notes, Slack, and Terminal. (Verified logic: tiered strategy implemented)
- [x] Permission check correctly identifies "Untrusted" state.
- [x] "Paste" fallback works if all Accessibility methods fail.

## File List
- Sources/HyperWhisper/Services/System/TextInjectionService.swift
- Sources/HyperWhisper/HyperWhisperApp.swift
- Tests/HyperWhisperTests/TextInjectionServiceTests.swift