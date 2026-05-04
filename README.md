# Monotask

iOS 18+ app that shows one reminder at a time from a list you choose (default: a Reminders list named **Monotask**).

## Requirements

- Xcode 16+ (Swift 5.10 toolchain)
- [xcodegen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`

## Generate and open

```bash
cd /path/to/monotask
xcodegen generate
open Monotask.xcodeproj
```

Then select an iPhone simulator or device and run (**⌘R**).

## First run

Grant **full** Reminders access when prompted. The app needs read access to incomplete reminders, not write-only.

## Rename the app (and default list name)

1. Set `CFBundleDisplayName` in [`Monotask/App/Info.plist`](Monotask/App/Info.plist) (or override via `project.yml` `INFOPLIST_KEY_CFBundleDisplayName`).
2. Optionally change `PRODUCT_BUNDLE_IDENTIFIER` / target `name` in [`project.yml`](project.yml).
3. Run `xcodegen generate` again.
4. Existing installs keep the list they already picked via persisted calendar ID; only new installs use the new default list title.

## Tests

```bash
xcodegen generate
# Pick a booted or available iPhone simulator (name + OS must match an installed runtime)
xcodebuild -scheme Monotask -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.1' test
```

Verified on this machine with Xcode 16 / iOS 18.1 simulator. List devices: `xcrun simctl list devices available`.

## Future considerations

See the product plan (animations, gestures, due dates, subtasks, widgets, etc.).
