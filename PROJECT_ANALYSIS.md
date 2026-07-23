# JustTags Project Analysis

## Executive Summary

JustTags is a focused native macOS utility for decoding and inspecting BER-TLV / EMV tag data. The product value is clear: it turns raw hex or base64 payloads into readable tag trees, offers a tag reference library, and supports side-by-side diffing for troubleshooting card flows.

The codebase is relatively small and understandable. The app is organized around three window types:

- Main parsing windows
- Diff windows
- A singleton library window

The current implementation builds successfully (`xcodebuild build -scheme JustTags`) and its unit test suite passes in full — 25 tests across 3 suites via `xcodebuild test -scheme JustTags` — verified on July 23, 2026.

This is a follow-up to an earlier review. Every issue that review verified — deep linking, diff input, persistence, library reactivity, and destructive-action confirmation — has since been fixed, and a real unit test suite now exists where there was none before. The findings below are narrower and lower-severity than last time.

The strongest parts of the project are:

- A practical, domain-specific feature set that keeps growing: tag/subtag creation, hex/ASCII/mapped-value/bit-level editing, and AID/Kernel-ID-based kernel auto-selection have all landed since the last pass
- Good use of native macOS multiwindow affordances, now with full state restoration across main, diff, and library windows
- Clear separation between parsing, diffing, library browsing, settings, and persistence
- Reuse of `SwiftyEMVTags` / `SwiftyBERTLV` instead of reimplementing the EMV domain layer
- A real, passing unit test suite covering the highest-risk pure logic (input parsing, diffing, state round-tripping)
- Reactive library data and confirmed destructive actions, both open problems last time

The biggest remaining weaknesses are:

- Two force-unwraps of `AppVM.shared.tagDecoder!` are still a crash risk around the library window's setup
- The main window detail pane still uses a manual `HStack` layout rather than a native split/inspector pattern — notably, an inspector-based rework was already tried once and rolled back
- Window/tab bookkeeping in `AppVM` is still manual array management (`mainVMs`/`diffVMs`, pruned and indexed by hand) rather than scene-owned state
- Test coverage, while real now, doesn't yet reach search behavior or URL/deep-link routing
- App state is still persisted to the Documents folder rather than Application Support

## Functional Overview

### 1. Main Parsing Flow

The main window parses EMV tags from pasted hex or base64 input and renders them as a browsable, editable tree.

Primary capabilities:

- Paste TLV data into a parsing tab
- Decode BER-TLV structures through `InputParser` and `TagParser`
- Show nested constructed tags
- Search by tag id, name, and description
- Select one or more tags
- Copy selected tags back as hex
- Open tag details in a side panel
- Add new top-level tags (toolbar "Add Tag" popover) and new subtags on constructed tags (inline "add subtag" action)
- Edit tag/subtag values: raw hex, ASCII, individual bits, bit-groups via an enum picker, and known mapped values
- Remove tags and subtags from the parsed list, with an edited-tag indicator shown in the list
- Open a tag in its own window from the row's context menu
- Auto-select applicable kernels based on AID and Kernel ID tags found in the parsed data; kernels added manually stay selected through auto-detection instead of being overridden
- Toggle individual decoded bits for supported tags

Key files:

- `JustTags/Main/MainVM.swift`
- `JustTags/Main/MainView.swift`
- `JustTags/Main/TagParser.swift`
- `JustTags/TagRowView/` (including `AddTagView.swift` for tag/subtag creation)
- `JustTags/Details/`

### 2. Diff Flow

The diff window compares two parsed tag lists and highlights changes.

Primary capabilities:

- Paste two inputs, one per side (manual typing was removed in favor of an explicit "Paste from Clipboard" action per column — see Resolved Issues)
- Parse and normalize each side
- Diff sibling tags with `Diff.diff(...)`
- Flip left/right sides
- Filter to only differing tags
- Reuse the same kernel-selection mechanism as the main flow

Key files:

- `JustTags/Diff/DiffVM.swift`
- `JustTags/Diff/DiffView.swift`
- `JustTags/Diff/Diff.swift`
- `JustTags/DiffedTagRowView/`

### 3. Library Flow

The library is a read-only reference browser for known EMV tags and kernels, plus an interactive decoder for sample values.

Primary capabilities:

- Browse tags by kernel
- Search tag metadata
- Inspect tag definitions and mappings
- Enter sample bytes to decode known tag values interactively, including bit- and bit-group-level editing of the sample value
- Move through search results with arrow-key shortcuts
- Rebuild automatically when custom resources change in Settings, instead of requiring the window to be reopened to see new kernels/mappings

Key files:

- `JustTags/Library/LibraryVM.swift`
- `JustTags/Library/LibraryView.swift`
- `JustTags/Library/LibraryKernelInfoView.swift`

### 4. Settings and Custom Resources

The app lets users extend decoder behavior with custom kernel info and tag mappings.

Primary capabilities:

- Import JSON resources
- Delete individual resources, behind a confirmation dialog
- Clear all imported resources, behind a confirmation dialog
- Review keyboard shortcuts

