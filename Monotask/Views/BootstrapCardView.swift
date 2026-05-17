import SwiftUI

struct BootstrapCardView: View {
  @State private var showSpinner = false
  // PostItCard requires a focus binding; unused here because isEditing is always false.
  @FocusState private var dummyFocus: PostItEditFocus?
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    GeometryReader { proxy in
      let side = max(200, min(proxy.size.width - 48, proxy.size.height))
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
        frontCardRotation: reduceMotion ? 0 : 2.0
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
    .task {
      try? await Task.sleep(for: .milliseconds(300))
      withAnimation { showSpinner = true }
    }
  }
}
