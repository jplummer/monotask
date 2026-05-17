import SwiftUI

struct BootstrapCardView: View {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var showSpinner = false
  @State private var frontCardAngle: Double = 0
  // PostItCard requires a focus binding; unused here because isEditing is always false.
  @FocusState private var dummyFocus: PostItEditFocus?

  // Matches TaskFocusView exactly.
  private let horizontalPadding: CGFloat = 24
  private let bottomChromeReserve: CGFloat = 72

  var body: some View {
    GeometryReader { proxy in
      let side = max(200, min(proxy.size.width - horizontalPadding * 2, proxy.size.height - bottomChromeReserve))
      PostItCard(
        squareSide: side,
        isEditing: false,
        displayTitle: "Monotask",
        displayNotes: "Get one thing done at a time",
        editTitle: .constant(""),
        editNotes: .constant(""),
        focus: $dummyFocus,
        stackedCardsCount: 3,
        colorIndex: 0,
        frontCardRotation: reduceMotion ? 0 : frontCardAngle
      )
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .overlay(alignment: .bottom) {
      if showSpinner {
        ProgressView()
          .padding(.bottom, 60)
          .transition(.opacity)
      }
    }
    .onAppear {
      frontCardAngle = Double.random(in: -2.5...2.5)
    }
    .task {
      try? await Task.sleep(for: .milliseconds(300))
      withAnimation { showSpinner = true }
    }
  }
}
