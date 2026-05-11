# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What is Monotask

An iOS 18+ SwiftUI app that surfaces one randomly-selected incomplete reminder at a time from a chosen Apple Reminders list. Built on EventKit with a post-it-on-gradient single-task UI.

## Build & Run

Requires Xcode 16+ and [xcodegen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`).

```bash
xcodegen generate          # regenerate Monotask.xcodeproj from project.yml
open Monotask.xcodeproj    # then Cmd+R on an iPhone simulator
```

After any `project.yml` edit, re-run `xcodegen generate` before building.

### Signing

Team ID lives in `Monotask/Config/MonotaskSigning.local.xcconfig` (gitignored). First `xcodegen generate` copies from the `.example` file. Replace `XXXXXXXXXX` with your 10-character Team ID.

### Tests

```bash
xcodegen generate
xcodebuild -scheme Monotask -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.1' test
```

List available simulators: `xcrun simctl list devices available`. Adjust `name` and `OS` to match an installed runtime.

## Architecture

**Pattern**: Single `@Observable` view model (`AppViewModel`) injected into the SwiftUI environment. No third-party dependencies.

### Data flow

```
MonotaskApp (@main)
  └─ AppViewModel (owns all state)
       ├─ RemindersService (protocol) ← EventKitRemindersService (device) / MockRemindersService (tests)
       ├─ SelectionStore (UserDefaults) ← persists chosen list ID + last focused reminder ID
       └─ UniformRandomTopLevelPolicy ← random selection with re-roll exclusion
```

### Phase state machine

`AppViewModel.phase` (`AppPhase` enum) drives `RootView`:

`bootstrapping` → `permissionDenied` | `listSetup` | `emptyList` | `focused`

- **bootstrapping**: Check/request EventKit full access, resolve persisted list.
- **permissionDenied**: `PermissionInstructionsView` (Open Settings / Try again).
- **listSetup**: `ListSetupView` — create default list or pick existing.
- **emptyList**: `EmptyListView` — prompt to add first task.
- **focused**: `TaskFocusView` + `PostItCard` — the main single-task screen.

### Key behaviors

- **Complete/trash with undo**: When pool has 2+ tasks, actions are deferred for 4 seconds with an undo toast (`pendingUndo`). Single-task pool commits immediately.
- **Add-task surfacing**: If pool was 0 or 1 when add started, focus the new task. If 2+, keep current focus.
- **Re-roll**: Excludes current task from random pick. If only one task exists, shows "only one task" alert.
- **External sync**: `EKEventStoreChanged` triggers pool reload so Reminders app edits stay in sync.
- **List resolution order**: Persisted list ID first, then a list matching `AppConfig.appName` ("Monotask").

### Source layout

| Directory | Purpose |
|---|---|
| `Monotask/App/` | `@main` entry point, `AppConfig` (centralized app name) |
| `Monotask/Models/` | `ReminderTask` — domain model wrapping `EKReminder` |
| `Monotask/Services/` | `RemindersService` protocol + EventKit/mock implementations |
| `Monotask/State/` | `AppViewModel` (all app state), `SelectionStore` (UserDefaults persistence) |
| `Monotask/Selection/` | `UniformRandomTopLevelPolicy` — random pick with exclusion |
| `Monotask/Views/` | All SwiftUI views |
| `Monotask/Resources/` | `DesignColors` (gradient + post-it palette), asset catalogs |
| `MonotaskTests/` | Unit tests (selection policy, selection store, view model) |

### Focus view UI layers

The `TaskFocusView` uses three control surfaces:

1. **Bottom icon strip** — safe-area row: re-roll, trash.
2. **Floating chrome** — positioned on/near the post-it card: complete (upper-left checkbox), edit (bottom-right pencil). These rotate with the card's tilt.
3. **List picker** — nav bar `ToolbarItem(.principal)` menu for switching lists.

### Testability

`RemindersService` is a protocol. Tests use `MockRemindersService` and `AppViewModel(skipInitialBootstrap: true)` to control the lifecycle. `UniformRandomTopLevelPolicy` accepts an injected `nextRandomUnit` closure for deterministic tests.

## Product docs

- **[docs/PLAN.md](docs/PLAN.md)** — architecture, state machine, locked decisions.
- **[docs/TASKS.md](docs/TASKS.md)** — implementation checklist and reality check.
- **[docs/ONBOARDING.md](docs/ONBOARDING.md)** — proposed first-run onboarding (not yet implemented).

## Conventions

- iOS 18+ only; uses `requestFullAccessToReminders`. Write-only access is treated as insufficient.
- No third-party dependencies. EventKit only.
- `xcodegen` (`project.yml`) is the source of truth for the Xcode project. The `.xcodeproj` is checked in for clone-and-open convenience but is regenerated.
- App name is centralized in `AppConfig.appName` (reads `CFBundleDisplayName` from Info.plist).
- `@MainActor` on the view model; all UI state mutations happen on main.
