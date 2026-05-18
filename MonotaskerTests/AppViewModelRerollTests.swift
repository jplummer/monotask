import XCTest
@testable import Monotasker

@MainActor
final class AppViewModelRerollTests: XCTestCase {

  private func makeStore(listId: String = "cal-1", reminderId: String? = nil) -> SelectionStore {
    let suite = "test.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defaults.removePersistentDomain(forName: suite)
    let store = SelectionStore(defaults: defaults)
    store.selectedListIdentifier = listId
    if let reminderId { store.setReminderID(reminderId, forList: listId) }
    return store
  }

  func testRerollWithMultipleTasksChangesCurrentTask() async {
    let r1 = ReminderTask(id: "r-1", title: "A", isCompleted: false)
    let r2 = ReminderTask(id: "r-2", title: "B", isCompleted: false)
    let mock = MockRemindersService(
      calendars: [ReminderCalendarSummary(id: "cal-1", title: "Monotasker")],
      reminders: ["cal-1": [r1, r2]]
    )
    let store = makeStore(reminderId: "r-1")
    // Policy always picks index 0 of the filtered pool; after excluding r-1, only r-2 remains.
    let vm = AppViewModel(
      reminders: mock,
      selectionStore: store,
      selectionPolicy: UniformRandomTopLevelPolicy { 0.0 },
      skipInitialBootstrap: true
    )
    await vm.start()
    XCTAssertEqual(vm.currentTask?.id, "r-1")

    await vm.reroll()

    XCTAssertEqual(vm.currentTask?.id, "r-2")
    XCTAssertEqual(store.reminderID(forList: "cal-1"), "r-2")
    XCTAssertFalse(vm.showOnlyOneTaskAlert)
  }

  func testRerollWithSingleTaskKeepsSameTaskAndShowsAlert() async {
    let r1 = ReminderTask(id: "r-1", title: "Only", isCompleted: false)
    let mock = MockRemindersService(
      calendars: [ReminderCalendarSummary(id: "cal-1", title: "Monotasker")],
      reminders: ["cal-1": [r1]]
    )
    let store = makeStore(reminderId: "r-1")
    let vm = AppViewModel(
      reminders: mock,
      selectionStore: store,
      selectionPolicy: UniformRandomTopLevelPolicy { 0.0 },
      skipInitialBootstrap: true
    )
    await vm.start()

    await vm.reroll()

    XCTAssertEqual(vm.currentTask?.id, "r-1")
    XCTAssertTrue(vm.showOnlyOneTaskAlert)
  }

  func testDismissOnlyOneTaskAlertClearsFlag() async {
    let r1 = ReminderTask(id: "r-1", title: "Only", isCompleted: false)
    let mock = MockRemindersService(
      calendars: [ReminderCalendarSummary(id: "cal-1", title: "Monotasker")],
      reminders: ["cal-1": [r1]]
    )
    let store = makeStore(reminderId: "r-1")
    let vm = AppViewModel(
      reminders: mock,
      selectionStore: store,
      selectionPolicy: UniformRandomTopLevelPolicy { 0.0 },
      skipInitialBootstrap: true
    )
    await vm.start()
    await vm.reroll()
    XCTAssertTrue(vm.showOnlyOneTaskAlert)

    vm.dismissOnlyOneTaskAlert()

    XCTAssertFalse(vm.showOnlyOneTaskAlert)
  }
}
