# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

JustTags is a native macOS SwiftUI application for working with BER-TLV EMV tags (payment card protocol tags). It supports parsing, filtering, diffing, and inspecting EMV tag data from hex or base64 input.

## Swift Code Style

Prefer `== false` over `!` for boolean negation (e.g. `isLibrary == false` not `!isLibrary`).

## Build & Development

```bash
# Open in Xcode
xed .

# Build from command line
xcodebuild build -scheme JustTags

# Scan for unused code (requires periphery installed)
periphery scan
```

There are no automated tests — the project relies on manual testing via Xcode.

## Architecture

The app uses **MVVM with SwiftUI** and supports multiple simultaneous windows with native macOS tabbing.

### Central State

- `AppVM.swift` — Singleton managing all windows, repositories, and settings. Entry point for understanding global state.
- `JustTagsApp.swift` — `@main` app entry, sets up `WindowGroup` and injects `AppVM`.

### Window Types (`Utils/WindowType.swift`)

Three window types, each with its own VM and View:

1. **Main** (`Main/`) — Parse and explore tags from hex/base64 input. `MainVM` manages parsed tags, search/filter state, and selection. `TagParser.swift` wraps `SwiftyEMVTags`.

2. **Diff** (`Diff/`) — Compare two tag sets side-by-side. `DiffVM` + `Diff.swift` implement the comparison algorithm.

3. **Library** (`Library/`) — Read-only reference browser for known EMV tags.

### Key Subsystems

**Tag Display** (`TagRowView/`) — Modular views for rendering individual tags: `PlainTagView`, `ConstructedTagView`, `TagValueView`, etc.

**Details Panel** (`Details/`) — Shows full tag info, decoded bytes, tag mappings, and kernel info when a tag is selected.

**Settings** (`Settings/`) — Three tabs: Kernel Info, Tag Mappings, Key Bindings. Uses a pluggable custom resource system (`CustomResourceRepo.swift`, `KernelInfoRepo.swift`, `TagMappingResource.swift`).

**Persistence** (`Persistence/`) — JSON-based app state save/restore on quit/launch. Saves open windows and active tabs. Implemented as an `AppVM` extension.

**EMV Utilities** (`Utils/EMVTag/`) — Extensions on `SwiftyEMVTags` types for decoding (`EMVTagDecoding.swift`), search (`EMVTagSearch.swift`), and display helpers.

### External Dependencies

- `SwiftyEMVTags` — Core EMV tag decoding and metadata (primary domain library)
- `SwiftyBERTLV` — BER-TLV binary parsing

### Command-Line / URL Scheme

The app supports deep-linking via `justtags://main/<hex-or-base64>` for CLI integration (documented in README).
