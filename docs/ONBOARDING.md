# Onboarding (proposed)

This document proposes a first-run flow aimed at **maximizing full Reminders access** (see product constraints in [PLAN.md](PLAN.md)). **No implementation yet.** Later, instrument the steps so we can see where users drop off (see [Instrumentation hooks](#instrumentation-hooks)).

## Sources consulted


| Source                                                                                                                                                | What we took from it                                                                                                                                                                                                                                                                            |
| ----------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [Apple Human Interface Guidelines – Onboarding](https://developer.apple.com/design/human-interface-guidelines/onboarding)                             | Page did not load in our environment; aligned with Apple’s general interaction guidance: request access **when the task needs it**, explain **why**, keep text specific and short. Related docs stress **context** for permission moments rather than surprising users at launch when possible. |
| [Prototypr – 3 best practices for in-app permissions](https://blog.prototypr.io/3-best-practices-for-in-app-permissions-dce7d36544a4)                 | **Pre-permission** (“soft”) step before the OS alert so the first denial is not necessarily the system dialog; **context-triggered** asks after intent; **value-forward** copy; **minimize** separate permission interruptions.                                                                 |
| [Adoptkit – mobile app onboarding best practices](https://www.adoptkit.com/posts/mobile-app-onboarding-best-practices)                                | Fetch timed out; industry convention from that domain includes **short flows**, **progressive disclosure**, and **clear progress** so users know how much setup remains.                                                                                                                        |
| [Reddit – onboarding flow / drop-off discussion](https://www.reddit.com/r/iOSProgramming/comments/1rpzsqb/roast_help_my_onboarding_flow_20_drop_off/) | Page blocked in our environment; the thread title alone reinforces measuring **where users leave** and trimming friction.                                                                                                                                                                       |


## Product constraint

Monotask’s core behavior (show one incomplete reminder from a chosen list, complete, edit, delete, re-roll) requires **full** Reminders access. **Write-only** access is treated as insufficient ([PLAN.md](PLAN.md)). Unlike camera-on-upload patterns, “later” permission still leaves the app useless until granted, so **delaying the system prompt forever** is not viable. The compromise is: **few screens**, **strong justification**, then **one system prompt** after the user has explicitly tapped to continue (soft gate).

## Proposed flow (happy path)

Direction is **one primary vertical path**: welcome → understand Reminders → confirm → **system permission** → existing list-resolution / empty / focus logic.

1. **Welcome (single screen)**
  - **Goal**: Establish what Monotask *is* (one reminder at a time, chosen list) without asking for data yet.  
  - **Content**: Short headline, one supporting line, optional illustration aligned with the post-it UI.  
  - **Primary CTA**: Continue.  
  - **Secondary**: None required (avoid “Skip” that dumps users into a broken state without explanation).
2. **Reminders access explanation (single screen)**
  - **Goal**: Answer “why full access?” before iOS shows the alert. Tie access to **user-visible outcomes**: reading incomplete tasks, marking complete, edits syncing with Reminders.  
  - **Content**: Explicitly mention that Apple only shows the **system permission dialog once** per permission surface in normal use, so tapping **Continue** here should mean “I’m ready to review Apple’s prompt.” Optionally one line on **full vs write-only**: full read is required to list tasks; write-only is not enough (matches current copy direction in `PermissionInstructionsView`).  
  - **Primary CTA**: Continue to permission (label clearly: e.g. “Continue” or “Allow access in next step”).  
  - **No** OS permission request on this screen yet.
3. **Soft confirmation (optional but recommended)**
  - **Goal**: Final consent moment **in-app** so the next UI is expected to be Apple’s dialog (aligns with Prototypr’s pre-permission pattern).  
  - **Implementation options**: Either merge into step 2 as a single prominent primary button, or a minimal interim sheet: “Ready to allow Reminders?” + **Allow** / **Not now**.  
  - **If user taps Allow**: Immediately trigger `requestFullAccess` (or the project’s existing authorization API).  
  - **If Not now**: Route to a **non-destructive** state: short explanation + **Open Settings** + **Try again** (same intent as today’s blocked path), without implying the app works offline.
4. **System permission outcome**
  - **Full access**: Proceed to existing bootstrap (`resolveListAndLoad`, list setup, empty list, or focus).  
  - **Denied / write-only / restricted**: Existing instructions surface (`PermissionInstructionsView` pattern); copy should stay consistent with steps 2–3.

## Flow choices (why not X)

- **Single blast of OS prompts at cold launch**: High deny risk with no mental model (Prototypr; Apple-style **context**).  
- **Long multi-slide tours before value**: Increases abandonment (common onboarding articles; aligns with keeping steps **minimal**).  
- **Fake “Allow” that is not the real prompt**: Deceptive; the soft step should **truthfully** precede the real request.  
- **Skip onboarding entirely**: Works for power users only; most users never grant without **why** Reminders matters here.

## Copy principles

- Lead with **user benefit**, then **what data**, then **what happens if they decline** (Settings path).  
- Avoid jargon (“EventKit”, “calendar API”) unless testing shows comprehension gains.  
- Keep paragraphs **short**; one idea per screen.

## Instrumentation hooks

These are **event names / milestones** for a future analytics layer (local logging, TelemetryDeck, PostHog, etc.). Define stable string IDs so funnels stay comparable across app versions.


| Step / event                                | Notes                                                                                                                              |
| ------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| `onboarding_welcome_impression`             | First paint of welcome screen.                                                                                                     |
| `onboarding_welcome_continue`               | Primary CTA from welcome.                                                                                                          |
| `onboarding_reminders_explainer_impression` | Reminders explanation screen shown.                                                                                                |
| `onboarding_reminders_continue`             | User commits to proceeding toward permission.                                                                                      |
| `onboarding_soft_allow_tap`                 | User tapped the control that **will** lead to the system prompt (if separate from explainer).                                      |
| `onboarding_soft_not_now`                   | User deferred; correlate with later Settings recovery.                                                                             |
| `permission_os_prompt_triggered`            | Immediately before calling `requestFullAccess` (accurate timestamp for ordering).                                                  |
| `permission_outcome`                        | Payload: `full_access`, `denied`, `write_only`, `restricted`, `undetermined` (map from `EKAuthorizationStatus` / app equivalents). |
| `permission_recovery_impression`            | Blocked / instructions UI shown.                                                                                                   |
| `permission_recovery_open_settings`         | Tap Open Settings.                                                                                                                 |
| `permission_recovery_try_again`             | Tap Try again after return from Settings.                                                                                          |
| `post_permission_list_setup_impression`     | Landed in list setup after permission granted.                                                                                     |
| `post_permission_focus_impression`          | Landed on task focus after permission granted.                                                                                     |


**Funnel slices**: Count impressions vs continues between each adjacent pair above; time delta between `permission_os_prompt_triggered` and `permission_outcome`; correlation between `onboarding_soft_not_now` and eventual `permission_outcome == full_access`.

## Open questions

- Whether **one merged screen** (welcome + Reminders explanation + single Continue) tests better than two screens (fewer steps vs less overwhelm). A/B candidate after instrumentation lands.  
- Whether showing a **single illustrative screenshot** of the post-it increases trust enough to justify slightly longer first paint.

## Related files (current app)

- Permission denial UI: `[Monotask/Views/PermissionInstructionsView.swift](../Monotask/Views/PermissionInstructionsView.swift)`  
- Authorization and phases: `[Monotask/State/AppViewModel.swift](../Monotask/State/AppViewModel.swift)`

