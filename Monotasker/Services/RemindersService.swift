import Foundation

enum RemindersAuthorization: Equatable, Sendable {
  case undetermined
  case denied
  case writeOnly
  case fullAccess
}

enum RemindersServiceError: Error, Equatable, Sendable {
  case noWritableSource
  case reminderNotFound
  case calendarNotFound
}

/// Stable Reminders list identity for UI and persistence (`EKCalendar.calendarIdentifier`).
struct ReminderCalendarSummary: Identifiable, Equatable, Hashable, Sendable {
  let id: String
  let title: String
}

/// Abstraction over EventKit for tests and previews.
protocol RemindersService: AnyObject, Sendable {
  func currentAuthorization() -> RemindersAuthorization
  func requestFullAccess() async throws -> Bool
  func reminderCalendars() -> [ReminderCalendarSummary]
  func calendar(withIdentifier id: String) -> ReminderCalendarSummary?
  func firstCalendar(named title: String) -> ReminderCalendarSummary?
  func createReminderList(title: String) throws -> ReminderCalendarSummary
  func fetchIncompleteTopLevel(calendarId: String) async throws -> [ReminderTask]
  func createReminder(title: String, notes: String?, calendarId: String) throws -> ReminderTask
  func updateReminder(id: String, title: String, notes: String?) throws
  func completeReminder(id: String) throws
  func deleteReminder(id: String) throws
  func eventStoreChanges() -> AsyncStream<Void>
}
