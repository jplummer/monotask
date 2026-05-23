# Onboarding Design Spec
_Date: 2026-05-16_

## Philosophy

Get users into the actual app interface and using it as fast as pleasantly possible. Every screen in the onboarding flow uses the real app visual language — the gradient background, the card stack, the post-it card — rather than a separate "marketing" UI. By the time the user has their first task, they already know what the app looks and feels like.

---

## Screens & States

### 1. Static Launch Screen (iOS LaunchScreen)

Gradient only — no card, no text, no spinner. Shown by iOS for a fraction of a second before app code runs, primarily to prevent a white flash on cold launch. The real branded experience begins with §2.

Use the named color assets `GradientTop` and `GradientBottom` from `Assets.xcassets` as the storyboard background colors. Both assets already define light and dark variants, so the launch screen automatically respects the system appearance — no extra work required.

---

### 2. In-App Bootstrap State (every launch)

Shown while EventKit initializes and the persisted list resolves. Displayed on every launch for all users.

**Visual:**
- Full gradient background
- Card stack: same visual as the main app — two background cards using the real `DesignColors` post-it palette, each at its own tilt angle so all three cards are visible (match the existing `PostItCard` / card stack implementation exactly)
- Front card #FFF0D1 (light mode)
- Front card copy: title "Monotask", note "Get one thing done at a time" — same title/note layout and typography as any normal task card
- Respects system dark/light mode (front card #5C5247 in dark mode)
- No icons, no nav bar, no bottom strip

**Behavior:**
- After bootstrap completes, transitions to:
  - `focused` or `emptyList` phase — if onboarded and list is resolved
  - `listSetup` phase (opens nav bar picker automatically) — if onboarded but no list resolved
  - Onboarding screen — if not yet onboarded
- Delayed spinner: if bootstrap takes longer than ~300ms, a small spinner appears below the card. Delay threshold is tunable after the performance pass.

---

### 3. Onboarding Screen (first launch only)

Replaces the bootstrap state for users who have not yet granted Reminders permission.

**Visual:**
- Same gradient + card stack as bootstrap state
- Front card: #FFF0D1 light / #5C5247 dark, same tilt angles as bootstrap state (match existing card stack implementation)
- Front card copy: title "Select a Reminders list", note "Monotask gives you one task at a time, from the Reminders list of your choice"
- **Only visible control:** completion checkbox (circle, upper-left of card)
- All other icons hidden (no bottom strip, no pencil, no shuffle, no nav bar)

**Interaction:**
- Tap completion checkbox → fires the iOS Reminders permission dialog
- Permission granted → list selection flow (see §5)
- Permission denied → permission denied screen (see §4)

---

### 4. Permission Denied Screen

Shown when the user denies Reminders access during onboarding, or when the app is launched with permission previously denied or restricted.

**Visual:**
- Full gradient background (no card stack behind)
- Single ghost card: transparent background, dashed outline border, tilted ~-2°
- Inside ghost card: lock icon + title "Reminders access needed" + short instructional body ("Open Settings and allow Reminders access to use Monotask")
- Below ghost card: two controls
  - Primary button: "Open Settings" (opens iOS Settings deep link)
  - Secondary text link: "Try again" (re-checks permission status)

---

### 5. List Selection (post-permission)

Triggered immediately after permission is granted.

**Case A — "Monotask" list found:**
- App silently selects the found list and transitions directly to the main `focused` / `emptyList` state
- A toast appears: _"Using your Monotask list"_ with a **"Change"** action button on the right
- Tapping "Change" opens the nav bar list picker

**Case B — No "Monotask" list found:**
- Nav bar list picker opens immediately (no intermediate screen)
- Picker has a heading: "Select Reminders list"
- Bottom of picker: "Add New List" row with a circle-plus icon

**Case C — No lists at all:**
- Same as Case B. "Add New List" is the first and only row. User creates a list and returns.

---

### 6. Empty List State

Shown when a list is resolved but contains no incomplete reminders.

**On arrival (every time this state is entered):**
- Card drops directly into inline edit mode
- Keyboard is up, title field focused, placeholder text: "Enter your first task"
- Notes field visible below with placeholder "optional"
- "Done" in the keyboard toolbar submits the task

**If user dismisses keyboard without typing:**
- Keyboard closes
- Card displays static placeholder copy: title "What do you need to do?", note "Add a task to your Monotask list"
- The usual "+" (add task) button appears below the card, as does the edit icon in its usual location
- Tapping either re-enters edit mode

---

### 7. Bootstrap → Onboarding Transition

When bootstrap resolves and the user has not yet onboarded, the card transitions from bootstrap copy to onboarding copy using a two-phase crossfade:

1. Card content (title, note) fades out → card is briefly blank
2. Onboarding content (title, note, checkbox) fades in together in one step

The blank-card pause gives the user a clear "something changed" signal without a jarring jump cut. If in practice the bootstrap resolves so quickly that the first state is imperceptible, this transition can be dropped — but start with it.

If the checkbox-arriving-simultaneously proves too subtle in testing, try a short additional delay on the checkbox after the text fades in. TelemetryDeck drop-off data from the onboarding funnel will help identify if users are struggling to find the CTA.

---

## Analytics (TelemetryDeck)

TelemetryDeck is confirmed in place (`TelemetryDeckAnalyticsService`). Onboarding is the highest-leverage funnel to monitor. Instrument every step so drop-off is visible.

| Event | Trigger | Status |
|---|---|---|
| `onboarding.impression` | Onboarding screen appears | ✅ wired |
| `onboarding.cta_tapped` | Completion checkbox tapped | ✅ wired (rename candidate: `onboarding.checkbox_tapped`) |
| `permission.outcome` | Permission dialog resolved (params: granted/denied/error) | ✅ wired |
| `onboarding.list_auto_selected` | "Monotask" list found and silently selected | ➕ new |
| `onboarding.list_picker_opened` | Nav bar picker opened during onboarding | ➕ new |
| `onboarding.change_tapped` | User taps "Change" on the auto-select toast | ➕ new |
| `onboarding.complete` | User reaches `focused` or `emptyList` with a list resolved | ➕ new |
| `onboarding.first_task_created` | First task submitted from the empty-state edit card | ➕ new |

New events (`➕`) should be added during implementation. The existing wired events may need their call sites updated to match the new interaction model (the CTA is now a checkbox, not a button).

---

## Nav Bar List Picker

The existing `ToolbarItem(.principal)` menu, used throughout the app for switching lists.

- **Heading:** "Select Reminders list" (added)
- **Bottom row:** "Add New List" with a circle-plus (`􀁌`) icon
- Opened during onboarding (Cases B/C above) or via "Change" toast action

---

## Dark Mode

All screens in this spec respect the system appearance automatically. No special-casing is needed — the existing infrastructure handles it:

| Element | Light | Dark | Source |
|---|---|---|---|
| Gradient background | Soft pink→peach | Deep purple→teal | `DesignColors.gradientTop/Bottom` (named assets in `Assets.xcassets`, both variants already defined) |
| Front card | Warm cream `#FFF0D1` | Warm dark `#5C5247`-ish | `DesignColors.postItColor(at: 0)` |
| Background cards | Pastel palette | Muted dark palette | `DesignColors.postItColor(at:)` — same indices as main app |
| Ghost card (permission denied) | Transparent + dark dashed border | Same treatment, dark mode colors | `DesignColors` + system opacity |
| LaunchScreen gradient | Light variant | Dark variant | Named color assets referenced directly in storyboard |

The rule: never hardcode colors in new onboarding views. Always use `DesignColors` or the existing named asset colors. Dark mode comes for free.

---

## What Changes vs. Current Implementation

| Current | New |
|---|---|
| `OnboardingView` — placeholder text + system icon + "Connect my Reminders" button | Card-based onboarding screen with completion checkbox as the sole CTA |
| `bootstrapping` phase shows nothing (or system default) | Bootstrap state shows the branded card |
| `ListSetupView` — dedicated screen for list creation/selection | Retired; `listSetup` phase now opens nav bar picker automatically instead |
| `EmptyListView` — static empty state with add button | Auto-enters edit mode on arrival; falls back to static card on keyboard dismiss |
| `PermissionInstructionsView` — generic layout | Ghost card with dashed outline, lock icon, same button actions |

---

## Pre-Launch

- **App Store identity tuning** — before launch, revisit and tune the App Store listing: screenshots, description, keywords, and preview. Onboarding copy decisions (tagline, value prop framing) should inform the store listing language for consistency.

---

## Out of Scope

- Swipe gestures on the onboarding card (reserved for a later main UI iteration)
- Multi-screen onboarding tour / feature explainer
- Analytics instrumentation (event names are pre-defined in `ONBOARDING.md`; wiring them up is a separate pass)
- Dark mode card color (#5C5247) — handled as part of the existing dark mode pass, not this spec
