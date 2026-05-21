import XCTest
import SnapshotTesting
import SwiftUI
@testable import Monotasker

/// Snapshot tests for the main view states across device sizes and light/dark mode.
///
/// The post-it card tilt is randomised on each appearance (±2.5°), so snapshots
/// use perceptualPrecision: 0.98 — enough tolerance for minor edge-pixel variance
/// while still catching real layout regressions.
///
/// To regenerate reference images (e.g. after an intentional visual change):
///   1. Set `record: .all` in the `snap` helper below.
///   2. Run the snapshot tests once — PNGs are written to __Snapshots__/.
///   3. Restore `record: nil` and commit the updated PNGs.
@MainActor
final class SnapshotTests: XCTestCase {

  // MARK: - Helpers

  private func makeController(phase: AppPhase, task: ReminderTask? = nil) -> UIViewController {
    let listSummary = ReminderCalendarSummary(id: "cal-1", title: "Monotasker")
    let pool: [ReminderTask] = task.map { [$0] } ?? []

    let mock = MockRemindersService(
      authorization: .fullAccess,
      calendars: [listSummary],
      reminders: ["cal-1": pool]
    )
    let suite = "snapshot.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defaults.removePersistentDomain(forName: suite)
    let store = SelectionStore(defaults: defaults)
    if let task {
      store.selectedListIdentifier = listSummary.id
      store.setReminderID(task.id, forList: listSummary.id)
    }

    let vm = AppViewModel(
      reminders: mock,
      selectionStore: store,
      selectionPolicy: UniformRandomTopLevelPolicy { 0.0 },
      skipInitialBootstrap: true
    )
    vm.phase = phase
    vm.activeListSummary = listSummary
    vm.pool = pool
    vm.currentTask = task

    return UIHostingController(rootView: RootView().environment(vm))
  }

  private func snap(
    _ controller: UIViewController,
    device: ViewImageConfig,
    style: UIUserInterfaceStyle,
    named name: String,
    file: StaticString = #filePath,
    testName: String = #function
  ) {
    let traits = UITraitCollection(traitsFrom: [
      device.traits,
      UITraitCollection(userInterfaceStyle: style)
    ])
    assertSnapshot(
      of: controller,
      as: .image(on: device, precision: 1, perceptualPrecision: 0.98, traits: traits),
      named: name,
      record: .missing,   // change to .all to regenerate all reference images
      file: file,
      testName: testName
    )
  }

  // MARK: - Onboarding

  func testOnboarding() {
    let c = makeController(phase: .onboarding)
    snap(c, device: .iPhoneSe,      style: .light, named: "se_light")
    snap(c, device: .iPhoneSe,      style: .dark,  named: "se_dark")
    snap(c, device: .iPhone13,      style: .light, named: "std_light")
    snap(c, device: .iPhone13,      style: .dark,  named: "std_dark")
    snap(c, device: .iPhone13ProMax, style: .light, named: "max_light")
    snap(c, device: .iPhone13ProMax, style: .dark,  named: "max_dark")
  }

  // MARK: - Permission denied

  func testPermissionDenied() {
    let c = makeController(phase: .permissionDenied)
    snap(c, device: .iPhoneSe,      style: .light, named: "se_light")
    snap(c, device: .iPhoneSe,      style: .dark,  named: "se_dark")
    snap(c, device: .iPhone13,      style: .light, named: "std_light")
    snap(c, device: .iPhone13,      style: .dark,  named: "std_dark")
    snap(c, device: .iPhone13ProMax, style: .light, named: "max_light")
    snap(c, device: .iPhone13ProMax, style: .dark,  named: "max_dark")
  }

  // MARK: - Empty list

  func testEmptyList() {
    let c = makeController(phase: .emptyList)
    snap(c, device: .iPhoneSe,      style: .light, named: "se_light")
    snap(c, device: .iPhoneSe,      style: .dark,  named: "se_dark")
    snap(c, device: .iPhone13,      style: .light, named: "std_light")
    snap(c, device: .iPhone13,      style: .dark,  named: "std_dark")
    snap(c, device: .iPhone13ProMax, style: .light, named: "max_light")
    snap(c, device: .iPhone13ProMax, style: .dark,  named: "max_dark")
  }

  // MARK: - Focused (main task view)

  func testFocused() {
    let task = ReminderTask(
      id: "r-1",
      title: "Finish the app",
      notes: "Almost there.",
      isCompleted: false
    )
    let c = makeController(phase: .focused, task: task)
    snap(c, device: .iPhoneSe,      style: .light, named: "se_light")
    snap(c, device: .iPhoneSe,      style: .dark,  named: "se_dark")
    snap(c, device: .iPhone13,      style: .light, named: "std_light")
    snap(c, device: .iPhone13,      style: .dark,  named: "std_dark")
    snap(c, device: .iPhone13ProMax, style: .light, named: "max_light")
    snap(c, device: .iPhone13ProMax, style: .dark,  named: "max_dark")
  }

  // MARK: - Focused with long content (overflow / truncation check)

  func testFocusedLongContent() {
    let task = ReminderTask(
      id: "r-1",
      title: "Write comprehensive unit tests covering every edge case in the view model",
      notes: "Make sure to cover the undo flow, the external change handler, the onboarding path, and the list resolution fallback.",
      isCompleted: false
    )
    let c = makeController(phase: .focused, task: task)
    snap(c, device: .iPhoneSe,      style: .light, named: "se_light")
    snap(c, device: .iPhone13,      style: .light, named: "std_light")
    snap(c, device: .iPhone13ProMax, style: .light, named: "max_light")
  }
}
