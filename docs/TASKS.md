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
- **Tests**: Selection policy + mocks exist under `MonotaskTests/`.
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

---

## Suggested implementation order

Prioritize **identity and observability**, then **inclusive UX**, then **first-run flows**, then **speed**, then **distribution**.

1. **Branding & visual identity** — Lock icon direction, palette/post-it character, and voice **before** splash and onboarding so those screens feel intentional. Optional: run **multiple agents or designers in parallel** on competing directions, then pick one.
2. **Daily-use instrumentation** — Wire **core events** for real usage (opens, completes, deletes, undo usage, list switches, errors) so you can iterate before and after launch. Choose provider (TelemetryDeck, PostHog, OSLog-only, etc.) and privacy stance; onboarding funnel events can share the same pipe later.
3. **Full accessibility pass** — VoiceOver order and labels, Dynamic Type through **large** sizes, Reduce Motion, contrast and tap targets on **bottom strip**, **floating chrome**, sheets, and empty/setup flows.
4. **Splash + first-run onboarding** — After branding; short launch shell; education per [ONBOARDING.md](ONBOARDING.md); defer `bootstrap` / `start()` until after onboarding when applicable so the Reminders prompt is not the first screen.
5. **Performance pass** — Profile focus view, post-it, list loads; coalesce or debounce `EKEventStoreChanged` if reloads stack; trim redundant layout/animation cost (see [Performance pass](#performance-pass)).
6. **Ship-ready polish** — Error UX improvements, scene lifecycle (background / Settings / Reminders edits), small-phone and dark/light passes (can overlap step 3).
7. **View refinement** — Typography, haptics, tokens ([View and behavior refinement](#view-and-behavior-refinement)); ongoing.
8. **App Store and marketing assets** — **Last**: screenshots, copy, privacy questionnaire, support URL after UI and icon settle ([App Store and marketing assets](#app-store-and-marketing-assets)).
9. **Deferred roadmap** — [Deferred](#deferred--roadmap) when expanding scope.

---

## Branding & visual identity

Do **before** splash/onboarding and before treating App Icon / screenshots as final.

- [ ] Define **icon** concept (metaphor, silhouette, dark/light).
- [ ] Align **gradient + post-it** with personality (calm, playful, minimal — pick and execute).
- [ ] Optional: **multi-agent / parallel exploration** of 2–3 directions, then merge winners into one system.

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
- **“Back of the stack” animation**: When pool ≥ 2 and add does not change focus, animate the new task visually **behind** the post-it (purely cosmetic).
- **Priority**: weighting or visual priority cues in UI and optional selection policy.
- **Due dates**: Filters (“today only”), overdue styling, or exclude not-yet-due from random pool.
- **Recurrence**: Surface recurrence info on the card without breaking EventKit’s next-instance behavior.
- **Subtasks**: If Apple exposes stable APIs, exclude or represent subtasks explicitly in the pool.
- **Settings screen**: Beyond list switching (e.g. appearance, haptics, selection policy).
- **Widgets / Lock Screen / Live Activities**: Surface current task outside the app.
- **iCloud selection sync**: Usually unnecessary because EventKit already syncs reminders; revisit only if you add non-EventKit state.

---

## Maintenance

- Keep **docs/PLAN.md** in sync when you change core behaviors (surfacing rules, phases, EventKit assumptions).
- Keep **[ONBOARDING.md](ONBOARDING.md)** when you implement or instrument first-run onboarding.
- Regenerate **`xcodegen`** project after `project.yml` edits and commit intentional `.pbxproj` updates.