Key files:

- `JustTags/Settings/SettingsView.swift`
- `JustTags/Settings/Resources/CustomResourceRepo.swift`
- `JustTags/Settings/Resources/CustomResourceListView.swift`
- `JustTags/Settings/Shortcuts/`

### 5. App-Level UX

The app also supports:

- Multiple windows and native tabbing
- Full state restoration on relaunch: main tabs, diff windows, and the library window are all persisted, along with which window/tab was active
- Custom URL scheme support: `justtags://main/...`, now reliably routed into an empty existing tab or a fresh one
- Release notes and "What's New"

Key files:

- `JustTags/JustTagsApp.swift`
- `JustTags/AppVM.swift`
- `JustTags/Persistence/`
- `JustTags/Main/MainViewCommands.swift`
- `JustTags/Updates/`

### 6. Automated Tests

Contrary to the previous pass — and to `CLAUDE.md`/`AGENTS.md`, which still say "there are no automated tests" — the project now has a real unit test suite using Swift Testing, run via the `JustTags` scheme's test action:

- `JustTagsTests/InputParserTests.swift` — hex/base64 parsing, malformed input
- `JustTagsTests/DiffTests.swift` — byte-level compare and `Diff.diff` normalization
- `JustTagsTests/AppStateTests.swift` — `AppState` round-tripping and backward-compatible decoding of older saved state

25 tests across 3 suites, all passing as of this review. Not yet covered: search/filter behavior and URL deep-link routing (see Improvement Suggestions). Worth updating `CLAUDE.md`/`AGENTS.md` to stop saying there are no automated tests.

## Architecture Assessment

### What is working well

- The codebase has meaningful feature folders, so the app is easy to navigate.
- Window-specific view models are separated from the app-level coordinator.
- Parsing logic is mostly kept out of views.
- The domain model from external packages is reused consistently.
- Focused values are used to drive commands based on the active window.
- `LibraryVM` is now reactive: it subscribes to `tagParser.objectWillChange` and rebuilds kernels, mappings, decodable-tag sets, and search indices when resources change, preserving the current selection across the rebuild.
- Persistence now round-trips the full picture — main tabs, diff windows, library state, and which window was active — with backward-compatible decoding of older saved state, and it's covered by tests.
- Direct `AppVM.shared` access is now rare: six call sites in the whole app, and all but two are either the composition root (`JustTagsApp.swift`) or `#Preview`/`PreviewProvider` code. The two production exceptions are the library window building its own `TagParser` from `AppVM.shared.tagDecoder!`, and `LibraryVM` registering itself back onto `AppVM.shared.libraryVM`.

### Architectural tradeoffs

The app is structurally closer to "central coordinator + per-window VMs" than a pure SwiftUI scene-owned model. That is reasonable for a utility app with multiple windows, but it comes with some remaining costs:

- Window creation/restoration is still manual bookkeeping: `AppVM` tracks `mainVMs`/`diffVMs` as arrays it prunes and indexes into (`activateRestoredWindow`, `vmIdToOpen`), rather than scenes owning their own identity.
- A couple of flows still reach for imperative AppKit alerts instead of SwiftUI-native state — renaming a tab builds an `NSAlert` with an embedded `NSTextField` (`MainViewCommands.renameTab()`), and `AppVM` uses `NSAlert` elsewhere too.
- `@SceneStorage` is currently used nowhere in the app. It was briefly introduced for the main window's `showsDetails` alongside an inspector-based rework, then removed again in the same revert (see below) — so this is back to being fully open.

### SwiftUI/macOS skill perspective

From a native macOS SwiftUI point of view, the app already has good instincts:

- separate scenes
- menu commands
- multiwindow support
- sidebar/detail thinking in the library

Worth calling out explicitly: the team already tried the modern approach for the main window's detail pane. In late April 2026 it was rebuilt around `.inspector(isPresented:)` with `@SceneStorage`-backed persistence ("Modernize main view inspector restoration"), then rolled back about three weeks later to the original inline `HStack` layout, while deliberately keeping the `showsDetails` persistence behavior ("Revert inspector panel in favour of inline details view"). The commit history doesn't record why it was rolled back. That matters for how the next suggestion should land: this isn't an untried idea, and repeating it without knowing what went wrong last time would likely just reproduce the same outcome.

## Resolved Issues

Every issue verified in the previous pass has since been fixed:

### ~~1. Deep links do not reliably open in the main parsing flow~~ ✓ Fixed

### ~~2. Diff text entry is effectively broken for manual typing~~ ✓ Fixed

### ~~3. Persistence does not restore the full app state it claims to track~~ ✓ Fixed

### ~~4. Library content is snapshot-based and does not react to runtime resource changes~~ ✓ Fixed

### ~~5. Destructive resource actions have no confirmation or undo~~ ✓ Fixed (confirmation dialogs shipped; there is still no undo path — tracked as a suggestion below)

## Additional Technical Risks

These are not immediate bugs, but they are worth tracking:

