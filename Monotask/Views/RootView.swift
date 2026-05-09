import SwiftUI

private enum LaunchPhase {
  case splash
  case onboarding
  case app
}

struct RootView: View {
  @Environment(AppViewModel.self) private var model
  @State private var launchPhase: LaunchPhase = .splash

  var body: some View {
    Group {
      switch launchPhase {
      case .splash:
        SplashView(useBriefTiming: model.hasCompletedIntroFlow) {
          advanceFromSplash()
        }
      case .onboarding:
        OnboardingFlowView {
          model.markIntroCompleted()
          launchPhase = .app
          Task { await model.start() }
        }
      case .app:
        MainAppPhaseContent()
      }
    }
    .animation(.easeInOut(duration: 0.2), value: launchPhase)
    .alert("Notice", isPresented: Binding(
      get: { model.userMessage != nil },
      set: { if !$0 { model.userMessage = nil } }
    )) {
      Button("OK", role: .cancel) {
        model.userMessage = nil
      }
    } message: {
      Text(model.userMessage ?? "")
    }
  }

  private func advanceFromSplash() {
    if model.hasCompletedIntroFlow {
      launchPhase = .app
      Task { await model.start() }
    } else {
      launchPhase = .onboarding
    }
  }
}

/// Content gated by `AppPhase` after splash / onboarding (permission, setup, empty, focus).
struct MainAppPhaseContent: View {
  @Environment(AppViewModel.self) private var model

  var body: some View {
    Group {
      switch model.phase {
      case .bootstrapping:
        ProgressView("Loading…")
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      case .permissionDenied:
        PermissionInstructionsView()
      case .listSetup:
        NavigationStack {
          ListSetupView()
        }
      case .emptyList:
        NavigationStack {
          EmptyListView()
        }
      case .focused:
        NavigationStack {
          if let task = model.currentTask {
            TaskFocusView(task: task)
          } else {
            ProgressView("Loading…")
          }
        }
      }
    }
    .animation(.easeInOut(duration: 0.22), value: model.phase)
  }
}
