import SwiftUI

struct EmptyListView: View {
  @Environment(AppViewModel.self) private var model
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  @State private var isEditing = false
  @State private var title = ""
  @State private var notes = ""
  @State private var isSaving = false
  @State private var frontCardAngle: Double = 1.5
  @FocusState private var editFocus: PostItEditFocus?
  @State private var showNewListAlert = false
  @State private var newListName = ""

  private let horizontalPadding: CGFloat = 24
  /// Space reserved so the post-it does not cover the bottom chrome area (points).
  private let bottomChromeReserve: CGFloat = 72

  var body: some View {
    GeometryReader { proxy in
      let size = proxy.size
      let widthBudget = size.width - horizontalPadding * 2
      let heightBudget = size.height - bottomChromeReserve
      let side = max(200, min(widthBudget, heightBudget))
      let upShift = size.height * PostItCardLayout.verticalUpShiftRatio
      let cardCY = size.height / 2 - upShift

      let angle = reduceMotion ? 0.0 : frontCardAngle

      ZStack {
        // Card — switches between static placeholder and edit mode
        PostItCard(
          squareSide: side,
          isEditing: isEditing,
          displayTitle: "What do you need to do?",
          displayNotes: "Add a task to your Monotask list",
          editTitle: $title,
          editNotes: $notes,
          focus: $editFocus,
          stackedCardsCount: 1,
          colorIndex: 0,
          frontCardRotation: angle
        )
        .position(x: size.width / 2, y: cardCY)

        // Static placeholder chrome — pencil on the card, plus below
        if !isEditing {
          // Pencil: bottom-right of the card, rotated with card tilt
          toolbarIconButton(systemName: "pencil", accessibilityLabel: "Edit") {
            beginEdit()
          }
          .rotationEffect(.degrees(angle))
          .position(PostItCardLayout.rotatedPoint(
            lx: side / 2 - 6 - 22,
            ly: side / 2 - 6 - 22,
            cx: size.width / 2,
            cy: cardCY,
            degrees: angle
          ))

          // Plus: below the card center, upright
          toolbarIconButton(systemName: "plus.circle", accessibilityLabel: "Add task") {
            beginEdit()
          }
          .position(x: size.width / 2, y: cardCY + side / 2 + 36)
        }

        // Done button — floating above safe area when editing
        if isEditing {
          VStack {
            Spacer()
            HStack {
              Spacer()
              Button("Done") {
                Task { await submitEdit() }
              }
              .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
              .fontWeight(.semibold)
              .padding(.horizontal, 24)
              .padding(.bottom, max(proxy.safeAreaInsets.bottom, 12) + 8)
            }
          }
        }
      }
      .frame(width: size.width, height: size.height)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .toolbar {
      ToolbarItem(placement: .principal) {
        if !isEditing {
          listPickerMenu
        }
      }
      ToolbarItem(placement: .topBarLeading) {
        if isEditing {
          Button("Cancel") { cancelEdit() }
        }
      }
    }
    .navigationBarTitleDisplayMode(.inline)
    .onAppear {
      frontCardAngle = reduceMotion ? 0 : Double.random(in: -2.5...2.5)
      // Defer past the first render cycle to avoid conflicting with the view's entry animation.
      DispatchQueue.main.async { beginEdit() }
    }
    .sheet(isPresented: Binding(
      get: { model.showListPickerSheet },
      set: { if !$0 { model.showListPickerSheet = false } }
    )) {
      ListPickerSheetView()
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    .alert("New Reminders list", isPresented: $showNewListAlert) {
      TextField("List name", text: $newListName)
      Button("Create") {
        let name = newListName
        newListName = ""
        Task { await model.createReminderList(named: name) }
      }
      Button("Cancel", role: .cancel) { newListName = "" }
    } message: {
      Text("Creates a new list in Reminders and switches Monotask to it.")
    }
  }

  // MARK: - List picker menu

  private var listPickerMenu: some View {
    Menu {
      Section("Select Reminders list") {
        let calendars = model.calendarsForSetup().sorted {
          $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
        }
        let activeId = model.activeListSummary?.id
        ForEach(calendars) { cal in
          Button {
            Task { await model.applyListChoice(cal) }
          } label: {
            if cal.id == activeId {
              Label(cal.title, systemImage: "checkmark")
            } else {
              Text(cal.title)
            }
          }
        }
      }
      Divider()
      Button {
        newListName = ""
        showNewListAlert = true
      } label: {
        Label("Add New List", systemImage: "plus.circle")
      }
    } label: {
      HStack(spacing: 6) {
        Text(model.activeListSummary?.title ?? AppConfig.appName)
          .font(.headline)
          .lineLimit(1)
        Image(systemName: "chevron.down")
          .font(.caption.weight(.semibold))
          .foregroundStyle(.secondary)
      }
      .frame(width: 220)
      .transaction { $0.animation = nil }
    }
    .accessibilityLabel("Reminders list, \(model.activeListSummary?.title ?? AppConfig.appName)")
    .accessibilityHint("Opens list of Reminders lists")
  }

  // MARK: - Icon button

  private func toolbarIconButton(systemName: String, accessibilityLabel: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      Image(systemName: systemName)
        .imageScale(.large)
        .frame(width: 44, height: 44)
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .foregroundStyle(.primary)
    .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
    .accessibilityLabel(accessibilityLabel)
  }

  // MARK: - Edit lifecycle

  private func beginEdit() {
    isEditing = true
    editFocus = .title
  }

  private func cancelEdit() {
    isSaving = false  // defensive: reset in case submitEdit had an early exit
    title = ""
    notes = ""
    isEditing = false
    editFocus = nil
  }

  private func submitEdit() async {
    isSaving = true
    let notesValue = notes.trimmingCharacters(in: .whitespacesAndNewlines)
    await model.addFromEmpty(title: title, notes: notesValue.isEmpty ? nil : notesValue)
    title = ""
    notes = ""
    isSaving = false
    isEditing = false
    editFocus = nil
  }
}
