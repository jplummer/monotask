import SwiftUI

@main
struct MonotaskerApp: App {
  private let analytics: TelemetryDeckAnalyticsService
  @State private var viewModel: AppViewModel
  @Environment(\.scenePhase) private var scenePhase

  init() {
    let analytics = TelemetryDeckAnalyticsService(
      appID: "42A77D2A-370F-4941-9D01-EC105B518BCE"
    )
    self.analytics = analytics
    _viewModel = State(initialValue: AppViewModel(
      reminders: EventKitRemindersService(),
      selectionStore: SelectionStore(),
      selectionPolicy: UniformRandomTopLevelPolicy(),
      analytics: analytics
    ))
  }

  var body: some Scene {
    WindowGroup {
      RootView()
        .environment(viewModel)
        .onChange(of: scenePhase) { _, newPhase in
          if newPhase == .active {
            analytics.record("app.foreground")
          }
        }
    }
  }
}
