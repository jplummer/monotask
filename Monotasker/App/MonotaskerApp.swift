import SwiftUI

@main
struct MonotaskerApp: App {
  @State private var viewModel: AppViewModel
  @Environment(\.scenePhase) private var scenePhase

  static var isScreenshotMode: Bool {
    CommandLine.arguments.contains("--screenshots")
  }

  init() {
    if Self.isScreenshotMode {
      let (service, store) = MonotaskerApp.screenshotFixtures()
      _viewModel = State(initialValue: AppViewModel(
        reminders: service,
        selectionStore: store,
        selectionPolicy: UniformRandomTopLevelPolicy(),
        analytics: nil,
        suppressToasts: true
      ))
    } else {
      _viewModel = State(initialValue: AppViewModel(
        reminders: EventKitRemindersService(),
        selectionStore: SelectionStore(),
        selectionPolicy: UniformRandomTopLevelPolicy(),
        analytics: nil
      ))
    }
  }

  private static func screenshotFixtures() -> (MockRemindersService, SelectionStore) {
    let listID = "list-weekend"
    let tasks: [ReminderTask] = [
      ReminderTask(id: "t1", title: "Install pegboard in the garage", notes: "Need to find the right wall anchors first."),
      ReminderTask(id: "t2", title: "Build the raised garden bed", notes: "Cedar boards are in the basement already."),
      ReminderTask(id: "t3", title: "Repaint the front door", notes: "Navy or black — decide before buying."),
      ReminderTask(id: "t4", title: "Fix the back fence gate"),
      ReminderTask(id: "t5", title: "Hang the new mirror in the hallway"),
    ]
    let calendars: [ReminderCalendarSummary] = [
      ReminderCalendarSummary(id: listID, title: "Weekend Projects"),
      ReminderCalendarSummary(id: "list-groceries", title: "Groceries"),
      ReminderCalendarSummary(id: "list-household", title: "Household"),
      ReminderCalendarSummary(id: "list-restaurants", title: "Restaurants to Try"),
      ReminderCalendarSummary(id: "list-reading", title: "Reading List"),
      ReminderCalendarSummary(id: "list-reminders", title: AppConfig.appName),
    ]
    let service = MockRemindersService(
      authorization: .fullAccess,
      calendars: calendars,
      reminders: [listID: tasks]
    )
    // Pre-seed selection so bootstrap resolves to Weekend Projects with a fixed task.
    // Pinning "t1" means color index 0 (warm cream) — avoids pink clashing with the gradient.
    let store = SelectionStore(defaults: UserDefaults(suiteName: "screenshot") ?? .standard)
    store.selectedListIdentifier = listID
    store.setReminderID("t1", forList: listID)
    return (service, store)
  }

  var body: some Scene {
    WindowGroup {
      RootView()
        .environment(viewModel)
        .task {
          if !Self.isScreenshotMode {
            viewModel.configureAnalytics(
              TelemetryDeckAnalyticsService(appID: AppConfig.telemetryDeckAppID)
            )
          }
        }
        .onChange(of: scenePhase) { _, newPhase in
          if newPhase == .active {
            Task { await viewModel.sceneDidBecomeActive() }
          }
        }
    }
  }
}
