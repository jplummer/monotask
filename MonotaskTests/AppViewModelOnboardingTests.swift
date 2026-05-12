import XCTest
@testable import Monotask

@MainActor
final class AppViewModelOnboardingTests: XCTestCase {

  private func makeStore(listId: String? = nil) -> SelectionStore {
    let suite = "test.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defaults.removePersistentDomain(forName: suite)
    let store = SelectionStore(defaults: defaults)
    store.selectedListIdentifier = listId
    return store
  }

  // MARK: - connectReminders — undetermined

  func testConnectRemindersUndeterminedGrantedProceedsToFocused() async {
    let task = ReminderTask(id: "r-1", title: "Do thing", isCompleted: false)
    let mock = MockRemindersService(
      authorization: .undetermined,
      calendars: [ReminderCalendarSummary(id: "cal-1", title: "Monotask")],
      reminders: ["cal-1": [task]]
    )
    let store = makeStore(listId: "cal-1")
    let vm = AppViewModel(
      reminders: mock,
      selectionStore: store,
      selectionPolicy: UniformRandomTopLevelPolicy { 0.0 },
      skipInitialBootstrap: true
    )
    await vm.connectReminders()
    XCTAssertEqual(vm.phase, .focused)
    XCTAssertEqual(vm.currentTask?.id, "r-1")
  }

  func testConnectRemindersUndeterminedDeniedGoesToPermissionDenied() async {
    let mock = MockRemindersService(authorization: .undetermined)
    mock.setRequestAccessResult(false)
    let store = makeStore()
    let vm = AppViewModel(
      reminders: mock,
      selectionStore: store,
      selectionPolicy: UniformRandomTopLevelPolicy { 0.0 },
      skipInitialBootstrap: true
    )
    await vm.connectReminders()
    XCTAssertEqual(vm.phase, .permissionDenied)
  }

  func testConnectRemindersUndeterminedErrorGoesToPermissionDenied() async {
    let mock = MockRemindersService(authorization: .undetermined)
    mock.setRequestAccessError(MockRemindersService.MockError.generic)
    let store = makeStore()
    let vm = AppViewModel(
      reminders: mock,
      selectionStore: store,
      selectionPolicy: UniformRandomTopLevelPolicy { 0.0 },
      skipInitialBootstrap: true
    )
    await vm.connectReminders()
    XCTAssertEqual(vm.phase, .permissionDenied)
    XCTAssertNotNil(vm.userMessage)
  }

  // MARK: - connectReminders — already decided

  func testConnectRemindersDeniedGoesToPermissionDenied() async {
    let mock = MockRemindersService(authorization: .denied)
    let store = makeStore()
    let vm = AppViewModel(
      reminders: mock,
      selectionStore: store,
      selectionPolicy: UniformRandomTopLevelPolicy { 0.0 },
      skipInitialBootstrap: true
    )
    await vm.connectReminders()
    XCTAssertEqual(vm.phase, .permissionDenied)
  }

  func testConnectRemindersWriteOnlyGoesToPermissionDenied() async {
    let mock = MockRemindersService(authorization: .writeOnly)
    let store = makeStore()
    let vm = AppViewModel(
      reminders: mock,
      selectionStore: store,
      selectionPolicy: UniformRandomTopLevelPolicy { 0.0 },
      skipInitialBootstrap: true
    )
    await vm.connectReminders()
    XCTAssertEqual(vm.phase, .permissionDenied)
  }

  func testConnectRemindersFullAccessSafetyValveProceedsToFocused() async {
    let task = ReminderTask(id: "r-1", title: "Do thing", isCompleted: false)
    let mock = MockRemindersService(
      authorization: .fullAccess,
      calendars: [ReminderCalendarSummary(id: "cal-1", title: "Monotask")],
      reminders: ["cal-1": [task]]
    )
    let store = makeStore(listId: "cal-1")
    let vm = AppViewModel(
      reminders: mock,
      selectionStore: store,
      selectionPolicy: UniformRandomTopLevelPolicy { 0.0 },
      skipInitialBootstrap: true
    )
    await vm.connectReminders()
    XCTAssertEqual(vm.phase, .focused)
  }

  // MARK: - Analytics

  func testConnectRemindersRecordsCtaTappedAndOutcome() async {
    let mock = MockRemindersService(authorization: .denied)
    let analytics = MockAnalyticsService()
    let store = makeStore()
    let vm = AppViewModel(
      reminders: mock,
      selectionStore: store,
      selectionPolicy: UniformRandomTopLevelPolicy { 0.0 },
      analytics: analytics,
      skipInitialBootstrap: true
    )
    await vm.connectReminders()
    XCTAssertEqual(analytics.eventCount(named: "onboarding.cta_tapped"), 1)
    XCTAssertEqual(analytics.eventCount(named: "permission.outcome"), 1)
    XCTAssertEqual(analytics.events(named: "permission.outcome").first?["result"], "denied")
  }

  func testRecordOnboardingImpressionFiresEvent() async {
    let mock = MockRemindersService(authorization: .undetermined)
    let analytics = MockAnalyticsService()
    let store = makeStore()
    let vm = AppViewModel(
      reminders: mock,
      selectionStore: store,
      selectionPolicy: UniformRandomTopLevelPolicy { 0.0 },
      analytics: analytics,
      skipInitialBootstrap: true
    )
    vm.recordOnboardingImpression()
    XCTAssertEqual(analytics.eventCount(named: "onboarding.impression"), 1)
  }
}
