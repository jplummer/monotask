import Foundation

final class MockAnalyticsService: AnalyticsService, @unchecked Sendable {
  private(set) var recorded: [(event: String, parameters: [String: String])] = []

  func record(_ event: String, parameters: [String: String] = [:]) {
    recorded.append((event, parameters))
  }

  func events(named name: String) -> [[String: String]] {
    recorded.filter { $0.event == name }.map(\.parameters)
  }

  func eventCount(named name: String) -> Int {
    recorded.filter { $0.event == name }.count
  }
}
