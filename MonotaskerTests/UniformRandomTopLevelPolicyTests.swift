import XCTest
@testable import Monotasker

final class UniformRandomTopLevelPolicyTests: XCTestCase {
  func testPickExcludingUsesFilteredPool() {
    var rng = 0.0
    let policy = UniformRandomTopLevelPolicy {
      defer { rng += 0.5 }
      return min(rng, 0.99)
    }
    let a = ReminderTask(id: "a", title: "A")
    let b = ReminderTask(id: "b", title: "B")
    let c = ReminderTask(id: "c", title: "C")
    let pool = [a, b, c]
    let result = policy.pick(from: pool, excluding: "a")
    XCTAssertFalse(result.onlyOneInPool)
    XCTAssertNotEqual(result.task?.id, "a")
    XCTAssertTrue(["b", "c"].contains(result.task?.id ?? ""))
  }

  func testPickExcludingWhenOnlyOneFallsBackAndFlags() {
    let policy = UniformRandomTopLevelPolicy { 0.0 }
    let a = ReminderTask(id: "a", title: "A")
    let pool = [a]
    let result = policy.pick(from: pool, excluding: "a")
    XCTAssertTrue(result.onlyOneInPool)
    XCTAssertEqual(result.task?.id, "a")
  }

  func testPickWithoutExcludingUsesFullPool() {
    let policy = UniformRandomTopLevelPolicy { 0.0 }
    let a = ReminderTask(id: "a", title: "A")
    let b = ReminderTask(id: "b", title: "B")
    let pool = [a, b]
    let result = policy.pick(from: pool, excluding: nil)
    XCTAssertFalse(result.onlyOneInPool)
    XCTAssertEqual(result.task?.id, "a")
  }
}
