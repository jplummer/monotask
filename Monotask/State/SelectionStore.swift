import Foundation

/// Persists the active Reminders list and the last focused reminder across launches.
final class SelectionStore: @unchecked Sendable {
  private let defaults: UserDefaults
  private let listKey = "monotask.selectedListIdentifier"
  private let reminderKey = "monotask.selectedReminderIdentifier"
  private let introKey = "monotask.hasCompletedIntroFlow"

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
  }

  var selectedListIdentifier: String? {
    get { defaults.string(forKey: listKey) }
    set {
      if let newValue {
        defaults.set(newValue, forKey: listKey)
      } else {
        defaults.removeObject(forKey: listKey)
      }
    }
  }

  var selectedReminderIdentifier: String? {
    get { defaults.string(forKey: reminderKey) }
    set {
      if let newValue {
        defaults.set(newValue, forKey: reminderKey)
      } else {
        defaults.removeObject(forKey: reminderKey)
      }
    }
  }

  func clearReminderSelection() {
    defaults.removeObject(forKey: reminderKey)
  }

  func clearAll() {
    defaults.removeObject(forKey: listKey)
    defaults.removeObject(forKey: reminderKey)
  }

  /// True after the user finishes first-run onboarding (splash education screens before bootstrap).
  var hasCompletedIntroFlow: Bool {
    get { defaults.bool(forKey: introKey) }
    set { defaults.set(newValue, forKey: introKey) }
  }
}
