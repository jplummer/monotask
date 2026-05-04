import XCTest
@testable import Monotask

@MainActor
final class AppViewModelTests: XCTestCase {
  func testAddSurfacesNewTaskWhenPoolWasOne() async {
    let suite = "test.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defaults.removePersistentDomain(forName: suite)
    let store = SelectionStore(defaults: defaults)
    store.selectedListIdentifier = "cal-1"
    let existing = ReminderTask(id: "r-1", title: "Only", notes: nil, isCompleted: false)
    let mock = MockRemindersService(
      calendars: [ReminderCalendarSummary(id: "cal-1", title: "Monotask")],
      reminders: ["cal-1": [existing]]
    )
    let vm = AppViewModel(
      reminders: mock,
      selectionStore: store,
      selectionPolicy: UniformRandomTopLevelPolicy { 0.42 },
      skipInitialBootstrap: true
    )
    await vm.start()
    XCTAssertEqual(vm.phase, .focused)
    XCTAssertEqual(vm.currentTask?.id, "r-1")
    vm.beginAdd()
    XCTAssertEqual(vm.poolSizeWhenAddOpened, 1)
    await vm.confirmAdd(title: "Second", notes: nil)
    XCTAssertEqual(vm.phase, .focused)
    XCTAssertEqual(vm.currentTask?.title, "Second")
    XCTAssertEqual(store.selectedReminderIdentifier, vm.currentTask?.id)
  }

  func testAddKeepsFocusWhenPoolWasTwoOrMore() async {
    let suite = "test.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defaults.removePersistentDomain(forName: suite)
    let store = SelectionStore(defaults: defaults)
    store.selectedListIdentifier = "cal-1"
    store.selectedReminderIdentifier = "r-1"
    let mock = MockRemindersService(
      calendars: [ReminderCalendarSummary(id: "cal-1", title: "Monotask")],
      reminders: [
        "cal-1": [
          ReminderTask(id: "r-1", title: "A", isCompleted: false),
          ReminderTask(id: "r-2", title: "B", isCompleted: false)
        ]
      ]
    )
    let vm = AppViewModel(
      reminders: mock,
      selectionStore: store,
      selectionPolicy: UniformRandomTopLevelPolicy { 0.1 },
      skipInitialBootstrap: true
    )
    await vm.start()
    XCTAssertEqual(vm.currentTask?.id, "r-1")
    vm.beginAdd()
    XCTAssertEqual(vm.poolSizeWhenAddOpened, 2)
    await vm.confirmAdd(title: "C", notes: nil)
    XCTAssertEqual(vm.currentTask?.id, "r-1")
    XCTAssertTrue(vm.pool.contains { $0.title == "C" })
  }
}
