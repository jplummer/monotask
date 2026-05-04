import SwiftUI

struct EmptyListView: View {
  @Environment(AppViewModel.self) private var model
  @State private var title = ""
  @State private var notes = ""
  @State private var isSaving = false

  var body: some View {
    ZStack {
      LinearGradient(
        colors: [DesignColors.gradientTop, DesignColors.gradientBottom],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .ignoresSafeArea()

      VStack(alignment: .leading, spacing: 16) {
        Text("No open tasks")
          .font(.title2.weight(.semibold))
        Text("Add your first task to this list. It appears on the post-it as soon as you save.")
          .font(.body)
          .foregroundStyle(.secondary)
        TextField("Title", text: $title)
          .textFieldStyle(.roundedBorder)
        TextField("Notes (optional)", text: $notes, axis: .vertical)
          .textFieldStyle(.roundedBorder)
          .lineLimit(3...6)
        Button("Add task") {
          Task {
            isSaving = true
            await model.addFromEmpty(title: title, notes: notes)
            title = ""
            notes = ""
            isSaving = false
          }
        }
        .buttonStyle(.borderedProminent)
        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
        Button("Add with full form…") {
          model.beginAdd()
        }
        .buttonStyle(.bordered)
        Spacer()
      }
      .padding(24)
    }
    .navigationTitle(model.activeListSummary?.title ?? "Monotask")
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
  }
}
