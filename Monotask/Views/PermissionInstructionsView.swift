import SwiftUI

struct PermissionInstructionsView: View {
  @Environment(AppViewModel.self) private var model

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        Text("Reminders access")
          .font(.title2.weight(.semibold))
        Text(
          "Monotask needs full access to Reminders so it can read incomplete tasks and update them when you complete or edit."
        )
        .font(.body)
        Text("If access was denied or set to write-only only, open Settings and enable full access for Monotask under Privacy & Security → Reminders.")
          .font(.body)
        HStack(spacing: 12) {
          Button("Open Settings") {
            model.openAppSettings()
          }
          .buttonStyle(.borderedProminent)
          Button("Try again") {
            Task { await model.refreshAfterSettings() }
          }
          .buttonStyle(.bordered)
        }
        .padding(.top, 8)
      }
      .padding(24)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}
