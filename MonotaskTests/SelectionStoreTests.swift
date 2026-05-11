import XCTest
@testable import Monotask

final class SelectionStoreTests: XCTestCase {

  private func makeStore(suite: String? = nil) -> (SelectionStore, UserDefaults) {
    let name = suite ?? "test.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: name)!
    defaults.removePersistentDomain(forName: name)
    return (SelectionStore(defaults: defaults), defaults)
  }

  // MARK: - Initial state

  func testInitialStateIsNil() {
    let (store, _) = makeStore()
    XCTAssertNil(store.selectedListIdentifier)
    XCTAssertNil(store.reminderID(forList: "any-list"))
  }

  // MARK: - selectedListIdentifier

  func testOverwriteListIdPersists() {
    let (store, _) = makeStore()
    store.selectedListIdentifier = "list-1"
    store.selectedListIdentifier = "list-2"
    XCTAssertEqual(store.selectedListIdentifier, "list-2")
  }

  // MARK: - Per-list reminder map

  func testSetAndGetReminderIDRoundTrip() {
    let (store, _) = makeStore()
    store.setReminderID("rem-1", forList: "list-1")
    XCTAssertEqual(store.reminderID(forList: "list-1"), "rem-1")
  }

  func testSetReminderIDMultipleLists() {
    let (store, _) = makeStore()
    store.setReminderID("rem-a", forList: "list-1")
    store.setReminderID("rem-b", forList: "list-2")
    XCTAssertEqual(store.reminderID(forList: "list-1"), "rem-a")
    XCTAssertEqual(store.reminderID(forList: "list-2"), "rem-b")
  }

  func testSetReminderIDOverwritesPreviousEntry() {
    let (store, _) = makeStore()
    store.setReminderID("rem-1", forList: "list-1")
    store.setReminderID("rem-2", forList: "list-1")
    XCTAssertEqual(store.reminderID(forList: "list-1"), "rem-2")
  }

  func testUnknownListReturnsNil() {
    let (store, _) = makeStore()
    XCTAssertNil(store.reminderID(forList: "no-such-list"))
  }

  // MARK: - clearReminderID(forList:)

  func testClearReminderIDRemovesEntryForList() {
    let (store, _) = makeStore()
    store.setReminderID("rem-1", forList: "list-1")
    store.clearReminderID(forList: "list-1")
    XCTAssertNil(store.reminderID(forList: "list-1"))
  }

  func testClearReminderIDForOneListPreservesOthers() {
    let (store, _) = makeStore()
    store.setReminderID("rem-1", forList: "list-1")
    store.setReminderID("rem-2", forList: "list-2")
    store.clearReminderID(forList: "list-1")
    XCTAssertNil(store.reminderID(forList: "list-1"))
    XCTAssertEqual(store.reminderID(forList: "list-2"), "rem-2")
  }

  func testClearReminderIDPreservesListIdentifier() {
    let (store, _) = makeStore()
    store.selectedListIdentifier = "list-1"
    store.setReminderID("rem-1", forList: "list-1")
    store.clearReminderID(forList: "list-1")
    XCTAssertEqual(store.selectedListIdentifier, "list-1")
  }

  // MARK: - clearAll

  func testClearAllResetsEverything() {
    let (store, _) = makeStore()
    store.selectedListIdentifier = "list-1"
    store.setReminderID("rem-1", forList: "list-1")
    store.clearAll()
    XCTAssertNil(store.selectedListIdentifier)
    XCTAssertNil(store.reminderID(forList: "list-1"))
  }

  func testClearAllWhenAlreadyNilIsNoOp() {
    let (store, _) = makeStore()
    store.clearAll()
    XCTAssertNil(store.selectedListIdentifier)
    XCTAssertNil(store.reminderID(forList: "any"))
  }

  // MARK: - Shared UserDefaults suite

  func testTwoInstancesOnSameSuiteShareState() {
    let suiteName = "test.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defaults.removePersistentDomain(forName: suiteName)
    let store1 = SelectionStore(defaults: defaults)
    let store2 = SelectionStore(defaults: defaults)

    store1.selectedListIdentifier = "list-shared"
    store1.setReminderID("rem-shared", forList: "list-shared")

    XCTAssertEqual(store2.selectedListIdentifier, "list-shared")
    XCTAssertEqual(store2.reminderID(forList: "list-shared"), "rem-shared")
  }

  // MARK: - LRU pruning

  func testPruningAt50RemovesOldestEntry() {
    let (store, _) = makeStore()
    for i in 0..<50 {
      store.setReminderID("rem-\(i)", forList: "list-\(i)")
    }
    // At exactly 50 entries, list-0 is still present.
    XCTAssertEqual(store.reminderID(forList: "list-0"), "rem-0")
    // Adding entry 51 evicts list-0 (oldest).
    store.setReminderID("rem-50", forList: "list-50")
    XCTAssertNil(store.reminderID(forList: "list-0"))
    XCTAssertEqual(store.reminderID(forList: "list-50"), "rem-50")
  }

  func testLRUOrderUpdatedOnRewrite() {
    let (store, _) = makeStore()
    // Fill to 50 — list-0 is oldest.
    for i in 0..<50 {
      store.setReminderID("rem-\(i)", forList: "list-\(i)")
    }
    // Touch list-0 to make it most recently used.
    store.setReminderID("rem-0-updated", forList: "list-0")
    // Adding one more entry should evict list-1 (new oldest), not list-0.
    store.setReminderID("rem-50", forList: "list-50")
    XCTAssertEqual(store.reminderID(forList: "list-0"), "rem-0-updated")
    XCTAssertNil(store.reminderID(forList: "list-1"))
  }

  // MARK: - Migration from legacy fields

  func testMigrationSeedsMapFromLegacyFields() {
    let suiteName = "test.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defaults.removePersistentDomain(forName: suiteName)
    defaults.set("list-legacy", forKey: "monotask.selectedListIdentifier")
    defaults.set("rem-legacy", forKey: "monotask.selectedReminderIdentifier")
    let store = SelectionStore(defaults: defaults)
    XCTAssertEqual(store.reminderID(forList: "list-legacy"), "rem-legacy")
  }

  func testMigrationClearsLegacyReminderKey() {
    let suiteName = "test.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defaults.removePersistentDomain(forName: suiteName)
    defaults.set("list-legacy", forKey: "monotask.selectedListIdentifier")
    defaults.set("rem-legacy", forKey: "monotask.selectedReminderIdentifier")
    _ = SelectionStore(defaults: defaults)
    XCTAssertNil(defaults.string(forKey: "monotask.selectedReminderIdentifier"))
  }

  func testMigrationSkippedIfMapAlreadyHasData() {
    let suiteName = "test.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defaults.removePersistentDomain(forName: suiteName)
    // Pre-populate the map.
    let store1 = SelectionStore(defaults: defaults)
    store1.setReminderID("existing-rem", forList: "existing-list")
    // Set legacy fields after the map is seeded.
    defaults.set("list-legacy", forKey: "monotask.selectedListIdentifier")
    defaults.set("rem-legacy", forKey: "monotask.selectedReminderIdentifier")
    // A fresh store should skip migration because the map is non-empty.
    let store2 = SelectionStore(defaults: defaults)
    XCTAssertNil(store2.reminderID(forList: "list-legacy"))
    XCTAssertEqual(store2.reminderID(forList: "existing-list"), "existing-rem")
    // Legacy key should remain untouched since migration was skipped.
    XCTAssertNotNil(defaults.string(forKey: "monotask.selectedReminderIdentifier"))
  }
}
