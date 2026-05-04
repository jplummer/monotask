import SwiftUI

struct EditTaskSheet: View {
  @Environment(AppViewModel.self) private var model
  @State private var title: String
  @State private var notes: String

  init(initialTitle: String, initialNotes: String) {
    _title = State(initialValue: initialTitle)
    _notes = State(initialValue: initialNotes)
  }

  var body: some View {
    NavigationStack {
      Form {
        Section("Task") {
          TextField("Title", text: $title)
          TextField("Notes", text: $notes, axis: .vertical)
            .lineLimit(3...8)
        }
      }
      .navigationTitle("Edit task")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            model.cancelEdit()
          }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Save") {
            Task { await model.confirmEdit(title: title, notes: notes) }
          }
          .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
      }
    }
    .presentationDetents([.medium, .large])
  }
}
