import SwiftUI

struct ListPickerSheetView: View {
  @Environment(AppViewModel.self) private var model
  @State private var showNewListAlert = false
  @State private var newListName = ""
  @State private var isWorking = false

  private var calendars: [ReminderCalendarSummary] {
    model.calendarsForSetup().sorted {
      $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
    }
  }

  var body: some View {
    NavigationStack {
      List {
        ForEach(calendars) { cal in
          Button(cal.title) {
            Task {
              guard !isWorking else { return }
              isWorking = true
              await model.applyListChoice(cal)
              isWorking = false
            }
          }
          .foregroundStyle(.primary)
        }
        Button {
          newListName = ""
          showNewListAlert = true
        } label: {
          Label("Add New List", systemImage: "plus.circle")
        }
      }
      .navigationTitle("Select Reminders list")
      .navigationBarTitleDisplayMode(.inline)
      .overlay {
        if isWorking {
          ProgressView()
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
      }
    }
    .alert("New Reminders list", isPresented: $showNewListAlert) {
      TextField("List name", text: $newListName)
      Button("Create") {
        let name = newListName
        newListName = ""
        Task {
          guard !isWorking else { return }
          isWorking = true
          await model.createReminderList(named: name)
          isWorking = false
        }
      }
      Button("Cancel", role: .cancel) {
        newListName = ""
      }
    } message: {
      Text("Creates a new list in Reminders and switches Monotask to it.")
    }
  }
}
