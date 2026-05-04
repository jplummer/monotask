import EventKit
import Foundation

/// One incomplete reminder surfaced in the UI (top-level only; subtasks excluded at fetch time).
struct ReminderTask: Identifiable, Equatable, Hashable, Sendable {
  let id: String
  var title: String
  var notes: String?
  var isCompleted: Bool

  init(id: String, title: String, notes: String? = nil, isCompleted: Bool = false) {
    self.id = id
    self.title = title
    self.notes = notes
    self.isCompleted = isCompleted
  }

  init(from reminder: EKReminder) {
    id = reminder.calendarItemIdentifier
    title = reminder.title ?? ""
    notes = reminder.notes
    isCompleted = reminder.isCompleted
  }
}
