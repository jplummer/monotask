import SwiftUI

struct TaskFocusView: View {
  let task: ReminderTask
  @Environment(AppViewModel.self) private var model

  var body: some View {
    ZStack(alignment: .bottom) {
      PostItCard(title: task.title, notes: task.notes)

      VStack(spacing: 10) {
        actionRow
      }
      .padding(.horizontal, 16)
      .padding(.bottom, 20)
    }
    .navigationTitle(model.activeListSummary?.title ?? AppConfig.appName)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button("Switch list") {
          model.openListSetup()
        }
      }
    }
    .sheet(isPresented: Binding(
      get: { model.showAddSheet },
      set: { if !$0 { model.cancelAdd() } }
    )) {
      AddTaskSheet()
    }
    .sheet(isPresented: Binding(
      get: { model.showEditSheet },
      set: { if !$0 { model.cancelEdit() } }
    )) {
      EditTaskSheet(initialTitle: task.title, initialNotes: task.notes ?? "")
    }
    .alert(
      "That's the only task in your list right now.",
      isPresented: Binding(
        get: { model.showOnlyOneTaskAlert },
        set: { if !$0 { model.dismissOnlyOneTaskAlert() } }
      )
    ) {
      Button("Add another") {
        model.beginAddFromOnlyOneAlert()
      }
      Button("Stay here", role: .cancel) {
        model.dismissOnlyOneTaskAlert()
      }
    } message: {
      Text("Add another task to shuffle between, or stay on this one.")
    }
  }

  private var actionRow: some View {
    VStack(spacing: 8) {
      HStack(spacing: 12) {
        labeledButton(systemName: "checkmark.circle", label: "Complete") {
          Task { await model.completeCurrent() }
        }
        labeledButton(systemName: "trash", label: "Trash") {
          Task { await model.deleteCurrent() }
        }
        labeledButton(systemName: "pencil", label: "Edit") {
          model.beginEdit()
        }
      }
      HStack(spacing: 12) {
        labeledButton(systemName: "shuffle", label: "Re-roll") {
          Task { await model.reroll() }
        }
        labeledButton(systemName: "plus.circle", label: "Add") {
          model.beginAdd()
        }
      }
    }
    .padding(12)
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
  }

  private func labeledButton(systemName: String, label: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      VStack(spacing: 4) {
        Image(systemName: systemName)
          .imageScale(.large)
        Text(label)
          .font(.caption2)
      }
      .frame(maxWidth: .infinity)
    }
    .buttonStyle(.bordered)
    .tint(.primary)
  }
}
