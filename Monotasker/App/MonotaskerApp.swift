import SwiftUI

@main
struct MonotaskerApp: App {
  @State private var viewModel: AppViewModel
  @Environment(\.scenePhase) private var scenePhase

  static var isScreenshotMode: Bool {
    CommandLine.arguments.contains("--screenshots")
  }

  init() {
    let reminders: any RemindersService = Self.isScreenshotMode
      ? MonotaskerApp.screenshotRemindersService()
      : EventKitRemindersService()
    _viewModel = State(initialValue: AppViewModel(
      reminders: reminders,
      selectionStore: SelectionStore(),
      selectionPolicy: UniformRandomTopLevelPolicy(),
      analytics: nil,
      suppressToasts: Self.isScreenshotMode
    ))
  }

  private static func screenshotRemindersService() -> MockRemindersService {
    let listID = "screenshot-list"
    let tasks: [ReminderTask] = [
      ReminderTask(id: "t1", title: "Install pegboard", notes: "Need to find the right wall anchors first."),
      ReminderTask(id: "t2", title: "Wash the car", notes: "Vacuum out the trunk while you're at it."),
      ReminderTask(id: "t3", title: "Rearrange the living room", notes: "Try the couch under the window."),
      ReminderTask(id: "t4", title: "Clear out the junk drawer"),
      ReminderTask(id: "t5", title: "Schedule the dentist"),
    ]
    return MockRemindersService(
      authorization: .fullAccess,
      calendars: [ReminderCalendarSummary(id: listID, title: AppConfig.appName)],
      reminders: [listID: tasks]
    )
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
