import XCTest
@testable import Monotask

final class SelectionStoreTests: XCTestCase {
  func testRoundTrip() {
    let suite = "test.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defaults.removePersistentDomain(forName: suite)
    let store = SelectionStore(defaults: defaults)
    XCTAssertNil(store.selectedListIdentifier)
    XCTAssertNil(store.selectedReminderIdentifier)
    store.selectedListIdentifier = "list-1"
    store.selectedReminderIdentifier = "rem-1"
    XCTAssertEqual(store.selectedListIdentifier, "list-1")
    XCTAssertEqual(store.selectedReminderIdentifier, "rem-1")
    store.clearReminderSelection()
    XCTAssertNil(store.selectedReminderIdentifier)
    XCTAssertEqual(store.selectedListIdentifier, "list-1")
    store.clearAll()
    XCTAssertNil(store.selectedListIdentifier)
  }
}
