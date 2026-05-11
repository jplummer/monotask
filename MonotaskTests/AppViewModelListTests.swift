import XCTest
@testable import Monotask

@MainActor
final class AppViewModelListTests: XCTestCase {

  private func makeStore(listId: String? = nil) -> SelectionStore {
    let suite = "test.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defaults.removePersistentDomain(forName: suite)
    let store = SelectionStore(defaults: defaults)
    store.selectedListIdentifier = listId
    return store
  }

  // MARK: - applyListChoice

  func testApplyListChoiceSwitchesListAndLoadsPool() async {
    let taskInList2 = ReminderTask(id: "r-10", title: "List 2 task", isCompleted: false)
    let mock = MockRemindersService(
      calendars: [
        ReminderCalendarSummary(id: "cal-1", title: "Monotask"),
        ReminderCalendarSummary(id: "cal-2", title: "Work")
      ],
      reminders: [
        "cal-1": [ReminderTask(id: "r-1", title: "List 1 task", isCompleted: false)],
        "cal-2": [taskInList2]
      ]
    )
    let store = makeStore(listId: "cal-1")
    let vm = AppViewModel(
      reminders: mock,
      selectionStore: store,
      selectionPolicy: UniformRandomTopLevelPolicy { 0.0 },
      skipInitialBootstrap: true
    )
    await vm.start()
    XCTAssertEqual(vm.currentTask?.id, "r-1")

    let list2 = ReminderCalendarSummary(id: "cal-2", title: "Work")
    await vm.applyListChoice(list2)

    XCTAssertEqual(vm.activeListSummary?.id, "cal-2")
    XCTAssertEqual(store.selectedListIdentifier, "cal-2")
    XCTAssertEqual(vm.phase, .focused)
    XCTAssertEqual(vm.currentTask?.id, "r-10")
  }

  func testListSwitchRecordsCurrentTaskInMap() async {
    let mock = MockRemindersService(
      calendars: [
        ReminderCalendarSummary(id: "cal-1", title: "Monotask"),
        ReminderCalendarSummary(id: "cal-2", title: "Work")
      ],
      reminders: [
        "cal-1": [ReminderTask(id: "r-1", title: "A", isCompleted: false)],
        "cal-2": [ReminderTask(id: "r-2", title: "B", isCompleted: false)]
      ]
    )
    let store = makeStore(listId: "cal-1")
    let vm = AppViewModel(
      reminders: mock,
      selectionStore: store,
      selectionPolicy: UniformRandomTopLevelPolicy { 0.0 },
      skipInitialBootstrap: true
    )
    await vm.start()
    XCTAssertEqual(vm.currentTask?.id, "r-1")

    await vm.applyListChoice(ReminderCalendarSummary(id: "cal-2", title: "Work"))

    // cal-1's last focused task must be recorded in the map.
    XCTAssertEqual(store.reminderID(forList: "cal-1"), "r-1")
    // Current focus is now on cal-2.
    XCTAssertEqual(vm.currentTask?.id, "r-2")
  }

  func testListSwitchRestoresRememberedTaskOnReturn() async {
    let r1 = ReminderTask(id: "r-1", title: "A", isCompleted: false)
    let r2 = ReminderTask(id: "r-2", title: "B", isCompleted: false)
    let r3 = ReminderTask(id: "r-3", title: "C", isCompleted: false)
    let mock = MockRemindersService(
      calendars: [
        ReminderCalendarSummary(id: "cal-1", title: "Monotask"),
        ReminderCalendarSummary(id: "cal-2", title: "Work")
      ],
      reminders: [
        "cal-1": [r1, r2],
        "cal-2": [r3]
      ]
    )
    // Pre-seed cal-1 so r-2 is remembered.
    let store = makeStore(listId: "cal-1")
    store.setReminderID("r-2", forList: "cal-1")
    let vm = AppViewModel(
      reminders: mock,
      selectionStore: store,
      selectionPolicy: UniformRandomTopLevelPolicy { 0.0 },
      skipInitialBootstrap: true
    )
    await vm.start()
    XCTAssertEqual(vm.currentTask?.id, "r-2")

    // Switch to cal-2, then back to cal-1.
    await vm.applyListChoice(ReminderCalendarSummary(id: "cal-2", title: "Work"))
    await vm.applyListChoice(ReminderCalendarSummary(id: "cal-1", title: "Monotask"))

    // Should restore r-2, the last remembered task for cal-1.
    XCTAssertEqual(vm.currentTask?.id, "r-2")
  }

  // MARK: - openListSetup

  func testOpenListSetupTransitionsToListSetupPhase() async {
    let mock = MockRemindersService(
      calendars: [ReminderCalendarSummary(id: "cal-1", title: "Monotask")],
      reminders: ["cal-1": [ReminderTask(id: "r-1", title: "Task", isCompleted: false)]]
    )
    let store = makeStore(listId: "cal-1")
    let vm = AppViewModel(
      reminders: mock,
      selectionStore: store,
      selectionPolicy: UniformRandomTopLevelPolicy { 0.0 },
      skipInitialBootstrap: true
    )
    await vm.start()
    XCTAssertEqual(vm.phase, .focused)

    vm.openListSetup()

    XCTAssertEqual(vm.phase, .listSetup)
  }

  // MARK: - createReminderList

  func testCreateReminderListCreatesCalendarAndSwitchesToEmptyList() async {
    let mock = MockRemindersService(
      calendars: [ReminderCalendarSummary(id: "cal-1", title: "Monotask")],
      reminders: ["cal-1": []]
    )
    let store = makeStore(listId: "cal-1")
    let vm = AppViewModel(
      reminders: mock,
      selectionStore: store,
      selectionPolicy: UniformRandomTopLevelPolicy { 0.0 },
      skipInitialBootstrap: true
    )
    await vm.start()

    await vm.createReminderList(named: "New Project")

    XCTAssertEqual(vm.activeListSummary?.title, "New Project")
    XCTAssertEqual(vm.phase, .emptyList)
    XCTAssertTrue(mock.reminderCalendars().contains { $0.title == "New Project" })
  }

  func testCreateReminderListThrowingSetsUserMessage() async {
    let mock = MockRemindersService(
      calendars: [ReminderCalendarSummary(id: "cal-1", title: "Monotask")],
      reminders: ["cal-1": [ReminderTask(id: "r-1", title: "Task", isCompleted: false)]]
    )
    mock.setCreateListError(RemindersServiceError.noWritableSource)
    let store = makeStore(listId: "cal-1")
    let vm = AppViewModel(
      reminders: mock,
      selectionStore: store,
      selectionPolicy: UniformRandomTopLevelPolicy { 0.0 },
      skipInitialBootstrap: true
    )
    await vm.start()

    await vm.createReminderList(named: "Will Fail")

    XCTAssertNotNil(vm.userMessage)
  }

  func testCreateReminderListBlankNameIsNoOp() async {
    let mock = MockRemindersService(
      calendars: [ReminderCalendarSummary(id: "cal-1", title: "Monotask")],
      reminders: ["cal-1": [ReminderTask(id: "r-1", title: "Task", isCompleted: false)]]
    )
    let store = makeStore(listId: "cal-1")
    let vm = AppViewModel(
      reminders: mock,
      selectionStore: store,
      selectionPolicy: UniformRandomTopLevelPolicy { 0.0 },
      skipInitialBootstrap: true
    )
    await vm.start()
    let calendarCountBefore = mock.reminderCalendars().count

    await vm.createReminderList(named: "   ")

    XCTAssertEqual(mock.reminderCalendars().count, calendarCountBefore)
  }
}
