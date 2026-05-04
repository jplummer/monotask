import SwiftUI

struct PostItCard: View {
  let title: String
  let notes: String?
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    ZStack {
      LinearGradient(
        colors: [DesignColors.gradientTop, DesignColors.gradientBottom],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .ignoresSafeArea()

      VStack(alignment: .leading, spacing: 12) {
        Text(title)
          .font(.largeTitle.weight(.semibold))
          .foregroundStyle(.primary)
          .multilineTextAlignment(.leading)
          .frame(maxWidth: .infinity, alignment: .leading)
        if let notes, !notes.isEmpty {
          Text(notes)
            .font(.body)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.leading)
            .lineLimit(6)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        Spacer(minLength: 0)
      }
      .padding(28)
      .frame(maxWidth: .infinity, minHeight: 280, alignment: .topLeading)
      .background {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
          .fill(DesignColors.postItPaper)
          .shadow(color: .black.opacity(0.18), radius: 12, y: 6)
      }
      .padding(.horizontal, 24)
      .rotationEffect(.degrees(reduceMotion ? 0 : 1))
    }
  }
}