- `AppVM.shared.tagDecoder!` is still force-unwrapped in two places (`JustTagsApp.swift`, `LibraryView.swift`), both while constructing the library window's own `TagParser`. This remains a crash point around initialization and previews if that ever becomes `nil`.
- `MainView` still uses a manual `HStack` detail pane rather than a native split/inspector pattern (see the inspector attempt-and-revert discussed above).
- State restoration is still stored in Documents as `state.data`, which is unusual for app-internal UI state; Application Support remains a better long-term location. Unchanged since the last pass.
- A few hidden, zero-sized buttons exist purely to own keyboard shortcuts (the search shortcut in `MainView.swift` and `LibraryView.swift`, the "only diff" shortcut in `DiffView.swift`) — functional, but a workaround rather than explicit command/menu ownership.

## Improvement Suggestions

Suggestions that are now fully done — making the library reactive, redesigning diff input, expanding state restoration to cover diff/library/active-window — have been dropped rather than left in as stale recommendations. What's left is renumbered below.

### 1. Finish reducing singleton coupling in the last few spots

Recommended direction:

- Give the library window its `TagDecoder`/`TagParser` through the same dependency path the main and diff windows already use, instead of reaching into `AppVM.shared.tagDecoder!` directly.
- Replace the two remaining force-unwraps with a non-optional dependency or an explicit startup failure path.

Why:

This is now a small, well-scoped cleanup rather than a broad architectural change — most of the singleton surface flagged last time is already gone.

### 2. Move per-window UI state to `@SceneStorage`

Good candidates, unchanged from last time:

- current search text
- selected tag id
- expanded constructed tags
- diff filter mode
- library split visibility / current selection

Why:

This is still the most native macOS SwiftUI way to preserve transient window state, and it's currently unused anywhere in the app — it was added once for `showsDetails`, then removed along with the inspector revert.

### 3. Revisit the main parser detail pane only with a specific hypothesis in hand

Recommended direction:

- Before trying `.inspector` or `NavigationSplitView` again, pin down concretely what made the previous attempt worse — layout jumpiness, focus loss, popover placement, or something else not visible from the commit history alone.
- If a specific problem can be identified, a narrower second attempt may still be worthwhile; simply repeating the same broad rework is not.

Why:

This exact rework was already attempted and reverted in this codebase (April–May 2026). Recommending it again without addressing why it failed the first time would likely just reproduce the same outcome.

### 4. Add an undo path for destructive resource actions

Recommended direction:

- Confirmation dialogs now guard delete and clear-all; a lightweight undo (`UndoManager`, or a "resource deleted" toast with restore) would cover the remaining case of an intentional-then-regretted delete.

Why:

Confirmation prevents accidental loss but doesn't recover from a deliberate delete the user changes their mind about. Low cost given the resource list is already small and in-memory.

### 5. Extend test coverage to search and URL routing

Recommended direction:

- `InputParser`, diff normalization, and persistence encode/decode are now covered by `JustTagsTests`.
- Add tests for `MainVM`/`LibraryVM` search filtering and ranking, and for `AppVM.openMainDeepLink` (marker parsing, reuse-empty-tab-vs-create-new-tab behavior, percent-encoding).

Why:

These were the highest-value targets called out last time; they're the two pieces of logic still untested now that the rest of the list has been picked up.

### 6. Keep modernizing visual structure

Recommended direction:

- Replace the remaining hidden zero-sized shortcut buttons with explicit command/menu ownership.
- Replace the `NSAlert`-based tab rename flow with a SwiftUI-native alternative (e.g. an alert/sheet with a bound `TextField`).
- Continue the cleanup already underway (`foregroundStyle` throughout, `HintView` simplification, RFU rendering, mapping-picker popover sizing).

Why:

Smaller version of the same suggestion from last time — a good portion of it has already landed.

## Suggested Priorities

### Priority 1

- Replace the two `tagDecoder!` force-unwraps with a safer dependency path
- Move the persisted state file from Documents to Application Support

### Priority 2

- Extend tests to search behavior and deep-link routing
- Replace the `NSAlert` rename-tab flow and the hidden zero-sized shortcut buttons with SwiftUI-native equivalents
- Add an undo path for destructive resource actions

### Priority 3

- Adopt `@SceneStorage` for transient per-window UI state
- Finish reducing the library window's direct `AppVM.shared` touch points
- Only revisit the inspector/split-view rework once there's a specific fix in mind, not as a repeat attempt of what was already rolled back

## Closing Assessment

JustTags has moved a full step since the last review: every previously verified bug is fixed, the library is reactive, persistence is complete, destructive actions are confirmed, and a real test suite now backs the highest-risk logic. It reads today as a polished, dependable Mac tool rather than merely "useful and well-scoped" — the remaining items are narrow, well-understood cleanups (two force-unwraps, a persistence file location, a couple of AppKit-flavored UI workarounds) rather than open architectural questions.

The one place to be deliberate rather than reflexive is the main window's detail pane: a native inspector rework was already tried and rolled back, so the next move there should start from a specific diagnosis, not a repeat of the same experiment.
