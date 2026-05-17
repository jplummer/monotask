import EventKit
import Foundation

/// Live Reminders access via `EKEventStore`.
final class EventKitRemindersService: RemindersService, @unchecked Sendable {
  // Lazy so EKEventStore is not created until after the first SwiftUI frame renders.
  // All access paths go through AppViewModel (@MainActor), so lazy is safe here.
  private lazy var store = EKEventStore()

  func currentAuthorization() -> RemindersAuthorization {
    let status = EKEventStore.authorizationStatus(for: .reminder)
    switch status {
    case .notDetermined:
      return .undetermined
    case .restricted, .denied:
      return .denied
    case .writeOnly:
      return .writeOnly
    case .fullAccess:
      return .fullAccess
    @unknown default:
      return .denied
    }
  }

  func requestFullAccess() async throws -> Bool {
    try await store.requestFullAccessToReminders()
  }

  func reminderCalendars() -> [ReminderCalendarSummary] {
    store.calendars(for: .reminder).map(summary(from:))
  }

  func calendar(withIdentifier id: String) -> ReminderCalendarSummary? {
    guard let cal = store.calendar(withIdentifier: id) else { return nil }
    return summary(from: cal)
  }

  func firstCalendar(named title: String) -> ReminderCalendarSummary? {
    store.calendars(for: .reminder).first(where: { $0.title == title }).map(summary(from:))
  }

  func createReminderList(title: String) throws -> ReminderCalendarSummary {
    let cal = EKCalendar(for: .reminder, eventStore: store)
    cal.title = title
    guard
      let source = store.defaultCalendarForNewReminders()?.source
        ?? store.sources.first(where: { $0.sourceType == .calDAV })
        ?? store.sources.first
    else {
      throw RemindersServiceError.noWritableSource
    }
    cal.source = source
    try store.saveCalendar(cal, commit: true)
    return summary(from: cal)
  }

  func fetchIncompleteTopLevel(calendarId: String) async throws -> [ReminderTask] {
    guard let calendar = store.calendar(withIdentifier: calendarId) else {
      throw RemindersServiceError.calendarNotFound
    }
    return try await withCheckedThrowingContinuation { continuation in
      let predicate = store.predicateForIncompleteReminders(
        withDueDateStarting: nil,
        ending: nil,
        calendars: [calendar]
      )
      store.fetchReminders(matching: predicate) { (list: [EKReminder]?) in
        // Public EventKit does not expose parent/subtask relationships on `EKReminder`.
        // The pool is all incomplete reminders in this calendar (matches Reminders list contents).
        let ekReminders = list ?? []
        let tasks = ekReminders.map { ReminderTask(from: $0) }
        continuation.resume(returning: tasks)
      }
    }
  }

  func createReminder(title: String, notes: String?, calendarId: String) throws -> ReminderTask {
    guard let calendar = store.calendar(withIdentifier: calendarId) else {
      throw RemindersServiceError.calendarNotFound
    }
    let reminder = EKReminder(eventStore: store)
    reminder.calendar = calendar
    reminder.title = title
    reminder.notes = notes
    try store.save(reminder, commit: true)
    return ReminderTask(from: reminder)
  }

  func updateReminder(id: String, title: String, notes: String?) throws {
    guard let item = store.calendarItem(withIdentifier: id) as? EKReminder else {
      throw RemindersServiceError.reminderNotFound
    }
    item.title = title
    item.notes = notes
    try store.save(item, commit: true)
  }

  func completeReminder(id: String) throws {
    guard let item = store.calendarItem(withIdentifier: id) as? EKReminder else {
      throw RemindersServiceError.reminderNotFound
    }
    item.isCompleted = true
    try store.save(item, commit: true)
  }

  func deleteReminder(id: String) throws {
    guard let item = store.calendarItem(withIdentifier: id) as? EKReminder else {
      throw RemindersServiceError.reminderNotFound
    }
    try store.remove(item, commit: true)
  }

  func eventStoreChanges() -> AsyncStream<Void> {
    AsyncStream { continuation in
      // object: nil — avoids forcing EKEventStore initialization at observer-registration time.
      // EKEventStoreChanged is only ever posted by EventKit, so nil is safe here.
      let token = NotificationCenter.default.addObserver(
        forName: .EKEventStoreChanged,
        object: nil,
        queue: .main
      ) { _ in
        continuation.yield()
      }
      continuation.onTermination = { _ in
        NotificationCenter.default.removeObserver(token)
      }
    }
  }

  private func summary(from calendar: EKCalendar) -> ReminderCalendarSummary {
    ReminderCalendarSummary(id: calendar.calendarIdentifier, title: calendar.title)
  }
}
