import SwiftUI

struct PermissionInstructionsView: View {
  @Environment(AppViewModel.self) private var model

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        Text("Reminders access needed")
          .font(.title2.weight(.semibold))
        Text(
          "Monotask needs Full Access to Reminders to read and manage your tasks. If you chose \"Add Only\", please switch to Full Access."
        )
        .font(.body)
        Text("In Settings, go to Privacy & Security → Reminders → Monotask and choose Full Access.")
          .font(.body)
          .foregroundStyle(.secondary)
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
