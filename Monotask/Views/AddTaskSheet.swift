import SwiftUI

struct AddTaskSheet: View {
  @Environment(AppViewModel.self) private var model
  @State private var title = ""
  @State private var notes = ""
  @FocusState private var titleFocused: Bool

  var body: some View {
    NavigationStack {
      Form {
        Section("Task") {
          TextField("Title", text: $title)
            .focused($titleFocused)
          TextField("Notes", text: $notes, axis: .vertical)
            .lineLimit(3...8)
        }
      }
      .navigationTitle("New task")
      .navigationBarTitleDisplayMode(.inline)
      .onAppear { titleFocused = true }
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            model.cancelAdd()
          }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Save") {
            Task { await model.confirmAdd(title: title, notes: notes) }
          }
          .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
      }
    }
    .presentationDetents([.medium, .large])
  }
}
