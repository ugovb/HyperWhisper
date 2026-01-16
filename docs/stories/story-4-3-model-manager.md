# Story 4.3: Model Manager - Brownfield Addition

**Status:** Ready for Review

## User Story
As a user,
I want the app to handle downloading the large model weights for me,
So that I don't have to manually download and move files.

## Story Context
**Existing System Integration:**
- Integrates with: `ModelLoader`, HuggingFace.
- Technology: `URLSessionDownloadTask`, `FileManager`.
- Follows pattern: Background download with progress.
- Touch points: `Services/Transcription/ModelManager.swift`.

## Acceptance Criteria
**Functional Requirements:**
1. **Model Registry:** Maintain a registry of supported models:
   ```json
   [
     { "id": "parakeet-0.6b", "url": "hf.co/nvidia/parakeet-tdt-0.6b/...", "size": "1.2GB" },
     { "id": "llama-3-8b-4bit", "url": "hf.co/mlx-community/Llama-3-8B-4bit/...", "size": "4.8GB" }
   ]
   ```
2. **Download Management:** Track `progress`, `status` (.notDownloaded, .downloading, .downloaded), and `localPath`.
3. **Integrity Check:** Verify file size or checksum after download completion.
4. **Resumable Downloads:** Use `downloadTask(withResumeData:)` to handle network drops.

**Integration Requirements:**
5. Exposes `@Published` properties for the Dashboard UI (Story 4.2).

**Quality Requirements:**
6. **Background Execution:** Downloads continue even if the HUD/Dashboard window is closed.
7. **Storage Warning:** Check for at least 10GB free space before starting a large LLM download.

## Technical Notes
- **Storage Location:** `~/Library/Application Support/HyperWhisper/models/`.
- **UX:** Play a subtle sound or show a notification when a multi-GB download completes.

## Tasks / Subtasks
- [x] Task 1: Define `ModelDownload` struct and hardcoded Model Registry (AC: #1).
- [x] Task 2: Implement `ModelManager` class (Observable) with `startDownload`, `pause`, `cancel` logic using `URLSession` (AC: #2, #4).
- [x] Task 3: Implement file system checks (Free space > 10GB) and verification logic (AC: #3, #7).
- [x] Task 4: Connect `ModelManager` to `ModelsView` (Story 4.2) for UI updates (AC: #5).
- [x] Task 5: Ensure downloaded models are accessible to `ModelLoader` (AC: #6).
- [x] Task 6: Implement completion notification/sound (AC: #6).

## Dev Agent Record
### Agent Model Used
Gemini 2.0 Flash

### Debug Log References
- Resolved `Sendable` conformance issues for `ModelDownloadInfo` and `DownloadStatus`.
- Added missing `AppKit` import for `NSSound` in `ModelManager`.

### Completion Notes List
- Implemented `ModelManager` using `URLSession` background configuration.
- Created `DownloadState` structures conforming to `Sendable`.
- Updated `ModelsView` to reflect real-time download status.
- Added disk space check (10GB threshold) before starting downloads.

### File List
- docs/stories/story-4-3-model-manager.md
- Sources/HyperWhisper/Services/Transcription/ModelManager.swift
- Sources/HyperWhisper/UI/Dashboard/ModelsView.swift
- Sources/HyperWhisper/Models/DownloadState.swift

### Change Log
| Date | Version | Description | Author |
| :--- | :--- | :--- | :--- |
| 2026-01-11 | 1.0 | Initialized story tasks | James (Dev Agent) |
| 2026-01-11 | 1.1 | Implemented Model Manager and UI | James (Dev Agent) |

## Definition of Done
- [x] At least one model downloaded and verified via the Manager.
- [x] UI correctly reflects real-time download percentage.
- [x] Downloaded models are correctly placed for `ModelLoader` to find.