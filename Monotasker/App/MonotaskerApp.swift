import SwiftUI

@main
struct MonotaskerApp: App {
  @State private var viewModel: AppViewModel
  @Environment(\.scenePhase) private var scenePhase

  init() {
    _viewModel = State(initialValue: AppViewModel(
      reminders: EventKitRemindersService(),
      selectionStore: SelectionStore(),
      selectionPolicy: UniformRandomTopLevelPolicy(),
      analytics: nil
    ))
  }

  var body: some Scene {
    WindowGroup {
      RootView()
        .environment(viewModel)
        .task {
          viewModel.configureAnalytics(
            TelemetryDeckAnalyticsService(appID: AppConfig.telemetryDeckAppID)
          )
        }
        .onChange(of: scenePhase) { _, newPhase in
          if newPhase == .active {
            Task { await viewModel.sceneDidBecomeActive() }
          }
        }
    }
  }
}
