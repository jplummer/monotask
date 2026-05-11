import XCTest
@testable import Monotask

/// Regression guard: verifies that tasks shaped like Reminders section headers
/// (no notes, no completion status set) do not crash the VM and do not prevent
/// the app from reaching .focused.
///
/// This is the automated companion to the manual smoke test in docs/TASKS.md.
@MainActor
final class AppViewModelSectionsTests: XCTestCase {

  func testPoolWithSectionHeaderShapedTasksReachesFocused() async {
    // Section headers in Reminders.app typically have a title but no notes.
    // They look identical to regular reminders from EventKit's perspective —
    // this test confirms the VM handles them without crashing.
    let sectionHeader = ReminderTask(id: "r-section", title: "My Section", notes: nil, isCompleted: false)
    let normalTask = ReminderTask(id: "r-1", title: "Real task", notes: "some notes", isCompleted: false)

    let mock = MockRemindersService(
      calendars: [ReminderCalendarSummary(id: "cal-1", title: "Monotask")],
      reminders: ["cal-1": [sectionHeader, normalTask]]
    )
    let suite = "test.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defaults.removePersistentDomain(forName: suite)
    let store = SelectionStore(defaults: defaults)
    store.selectedListIdentifier = "cal-1"

    let vm = AppViewModel(
      reminders: mock,
      selectionStore: store,
      selectionPolicy: UniformRandomTopLevelPolicy { 0.0 },
      skipInitialBootstrap: true
    )
    await vm.start()

    XCTAssertEqual(vm.phase, .focused)
    XCTAssertNotNil(vm.currentTask)
    XCTAssertEqual(vm.pool.count, 2, "both tasks should appear in the pool — sections are flat in EventKit")
  }

  func testPoolWithOnlyHeaderShapedTasksStillFocuses() async {
    let header1 = ReminderTask(id: "r-h1", title: "Section A", notes: nil, isCompleted: false)
    let header2 = ReminderTask(id: "r-h2", title: "Section B", notes: nil, isCompleted: false)

    let mock = MockRemindersService(
      calendars: [ReminderCalendarSummary(id: "cal-1", title: "Monotask")],
      reminders: ["cal-1": [header1, header2]]
    )
    let suite = "test.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defaults.removePersistentDomain(forName: suite)
    let store = SelectionStore(defaults: defaults)
    store.selectedListIdentifier = "cal-1"

    let vm = AppViewModel(
      reminders: mock,
      selectionStore: store,
      selectionPolicy: UniformRandomTopLevelPolicy { 0.0 },
      skipInitialBootstrap: true
    )
    await vm.start()

    XCTAssertEqual(vm.phase, .focused)
    XCTAssertNotNil(vm.currentTask)
  }
}
