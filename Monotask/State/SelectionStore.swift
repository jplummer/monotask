import Foundation

/// Persists the active Reminders list and the last focused reminder per list across launches.
final class SelectionStore: @unchecked Sendable {
  private let defaults: UserDefaults
  private let listKey = "monotask.selectedListIdentifier"
  // Legacy single-reminder key — kept only for one-time migration on first launch after upgrade.
  private let legacyReminderKey = "monotask.selectedReminderIdentifier"
  private let mapKey = "monotask.listReminderMap"
  private let mapOrderKey = "monotask.listReminderMapOrder"
  private let mapLimit = 50

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
    migrateLegacyReminderIfNeeded()
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

  // MARK: - Per-list reminder map

  /// Returns the last focused reminder ID for the given list, or nil if none recorded.
  func reminderID(forList listID: String) -> String? {
    let map = defaults.dictionary(forKey: mapKey) as? [String: String] ?? [:]
    return map[listID]
  }

  /// Records the last focused reminder for a list. Marks it as most recently used and
  /// prunes the oldest entry if the map exceeds the limit.
  func setReminderID(_ reminderID: String, forList listID: String) {
    mutateMap { map, order in
      map[listID] = reminderID
      order.removeAll(where: { $0 == listID })
      order.append(listID)
      if order.count > mapLimit {
        let oldest = order.removeFirst()
        map.removeValue(forKey: oldest)
      }
    }
  }

  /// Clears the stored reminder ID for the given list (e.g. when that list's pool becomes empty).
  func clearReminderID(forList listID: String) {
    guard reminderID(forList: listID) != nil else { return }
    mutateMap { map, order in
      map.removeValue(forKey: listID)
      order.removeAll(where: { $0 == listID })
    }
  }

  func clearAll() {
    defaults.removeObject(forKey: listKey)
    defaults.removeObject(forKey: mapKey)
    defaults.removeObject(forKey: mapOrderKey)
    defaults.removeObject(forKey: legacyReminderKey)
  }

  // MARK: - Migration

  /// One-time migration: if the new map is empty and the legacy single-reminder fields are
  /// present, seeds the map with that pair so existing users don't lose their place.
  private func migrateLegacyReminderIfNeeded() {
    let map = defaults.dictionary(forKey: mapKey) as? [String: String] ?? [:]
    guard map.isEmpty,
          let listID = defaults.string(forKey: listKey),
          let reminderID = defaults.string(forKey: legacyReminderKey)
    else { return }
    setReminderID(reminderID, forList: listID)
    defaults.removeObject(forKey: legacyReminderKey)
  }

  // MARK: - Private

  /// Loads the map and order arrays, passes them to `body` for mutation, then writes both back.
  private func mutateMap(_ body: (inout [String: String], inout [String]) -> Void) {
    var map = defaults.dictionary(forKey: mapKey) as? [String: String] ?? [:]
    var order = defaults.array(forKey: mapOrderKey) as? [String] ?? []
    body(&map, &order)
    defaults.set(map, forKey: mapKey)
    defaults.set(order, forKey: mapOrderKey)
  }
}
