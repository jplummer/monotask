import Foundation

struct RandomPickResult: Equatable, Sendable {
  let task: ReminderTask?
  /// True when the caller asked to exclude an id and that removed every candidate (pool size 1); caller should show the gentle nudge UI.
  let onlyOneInPool: Bool
}

protocol RandomSelectionPolicy: Sendable {
  func pick(from pool: [ReminderTask], excluding excludedId: String?) -> RandomPickResult
}

/// Uniform random choice over the pool, excluding a given id when possible.
struct UniformRandomTopLevelPolicy: RandomSelectionPolicy {
  /// Unit interval [0, 1); inject for deterministic tests.
  var nextRandomUnit: @Sendable () -> Double

  init(nextRandomUnit: @escaping @Sendable () -> Double = { Double.random(in: 0..<1) }) {
    self.nextRandomUnit = nextRandomUnit
  }

  func pick(from pool: [ReminderTask], excluding excludedId: String?) -> RandomPickResult {
    guard !pool.isEmpty else {
      return RandomPickResult(task: nil, onlyOneInPool: false)
    }
    let filtered: [ReminderTask]
    if let excludedId {
      filtered = pool.filter { $0.id != excludedId }
    } else {
      filtered = pool
    }
    if filtered.isEmpty {
      let idx = randomIndex(count: pool.count)
      return RandomPickResult(task: pool[idx], onlyOneInPool: true)
    }
    let idx = randomIndex(count: filtered.count)
    return RandomPickResult(task: filtered[idx], onlyOneInPool: false)
  }

  private func randomIndex(count: Int) -> Int {
    guard count > 0 else { return 0 }
    let r = nextRandomUnit()
    let scaled = r * Double(count)
    let i = Int(floor(scaled))
    return min(max(0, i), count - 1)
  }
}
