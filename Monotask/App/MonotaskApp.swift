import SwiftUI

@main
struct MonotaskApp: App {
  @State private var viewModel = AppViewModel(
    reminders: EventKitRemindersService(),
    selectionStore: SelectionStore(),
    selectionPolicy: UniformRandomTopLevelPolicy(),
    skipInitialBootstrap: true
  )

  var body: some Scene {
    WindowGroup {
      RootView()
        .environment(viewModel)
    }
  }
}
