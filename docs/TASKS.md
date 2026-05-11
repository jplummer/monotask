# Monotask — task list

Use this file to track what to build next.

Status for **what is already true in the repo** lives under [Reality check](#reality-check-plan-vs-code) (**Done** / **Partial** / **Not started**). Later sections use `- [ ]` only for concrete checklist items.

Links: [Product plan](PLAN.md) · [Onboarding spec](ONBOARDING.md) · [README](../README.md)

---

## Reality check (plan vs code)

Snapshot of the repo **today** so PLAN/TASKS stay honest. Update this section when behavior shifts.

### Done (matches plan)

- **Core loop**: EventKit full-access path, pool fetch, random selection + re-roll exclusion, complete, trash, inline edit on post-it, add sheet, empty list, list setup, persisted list + reminder ids (`SelectionStore`).
- **Complete / trash UX**: When the pool has **two or more** tasks, complete and trash **defer** sending to EventKit for a short window and show a **post-action toast with Undo** (`AppViewModel.beginComplete`, `beginDelete`, `pendingUndo`, `TaskFocusView`). No separate confirmation alert — undo covers mistaken taps. When only **one** task remains, complete/trash **commit immediately** (nothing to rotate to during an undo window).
- **Add feedback**: Brief **“Task added.”** toast after a successful add (`showTaskAddedToast`).
- **Phases**: `AppPhase` and `RootView` switch (`bootstrapping`, `permissionDenied`, `listSetup`, `emptyList`, `focused`).
- **Permission denial UI**: `PermissionInstructionsView` with Open Settings / Try again.
- **Write-only / denied**: Routed per `AppViewModel.bootstrap` and Reminders authorization.
- **Only-one-task alert**: Implemented with add / dismiss paths.
- **External changes**: `EKEventStoreChanged` subscription reloads pool/focus.
- **Tests**: 61 tests across 9 groups covering bootstrap phases, undo/defer, reroll, edit, list switching, add edge cases, external changes, SelectionStore, and sections guard. All passing.
- **xcodegen**: `project.yml`, signing xcconfig pattern, README workflow.

### Partial (implemented but thin or needs a dedicated pass)

- **Errors**: `userMessage` + generic **Notice** alert in `RootView` — works, but not inline/recoverable UX everywhere.
- **Accessibility**: Some labels exist (e.g. list menu, focus controls); a **full VoiceOver / Dynamic Type / hit-target audit** is still required (see [Suggested implementation order](#suggested-implementation-order)).
- **RootView**: `.animation(.default, value: phase)` exists; dedicated phase transitions remain polish-tier.
- **Permission copy**: `PermissionInstructionsView` is usable; refinement bullets below remain.
- **Instrumentation**: No **daily-use** or product analytics wired yet (sessions, core actions, retention signals — provider TBD). Onboarding funnel events in [ONBOARDING.md](ONBOARDING.md) are spec-only until implemented.

### Focus UI terminology (vs older TASKS wording)

Earlier drafts described controls as an **“action row”** or generic **toolbar** in one horizontal band. The shipped focus screen uses two layers:

1. **Bottom icon strip** — full-width row at the safe area bottom: **re-roll**, **add**, **trash** (`TaskFocusView.bottomIconStrip`).
2. **Floating chrome** — controls positioned relative to the square post-it: **edit** (upper-right of the card’s frame) and **complete** (lower-right on the card). These are not in the bottom strip.

The navigation bar still hosts the **list picker** (`ToolbarItem` / principal); that is separate from the strip and floating chrome. When editing here, prefer **bottom strip**, **floating chrome**, and **list picker (nav bar)** so the layout stays unambiguous.

### Not started

- **Branding & visual identity** — Direction for **app icon**, gradient/post-it **personality**, and overall tone **before** splash and onboarding so first-run screens match the product (good candidate for a **competitive multi-agent** exploration: parallel moodboards / icon directions, then converge).
- **Splash / launch shell**: Not in the main app path yet.
- **First-run onboarding** (welcome + education **before** system prompt): Spec in [ONBOARDING.md](ONBOARDING.md); main branch still starts `bootstrap` without those screens.
- **Performance pass** (intentional optimization pass): Not done as a tracked pass; opportunistic tweaks only so far.
- **App icon in Assets**: `project.yml` may still omit a filled **App Icon** set until branding is decided.
- **App Store artifacts**: Screenshots, listing copy, privacy answers — **last**, after UI and branding stabilize ([App Store and marketing assets](#app-store-and-marketing-assets)).
- **Sections smoke test**: Unknown whether EventKit exposes section headers as `EKReminder` objects. See [Sections smoke test](#sections-smoke-test) — a quick manual check before any sections-aware work.

---

## Suggested implementation order

Prioritize **identity and observability**, then **inclusive UX**, then **first-run flows**, then **speed**, then **distribution**.

1. **Branding & visual identity** — Lock icon direction, palette/post-it character, and voice **before** splash and onboarding so those screens feel intentional. Optional: run **multiple agents or designers in parallel** on competing directions, then pick one.
2. ~~**Test coverage pass**~~ — **Done.** 61 tests; all passing. See [Test coverage pass](#test-coverage-pass-).
3. **Daily-use instrumentation** — Wire **core events** for real usage (opens, completes, deletes, undo usage, list switches, errors) so you can iterate before and after launch. Choose provider (TelemetryDeck, PostHog, OSLog-only, etc.) and privacy stance; onboarding funnel events can share the same pipe later.
4. **Full accessibility pass** — VoiceOver order and labels, Dynamic Type through **large** sizes, Reduce Motion, contrast and tap targets on **bottom strip**, **floating chrome**, sheets, and empty/setup flows.
5. **Splash + first-run onboarding** — After branding; short launch shell; education per [ONBOARDING.md](ONBOARDING.md); defer `bootstrap` / `start()` until after onboarding when applicable so the Reminders prompt is not the first screen.
6. **Performance pass** — Profile focus view, post-it, list loads; coalesce or debounce `EKEventStoreChanged` if reloads stack; trim redundant layout/animation cost (see [Performance pass](#performance-pass)).
7. **Ship-ready polish** — Error UX improvements, scene lifecycle (background / Settings / Reminders edits), small-phone and dark/light passes (can overlap step 4).
8. **View refinement** — Typography, haptics, tokens ([View and behavior refinement](#view-and-behavior-refinement)); ongoing.
9. **App Store and marketing assets** — **Last**: screenshots, copy, privacy questionnaire, support URL after UI and icon settle ([App Store and marketing assets](#app-store-and-marketing-assets)).
10. **Deferred roadmap** — [Deferred](#deferred--roadmap) when expanding scope.

---

## Branding & visual identity

Do **before** splash/onboarding and before treating App Icon / screenshots as final.

- [ ] Define **icon** concept (metaphor, silhouette, dark/light).
- [ ] Align **gradient + post-it** with personality (calm, playful, minimal — pick and execute).
- [ ] Optional: **multi-agent / parallel exploration** of 2–3 directions, then merge winners into one system.

---

## Test coverage pass ✅

**Complete.** 61 tests across 9 groups; all passing. The mock supports error injection via `setCreateListError(_:)` and `setAuthorization(_:)`; `AppViewModel.init` accepts `undoDelay:` for fast timer tests.

### Group 1 — Bootstrap / permission state machine (`AppViewModelBootstrapTests`)

- [x] **`fullAccess` + persisted list + non-empty pool → `.focused`**
- [x] **`fullAccess` + persisted list not found, name-match fallback → `.focused`**
- [x] **`fullAccess` + no persisted list, no name match → `.listSetup`**
- [x] **`denied` → `.permissionDenied`**
- [x] **`writeOnly` → `.permissionDenied`**
- [x] **`undetermined` → grant access → `.focused`**
- [x] **`fullAccess` + empty pool → `.emptyList`**
- [x] **`fetchIncompleteTopLevel` throws during load → `userMessage` set, phase → `.listSetup`**
- [x] **`refreshAfterSettings` while denied → still `.permissionDenied`**

### Group 2 — Complete / delete with undo window (`AppViewModelUndoTests`)

- [x] **`beginComplete` pool ≥ 2 → task absent from pool, `pendingUndo` = `.completion`, phase still `.focused`**
- [x] **`beginDelete` pool ≥ 2 → task absent from pool, `pendingUndo` = `.deletion`, phase still `.focused`**
- [x] **Undo complete → task restored to pool, mock not mutated, `pendingUndo` nil**
- [x] **Undo delete → task restored to pool, mock not mutated, `pendingUndo` nil**
- [x] **Timer fires → action committed to mock**
- [x] **`beginComplete` pool = 1 → immediate commit, `pendingUndo` stays nil, phase → `.emptyList`**
- [x] **`beginDelete` pool = 1 → immediate commit, `pendingUndo` stays nil, phase → `.emptyList`**
- [x] **Rapid second action commits first**
- [x] **External change during undo window → pending task still filtered from reloaded pool**
- [x] **`completeReminder` throws after timer fires → `userMessage` set**
- [x] **`deleteReminder` throws after timer fires → `userMessage` set**

### Group 3 — Reroll (`AppViewModelRerollTests`)

- [x] **Reroll pool ≥ 2 → `currentTask` changes, `selectionStore.selectedReminderIdentifier` updates**
- [x] **Reroll pool = 1 → same task kept, `showOnlyOneTaskAlert` = true**

### Group 4 — Edit (`AppViewModelEditTests`)

- [x] **`confirmEdit` valid → `currentTask` title/notes updated, mock store reflects change**
- [x] **`confirmEdit` blank title → no-op, mock not called**
- [x] **`confirmEdit` whitespace-only title → no-op**
- [x] **`confirmEdit` throws → `userMessage` set, `currentTask` unchanged**

### Group 5 — List switching (`AppViewModelListTests`)

- [x] **`applyListChoice` → `activeListSummary` updates, pool reloads from new list, `selectionStore` list ID updated**
- [x] **`applyListChoice` → reminder selection cleared when switching to a different list**
- [x] **`createReminderList` → new calendar created in mock, VM switches to it, pool is empty, phase → `.emptyList`**
- [x] **`createReminderList` blank name → no-op**
- [x] **`createReminderList` throws → `userMessage` set**
- [x] **`openListSetup` → phase → `.listSetup`**

### Group 6 — Add edge cases (`AppViewModelAddTests`)

- [x] **Add pool = 0 (`addFromEmpty`) → focuses new task**
- [x] **`confirmAdd` blank title → no-op, sheet stays open**
- [x] **`confirmAdd` whitespace-only title → no-op**
- [x] **`confirmAdd` throws → `userMessage` set, `showAddSheet` stays true**
- [x] **`cancelAdd` → `showAddSheet` = false**
- [x] **`showTaskAddedToast` set to true after successful add**

### Group 7 — External change reload (`AppViewModelExternalChangeTests`)

- [x] **Change fired while `.focused` → pool reloads, `currentTask` updated if data changed**
- [x] **Change fired while `activeListSummary` is nil → ignored (no crash)**
- [x] **Change fired while permission is not `.fullAccess` → ignored**

### Group 8 — `SelectionStore` (`SelectionStoreTests`)

- [x] **Initial state is all nil**
- [x] **`clearReminderSelection` preserves list ID**
- [x] **`clearAll` resets both fields to nil**
- [x] **Two separate instances on the same suite share state**
- [x] **Overwrite list ID persists**

### Group 9 — Sections regression guard (`AppViewModelSectionsTests`)

- [x] **Pool containing section-header-shaped tasks → `.focused`, no crash**

---

## Daily-use instrumentation

Goal: understand **real** usage patterns (not only onboarding drop-off).

- [ ] Choose **transport** (hosted analytics, first-party, or logging-only) and document retention / PII rules.
- [ ] Emit **core events**: app foreground, focus session, complete, delete, undo tap, re-roll, add success, list change, permission outcome, critical errors.
- [ ] Optional: **dashboards** or weekly export for iteration.

Onboarding-specific events remain specified in [ONBOARDING.md](ONBOARDING.md) and can be wired alongside or after the core set.

---

## First-run onboarding

Spec: **[ONBOARDING.md](ONBOARDING.md)**. Implement **after** [branding](#branding--visual-identity) so copy and visuals match the product.

- [ ] **Splash / launch shell** ahead of onboarding and main.
- [ ] Welcome + Reminders explanation (+ optional soft gate) **before** calling full-access request.
- [ ] Wire analytics / logging per [Instrumentation hooks](ONBOARDING.md#instrumentation-hooks) (same provider as [daily-use instrumentation](#daily-use-instrumentation) when possible).
- [ ] Keep **PermissionInstructionsView** (or successor) for deny / write-only recovery after OS prompt.
- [ ] Update PLAN state machine diagram if the permission **subgraph** gains new nodes.

---

## Performance pass

Run as a **dedicated** pass after core UX and flows feel stable; technical spikes can happen earlier on branches.

- [ ] **Reminders / EventKit**: Coalesce rapid store-change notifications if reloads stack; avoid redundant full pool fetches.
- [ ] **Rendering**: Audit `PostItCard` / `TaskFocusView` for expensive shadows, stacked layers, and animation modifiers that relayout every frame.
- [ ] **Navigation / phases**: Avoid animating the entire tree when only a subview should change.
- [ ] **Instruments**: Time main thread during launch, list switch, complete/delete, and background return; fix surprise synchronous work on the main actor.

---

## Ship-ready — current functionality

Tighten what exists so the app holds up as a **daily driver** (alongside the dedicated [accessibility](#suggested-implementation-order) pass).

- **Error UX**: Replace or supplement generic `userMessage` alerts with **inline / recoverable** messaging where it helps (e.g. save failures on add/edit).
- **Scene lifecycle**: Confirm behavior when returning from **background** / **Settings** (permission changes, list edits in Reminders) and fix stale UI edge cases.
- **Device matrix**: Run on **small phone**, **large phone**, and **dark/light** (toolbar, sheet detents, gradient safe areas, **bottom strip** + **floating chrome**).

Complete/trash are covered by **undo toasts** when the pool has 2+ tasks; no separate destructive confirmation is planned.

---

## App Store and marketing assets

**Last** in the sequence: depends on stable UI, **branding**, and **App Icon**.

- [ ] **App icon**: Full **Asset Catalog** icon set; set `ASSETCATALOG_COMPILER_APPICON_NAME` in `project.yml` / target when the branding set is ready.
- [ ] **Screenshots**: Required sizes per App Store Connect; dark and light if differentiated.
- [ ] **App Store copy**: Subtitle, description, keywords, **what’s new** template; align with Reminders positioning and privacy reality.
- [ ] **Privacy**: App Privacy questionnaire; **Privacy Policy URL** if required.
- [ ] **Support / marketing URLs**: Support URL, optional marketing site.
- [ ] **App Review**: Notes if permission flow or Reminders access needs reviewer context.

---

## View and behavior refinement

Polish each surface: layout, copy, motion, and interaction consistency.

### `RootView`

- Smoother **phase transitions** between bootstrapping, permission, setup, empty, and focused.
- Ensure **one alert at a time** if both `userMessage` and another modal could conflict.

### `PermissionInstructionsView`

- Tighten **copy** for clarity (full vs write-only access).
- Optional: short **bullet list** mirroring Settings path on current iOS version.

### `ListSetupView`

- Clarify labels when **no other lists** exist vs many lists (helper text).
- Consider **default selection** when switching lists (first item vs last-used).
- Loading overlay: ensure it cannot **double-submit** create/use actions.

### `TaskFocusView` + `PostItCard`

- **Typography**: Title vs notes hierarchy; max readable width on large phones.
- **Bottom strip** (re-roll, add, trash): spacing, tap targets; optional **ScrollView** if Dynamic Type grows content beyond one screen.
- **Floating chrome** (edit, complete on/near the card): alignment and discoverability with Reduce Motion.
- **List picker** (nav bar): discoverability of the principal menu.
- **Toasts** (undo, task added): placement vs keyboard and safe area; optional haptic on undo commit.
- **Only-one-task alert**: Copy and button titles vs real usage.

### `EmptyListView`

- Align **copy and visuals** with `TaskFocusView` (same metaphor, consistent gradient).
- Decide whether “Add with full form…” stays long-term or merges into one flow.

### `AddTaskSheet`

- **Keyboard**: Default focus on title; dismiss on save; **Return** key behavior.
- **Validation**: Enforce max length or trim rules if Reminders imposes limits.

### In-place edit (focus view)

- **Done** on title field could **save and dismiss** keyboard (optional shortcut).
- **Swipe / tap outside** to end editing (if desired) without new chrome.

### Cross-cutting UI

- Centralize **spacing / corner radius** tokens so post-it and sheets stay visually related.
- Review **haptics** optional for Complete (off by default or tied to Settings later).

---

## Deferred — roadmap

Ideas explicitly deferred from v1; implement when you choose to expand scope.

- **Animations / gestures**: Replace or augment the **bottom strip** / **floating chrome** with gestures (swipe complete, swipe re-roll, etc.).
- **”Back of the stack” animation**: When pool ≥ 2 and add does not change focus, animate the new task visually **behind** the post-it (purely cosmetic).
- **Priority**: weighting or visual priority cues in UI and optional selection policy.

### Sections / grouped tasks

Reminders.app lets users organize a list into named sections. EventKit’s public API does not expose a section field on `EKReminder`, so behavior is currently unknown:

- Section headers might surface as their own `EKReminder` items (polluting the pool with non-task noise), or sections might be purely a UI construct with no EventKit representation.
- Subtask relationships (`EKReminder` parent/child) are not exposed in the public API either.

**Before building anything here, run the smoke test in [Sections smoke test](#sections-smoke-test) below.**

Once behavior is understood, options include: ignore section tasks silently (filter by `hasRecurrenceRules` / title heuristics), expose sections as a pool filter, or simply document that Monotask works flat.

### Due dates

- **Filter**: “Today / overdue only” mode — exclude reminders with a future due date from the random pool.
- **Styling**: Overdue badge or color shift on the post-it card.
- **Caveat**: EventKit models recurring reminders as a single `EKReminder` with `recurrenceRules`; “completing” it advances to the next occurrence rather than removing it from the store. Any due-date filter must account for this or it will hide recurring tasks perpetually.

### Recurrence

- Surface recurrence cadence on the card (“repeats daily”) so the user knows completing it will bring it back.
- Do **not** try to delete recurring reminders — completing them is almost always the right action. Document this constraint.
- Test: complete a recurring reminder and verify the pool correctly reflects the next instance appearing (or not) on the same reload.

### Widgets / Lock Screen / Live Activities

Surfacing the current task outside the app requires meaningful architecture work:

- **App Group**: Add an App Group entitlement (e.g. `group.com.yourname.monotask`) to both the app target and widget extension so they can share `UserDefaults` (chosen list ID + focused reminder ID).
- **WidgetKit extension**: New target in `project.yml`; a `TimelineProvider` that reads from shared UserDefaults and performs a lightweight EventKit fetch.
- **EventKit in extension**: Widget extensions can call EventKit but must request their own authorization; the OS may grant it automatically if the main app already has full access — verify this on device.
- **Timeline refresh**: Refresh on complete/trash/re-roll by calling `WidgetCenter.shared.reloadAllTimelines()` from `AppViewModel`.
- **Lock Screen**: A small rectangular widget showing the current task title.
- **Live Activities**: Heavier lift; only worthwhile if timed tasks or focus sessions become a feature.
- **iCloud selection sync**: Usually unnecessary because EventKit already syncs reminders; revisit only if you add non-EventKit state.

- **Settings screen**: Beyond list switching (e.g. appearance, haptics, selection policy).
- **Subtasks**: If Apple exposes stable APIs, exclude or represent subtasks explicitly in the pool.

---

## Sections smoke test

Before implementing any sections-aware behavior, verify what EventKit actually returns from a sectioned list. This is a one-time investigative task.

**Manual procedure** (fastest path):
1. In Reminders.app, open (or create) the Monotask list.
2. Add two or three **sections** via the `…` menu → “Add Section”.
3. Add a task in each section.
4. Run Monotask on simulator or device pointing at that list.
5. Tap re-roll several times and note whether section header names appear as tasks in the pool.

**To make this reproducible / automated**, add a `MockRemindersService` fixture (in `MonotaskTests/`) that returns a mix of normal reminders and potential section-header-shaped reminders (e.g. reminders with no title body, or with `hasAlarms == false && notes == nil`). Assert the pool and focus view handle them without crashing.

- [ ] Run manual smoke test with a sectioned Reminders list.
- [ ] Document findings in a comment in `EventKitRemindersService` (or here) so future contributors know what to expect.
- [ ] If section headers appear in the pool: decide on filter strategy and add a unit test covering it.

---

## Maintenance

- Keep **docs/PLAN.md** in sync when you change core behaviors (surfacing rules, phases, EventKit assumptions).
- Keep **[ONBOARDING.md](ONBOARDING.md)** when you implement or instrument first-run onboarding.
- Regenerate **`xcodegen`** project after `project.yml` edits and commit intentional `.pbxproj` updates.
