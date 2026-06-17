# AlfredMini

A lightweight macOS clipboard manager built with SwiftUI + AppKit.

AlfredMini lives in the menu bar, tracks clipboard history, and lets you search/pin/paste quickly with a keyboard-first workflow.

## Features
- Menu bar app (`LSUIElement`) with no Dock icon.
- Automatic text clipboard capture.
- Fuzzy search over clipboard history.
- Two sort tabs:
  - `Recent`: unpinned items sorted by most recent activity.
  - `Frequent`: pinned items first, then most-used items.
- Pin/unpin snippets for quick access.
- One-key paste workflow into the previously active app.
- Configurable global shortcuts and retention limit.

## Requirements
- macOS 13.0+
- Xcode 15+ (or newer)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

## Build And Run
```bash
# from repo root
xcodegen generate
xcodebuild -scheme AlfredMini -configuration Debug build
```

Daily development flow:
1. Open `AlfredMini.xcodeproj`.
2. Run with `Cmd+R`.

## Create DMG
```bash
./scripts/build_dmg.sh
```

## Keyboard Shortcuts
Global defaults:
- Show Search: `Command + J`
- Quick Pin current clipboard: `Control + Option + S`

Inside search panel:
- Select item: `Enter`
- Pin/unpin selected: `Command + Enter`
- Move selection: `Up/Down`
- Quick paste item 1..9: `Command + 1..9`
- Toggle sort tab: `Tab`
- Close panel: `Esc`

You can customize global shortcuts in Preferences.

## Permissions
AlfredMini requests Accessibility permission to:
- Listen for global shortcuts.
- Simulate paste (`Cmd+V`) into other apps.

Grant in:
`System Settings -> Privacy & Security -> Accessibility`

Note:
- App Sandbox is disabled by design for these capabilities.

## Architecture (High Level)
- `AppDelegate` wires core components on launch:
  - `StatusBarController`
  - `ShortcutsManager`
  - `ClipboardMonitor`
- `ClipboardMonitor` polls `NSPasteboard` and forwards text to `ClipboardStore`.
- `ClipboardStore` manages:
  - transient in-memory items
  - persisted Core Data items (`ClipboardItemMO`)
- `SearchPanelView` reads from `ClipboardStore`, applies fuzzy search, and triggers paste via `PasteHelper`.

## Project Notes
- Xcode project is generated from `project.yml`.
- Do not hand-edit `.xcodeproj`; regenerate with `xcodegen generate` after config changes.
- Current SPM dependency: `KeyboardShortcuts` by Sindre Sorhus.
- There are currently no automated tests.

## License
MIT
