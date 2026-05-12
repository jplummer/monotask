import SwiftUI

struct OnboardingView: View {
  @Environment(AppViewModel.self) private var model

  var body: some View {
    VStack(spacing: 0) {
      Spacer()

      // Placeholder visual — brand artwork drops in here after identity is settled.
      Image(systemName: "checklist")
        .font(.system(size: 72, weight: .light))
        .foregroundStyle(.primary.opacity(0.8))
        .padding(.bottom, 48)

      VStack(spacing: 12) {
        Text("One task at a time, from the Reminders you already have.")
          .font(.title2.weight(.semibold))
          .multilineTextAlignment(.center)

        Text("Monotask reads your Reminders to show you one task at a time.")
          .font(.body)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
      }
      .padding(.horizontal, 32)

      Spacer()

      Button {
        Task { await model.connectReminders() }
      } label: {
        Text("Connect my Reminders")
          .font(.body.weight(.semibold))
          .frame(maxWidth: .infinity)
          .padding(.vertical, 16)
      }
      .buttonStyle(.borderedProminent)
      .padding(.horizontal, 32)
      .padding(.bottom, 48)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .onAppear {
      model.recordOnboardingImpression()
    }
  }
}
