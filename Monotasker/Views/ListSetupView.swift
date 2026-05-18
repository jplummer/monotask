import SwiftUI

struct ListSetupView: View {
  @Environment(AppViewModel.self) private var model
  @State private var selectedId: String = ""
  @State private var isWorking = false

  private var calendars: [ReminderCalendarSummary] {
    model.calendarsForSetup()
  }

  var body: some View {
    Form {
      Section {
        Text("Choose where Monotasker reads tasks from. You can create a new list named \(AppConfig.defaultListName) or pick an existing Reminders list.")
          .font(.footnote)
          .foregroundStyle(.secondary)
      }
      if !calendars.isEmpty {
        Section("Existing lists") {
          Picker("List", selection: $selectedId) {
            ForEach(calendars) { cal in
              Text(cal.title).tag(cal.id)
            }
          }
          Button("Use selected list") {
            guard let summary = calendars.first(where: { $0.id == selectedId }) else { return }
            Task {
              isWorking = true
              await model.applyListChoice(summary)
              isWorking = false
            }
          }
          .disabled(isWorking)
        }
      }
      Section {
        Button("Create \(AppConfig.defaultListName) list") {
          Task {
            isWorking = true
            await model.createDefaultList()
            isWorking = false
          }
        }
        .disabled(isWorking)
      }
    }
    .navigationTitle("Choose list")
    .onAppear {
      if selectedId.isEmpty, let first = calendars.first {
        selectedId = first.id
      }
    }
    .overlay {
      if isWorking {
        ProgressView()
          .padding()
          .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
      }
    }
  }
}
