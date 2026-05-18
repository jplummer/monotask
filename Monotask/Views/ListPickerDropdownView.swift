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

  private var calendars: [ReminderCalendarSummary] {
    model.calendarsForSetup().sorted {
      $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
    }
  }

  var body: some View {
    GeometryReader { proxy in
      ZStack(alignment: .top) {
        // Scrim — full screen, tappable when dismissible
        Color.black
          .opacity(isVisible ? 0.28 : 0)
          .ignoresSafeArea()
          .onTapGesture { if isDismissible { dismiss() } }
          .allowsHitTesting(isVisible)
          .animation(reduceMotion ? .none : .easeOut(duration: 0.2), value: isVisible)

        // Dropdown card — slides from just below the nav bar
        dropdownCard
          .padding(.horizontal, 12)
          .padding(.top, proxy.safeAreaInsets.top + 44 + 6)
          .offset(y: isVisible ? 0 : -12)
          .opacity(isVisible ? 1 : 0)
          .animation(
            reduceMotion ? .none : .spring(response: 0.3, dampingFraction: 0.82),
            value: isVisible
          )
      }
    }
    .ignoresSafeArea()
    .onAppear { isVisible = true }
    .alert("New Reminders list", isPresented: $showNewListAlert) {
      TextField("List name", text: $newListName)
      Button("Create") {
        let name = newListName
        newListName = ""
        dismiss { Task { await model.createReminderList(named: name) } }
      }
      Button("Cancel", role: .cancel) { newListName = "" }
    } message: {
      Text("Creates a new list in Reminders and switches Monotask to it.")
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
          }
          .padding(.horizontal, 16)
          .frame(height: 48)
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)

        if cal != calendars.last {
          Divider().padding(.leading, 16)
        }
      }

      if !calendars.isEmpty { Divider() }

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
    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    .shadow(color: .black.opacity(0.15), radius: 20, y: 8)
  }

  // MARK: - Dismiss

  private func dismiss(then action: @escaping () -> Void = {}) {
    withAnimation(
      reduceMotion ? .none : .easeOut(duration: 0.2),
      completionCriteria: .logicallyComplete
    ) {
      isVisible = false
    } completion: {
      action()
      model.showListPickerSheet = false
    }
  }
}
