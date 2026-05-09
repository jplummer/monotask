import SwiftUI

/// Brief branded screen before onboarding or the main app flow.
struct SplashView: View {
  /// Shorter auto-dismiss when the user has already completed intro once.
  var useBriefTiming: Bool
  /// Called after auto-dismiss or when the user taps to skip.
  let onFinished: () -> Void

  @State private var didFinish = false

  private var autoDismissMillis: UInt64 {
    useBriefTiming ? 550 : 1_150
  }

  var body: some View {
    ZStack {
      LinearGradient(
        colors: [DesignColors.gradientTop, DesignColors.gradientBottom],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .ignoresSafeArea()

      VStack(spacing: 12) {
        Text(AppConfig.appName)
          .font(.largeTitle.weight(.bold))
          .foregroundStyle(.primary)
        Text("One reminder at a time.")
          .font(.title3)
          .foregroundStyle(.secondary)
      }
      .padding()
    }
    .contentShape(Rectangle())
    .onTapGesture {
      finishIfNeeded()
    }
    .task {
      try? await Task.sleep(for: .milliseconds(autoDismissMillis))
      finishIfNeeded()
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(AppConfig.appName). One reminder at a time.")
    .accessibilityHint("Double tap to continue.")
  }

  private func finishIfNeeded() {
    guard !didFinish else { return }
    didFinish = true
    onFinished()
  }
}
