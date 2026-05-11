import XCTest
@testable import Monotask

@MainActor
final class AppViewModelAddTests: XCTestCase {

  private func makeStore(listId: String = "cal-1", reminderId: String? = nil) -> SelectionStore {
    let suite = "test.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defaults.removePersistentDomain(forName: suite)
    let store = SelectionStore(defaults: defaults)
    store.selectedListIdentifier = listId
    if let reminderId { store.setReminderID(reminderId, forList: listId) }
    return store
  }

  // MARK: - pool = 0 (addFromEmpty)

  func testAddFromEmptyFocusesNewTask() async {
    let mock = MockRemindersService(
      calendars: [ReminderCalendarSummary(id: "cal-1", title: "Monotask")],
      reminders: ["cal-1": []]
    )
    let store = makeStore()
    let vm = AppViewModel(
      reminders: mock,
      selectionStore: store,
      selectionPolicy: UniformRandomTopLevelPolicy { 0.0 },
      skipInitialBootstrap: true
    )
    await vm.start()
    XCTAssertEqual(vm.phase, .emptyList)

    await vm.addFromEmpty(title: "Brand new task", notes: nil)

    XCTAssertEqual(vm.phase, .focused)
    XCTAssertEqual(vm.currentTask?.title, "Brand new task")
  }

  // MARK: - Blank / whitespace title

  func testConfirmAddBlankTitleIsNoOp() async {
    let mock = MockRemindersService(
      calendars: [ReminderCalendarSummary(id: "cal-1", title: "Monotask")],
      reminders: ["cal-1": []]
    )
    let store = makeStore()
    let vm = AppViewModel(
      reminders: mock,
      selectionStore: store,
      selectionPolicy: UniformRandomTopLevelPolicy { 0.0 },
      skipInitialBootstrap: true
    )
    await vm.start()
    vm.beginAdd()

    await vm.confirmAdd(title: "", notes: nil)

    XCTAssertTrue(vm.showAddSheet, "sheet must stay open after no-op")
    // Pool must remain empty — no reminder was created
    XCTAssertTrue(vm.pool.isEmpty)
  }

  func testConfirmAddWhitespaceTitleIsNoOp() async {
    let mock = MockRemindersService(
      calendars: [ReminderCalendarSummary(id: "cal-1", title: "Monotask")],
      reminders: ["cal-1": []]
    )
    let store = makeStore()
    let vm = AppViewModel(
      reminders: mock,
      selectionStore: store,
      selectionPolicy: UniformRandomTopLevelPolicy { 0.0 },
      skipInitialBootstrap: true
    )
    await vm.start()
    vm.beginAdd()

    await vm.confirmAdd(title: "   ", notes: nil)

    XCTAssertTrue(vm.showAddSheet)
  }

  // MARK: - cancelAdd

  func testCancelAddDismissesSheet() async {
    let mock = MockRemindersService(
      calendars: [ReminderCalendarSummary(id: "cal-1", title: "Monotask")],
      reminders: ["cal-1": []]
    )
    let store = makeStore()
    let vm = AppViewModel(
      reminders: mock,
      selectionStore: store,
      selectionPolicy: UniformRandomTopLevelPolicy { 0.0 },
      skipInitialBootstrap: true
    )
    await vm.start()
    vm.beginAdd()
    XCTAssertTrue(vm.showAddSheet)

    vm.cancelAdd()

    XCTAssertFalse(vm.showAddSheet)
  }

  // MARK: - confirmAdd throws

  func testConfirmAddThrowingSetsUserMessageAndKeepsSheetOpen() async {
    let mock = MockRemindersService(
      calendars: [ReminderCalendarSummary(id: "cal-1", title: "Monotask")],
      reminders: ["cal-1": []]
    )
    let store = makeStore()
    let vm = AppViewModel(
      reminders: mock,
      selectionStore: store,
      selectionPolicy: UniformRandomTopLevelPolicy { 0.0 },
      skipInitialBootstrap: true
    )
    await vm.start()
    vm.beginAdd()
    // Point the VM at a calendar ID not in the mock so createReminder throws
    vm.activeListSummary = ReminderCalendarSummary(id: "cal-ghost", title: "Ghost")

    await vm.confirmAdd(title: "Doomed task", notes: nil)

    XCTAssertNotNil(vm.userMessage)
    XCTAssertTrue(vm.showAddSheet, "sheet must stay open after error")
  }

  // MARK: - showTaskAddedToast

  func testShowTaskAddedToastSetAfterSuccessfulAdd() async {
    let mock = MockRemindersService(
      calendars: [ReminderCalendarSummary(id: "cal-1", title: "Monotask")],
      reminders: ["cal-1": []]
    )
    let store = makeStore()
    let vm = AppViewModel(
      reminders: mock,
      selectionStore: store,
      selectionPolicy: UniformRandomTopLevelPolicy { 0.0 },
      skipInitialBootstrap: true
    )
    await vm.start()
    vm.beginAdd()

    await vm.confirmAdd(title: "Something", notes: nil)

    XCTAssertTrue(vm.showTaskAddedToast)
  }
}
