import SwiftUI

/// First-run education before the system Reminders permission prompt (bootstrap runs after completion).
struct OnboardingFlowView: View {
  let onFinished: () -> Void

  @State private var page = 0

  var body: some View {
    TabView(selection: $page) {
      welcomePage.tag(0)
      remindersPage.tag(1)
    }
    .tabViewStyle(.page)
    .indexViewStyle(.page(backgroundDisplayMode: .always))
    .background(
      LinearGradient(
        colors: [DesignColors.gradientTop, DesignColors.gradientBottom],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .ignoresSafeArea()
    )
  }

  private var welcomePage: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Welcome")
        .font(.title.weight(.semibold))
      Text("\(AppConfig.appName) picks one incomplete reminder from a list you choose and puts it on a simple note so you can focus.")
        .font(.body)
      Spacer(minLength: 0)
      Button("Next") {
        withAnimation {
          page = 1
        }
      }
      .buttonStyle(.borderedProminent)
      .frame(maxWidth: .infinity)
    }
    .padding(24)
  }

  private var remindersPage: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Reminders access")
        .font(.title.weight(.semibold))
      Text("Next, iOS will ask for Reminders access. Monotask needs full access so it can read your incomplete tasks and sync when you complete or edit.")
        .font(.body)
      Text("If access is set to write-only only, the app cannot list open tasks. You can change this anytime in Settings.")
        .font(.footnote)
        .foregroundStyle(.secondary)
      Spacer(minLength: 0)
      Button("Continue") {
        onFinished()
      }
      .buttonStyle(.borderedProminent)
      .frame(maxWidth: .infinity)
    }
    .padding(24)
  }
}
