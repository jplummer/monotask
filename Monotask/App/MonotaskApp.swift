import SwiftUI

@main
struct MonotaskApp: App {
  @State private var viewModel = AppViewModel(
    reminders: EventKitRemindersService(),
    selectionStore: SelectionStore(),
    selectionPolicy: UniformRandomTopLevelPolicy()
  )

  var body: some Scene {
    WindowGroup {
      RootView()
        .environment(viewModel)
    }
  }
}
