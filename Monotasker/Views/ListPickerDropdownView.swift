import SwiftUI

/// Full-screen overlay that presents the list picker as a dropdown card sliding
/// from just below the navigation bar. Driven by `AppViewModel.showListPickerSheet`.
///
/// Positioned and animated independently of any sheet system so it can be shown
/// programmatically (onboarding auto-select toast, listSetup phase) and still appear
/// to originate from the nav bar title.
struct ListPickerDropdownView: View {
  @Environment(AppViewModel.self) private var model
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  /// When false (listSetup phase), tapping the scrim does nothing — the user must pick.
  let isDismissible: Bool

  @State private var isVisible = false
  @State private var showNewListAlert = false
  @State private var newListName = ""

  private let caretHeight: CGFloat = 8
  private let cardWidth: CGFloat = 260

  private var calendars: [ReminderCalendarSummary] {
    model.calendarsForSetup().sorted {
      $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
    }
  }

  var body: some View {
    GeometryReader { proxy in
      ZStack(alignment: .top) {
        // Invisible dismiss layer — no dark scrim
        if isDismissible {
          Color.clear
            .contentShape(Rectangle())
            .ignoresSafeArea()
            .onTapGesture { dismiss() }
            .accessibilityHidden(true)
        }

        // Dropdown card — scales from caret tip at nav bar bottom edge
        dropdownCard
          .frame(width: cardWidth)
          .frame(maxWidth: .infinity)
          .padding(.top, proxy.safeAreaInsets.top + 44 - caretHeight)
          .scaleEffect(isVisible ? 1 : 0.88, anchor: .top)
          .opacity(isVisible ? 1 : 0)
      }
    }
    .ignoresSafeArea()
    .onAppear {
      withAnimation(reduceMotion ? nil : .spring(response: 0.22, dampingFraction: 0.9)) {
        isVisible = true
      }
    }
    .alert("New Reminders list", isPresented: $showNewListAlert) {
      TextField("List name", text: $newListName)
      Button("Create") {
        let name = newListName
        newListName = ""
        dismiss { Task { await model.createReminderList(named: name) } }
      }
      Button("Cancel", role: .cancel) { newListName = "" }
    } message: {
      Text("Creates a new list in Reminders and switches Monotasker to it.")
        .accessibilityLabel("Creates a new list in Reminders and switches Mono Tasker to it.")
    }
  }

  // MARK: - Card

  private var dropdownCard: some View {
    VStack(spacing: 0) {
      ForEach(calendars) { cal in
        Button {
          dismiss { Task { await model.applyListChoice(cal) } }
        } label: {
          HStack {
            Text(cal.title)
              .frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: "checkmark")
              .fontWeight(.semibold)
              .foregroundStyle(Color.accentColor)
              .opacity(cal.id == model.activeListSummary?.id ? 1 : 0)
              .accessibilityHidden(true)
          }
          .padding(.horizontal, 16)
          .frame(height: 48)
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
        .accessibilityLabel(AppConfig.voiceOverName(cal.title))
        .accessibilityValue(cal.id == model.activeListSummary?.id ? "selected" : "")

        if cal != calendars.last {
          Divider().padding(.leading, 16).accessibilityHidden(true)
        }
      }

      if !calendars.isEmpty { Divider().accessibilityHidden(true) }

      Button {
        newListName = ""
        showNewListAlert = true
      } label: {
        Label("Add New List", systemImage: "plus.circle")
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.horizontal, 16)
          .frame(height: 48)
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .foregroundStyle(.primary)
    }
    .padding(.top, caretHeight)
    .background(.regularMaterial, in: DropdownBubbleShape(caretHeight: caretHeight))
    .shadow(color: .black.opacity(0.10), radius: 16, y: 6)
  }

  // MARK: - Dismiss

  private func dismiss(then action: @escaping () -> Void = {}) {
    withAnimation(
      reduceMotion ? nil : .easeIn(duration: 0.15),
      completionCriteria: .logicallyComplete
    ) {
      isVisible = false
    } completion: {
      action()
      model.showListPickerSheet = false
    }
  }
}

// MARK: - Bubble shape

/// Rounded rectangle with an upward-pointing caret triangle at the top center,
/// used as a unified shape so `.regularMaterial` fills caret and card body seamlessly.
private struct DropdownBubbleShape: Shape {
  var cornerRadius: CGFloat = 14
  var caretWidth: CGFloat = 18
  var caretHeight: CGFloat = 8

  func path(in rect: CGRect) -> Path {
    var path = Path()

    let r = min(cornerRadius, (rect.height - caretHeight) / 2)
    let caretTipX = rect.midX
    let caretLeftX = caretTipX - caretWidth / 2
    let caretRightX = caretTipX + caretWidth / 2

    let bodyTop = rect.minY + caretHeight
    let bodyLeft = rect.minX
    let bodyRight = rect.maxX
    let bodyBottom = rect.maxY

    path.move(to: CGPoint(x: bodyLeft + r, y: bodyTop))
    path.addLine(to: CGPoint(x: caretLeftX, y: bodyTop))
    path.addLine(to: CGPoint(x: caretTipX, y: rect.minY))
    path.addLine(to: CGPoint(x: caretRightX, y: bodyTop))
    path.addLine(to: CGPoint(x: bodyRight - r, y: bodyTop))
    path.addArc(center: CGPoint(x: bodyRight - r, y: bodyTop + r),
                radius: r, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
    path.addLine(to: CGPoint(x: bodyRight, y: bodyBottom - r))
    path.addArc(center: CGPoint(x: bodyRight - r, y: bodyBottom - r),
                radius: r, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
    path.addLine(to: CGPoint(x: bodyLeft + r, y: bodyBottom))
    path.addArc(center: CGPoint(x: bodyLeft + r, y: bodyBottom - r),
                radius: r, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
    path.addLine(to: CGPoint(x: bodyLeft, y: bodyTop + r))
    path.addArc(center: CGPoint(x: bodyLeft + r, y: bodyTop + r),
                radius: r, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
    path.closeSubpath()
    return path
  }
}
