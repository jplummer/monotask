import SwiftUI

struct PermissionInstructionsView: View {
  @Environment(AppViewModel.self) private var model

  var body: some View {
    GeometryReader { proxy in
      let side = max(200, min(proxy.size.width - 48, proxy.size.height - 200))
      let upShift = proxy.size.height * PostItCardLayout.verticalUpShiftRatio
      let cardCY = proxy.size.height / 2 - upShift

      ZStack {
        LinearGradient(
          colors: [DesignColors.gradientTop, DesignColors.gradientBottom],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        VStack(spacing: 28) {
          // Ghost card: transparent fill, dashed border, slight tilt
          ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
              .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [8, 6]))
              .foregroundStyle(.primary.opacity(0.35))

            VStack(spacing: 16) {
              Image(systemName: "lock.fill")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(.primary.opacity(0.7))
              Text("Reminders access needed")
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)
              Text("Open Settings and allow Reminders access to use Monotask.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            }
            .padding(20)
          }
          .frame(width: side, height: side)
          .rotationEffect(.degrees(-2))

          // Action buttons below the ghost card
          VStack(spacing: 12) {
            Button("Open Settings") {
              model.openAppSettings()
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: 260)

            Button("Try again") {
              Task { await model.refreshAfterSettings() }
            }
            .buttonStyle(.plain)
            .foregroundStyle(.primary)
          }
        }
        .frame(width: proxy.size.width)
        .position(x: proxy.size.width / 2, y: cardCY + side / 4)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}
