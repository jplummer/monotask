import Foundation

protocol AnalyticsService: Sendable {
  func record(_ event: String, parameters: [String: String])
}

extension AnalyticsService {
  func record(_ event: String) {
    record(event, parameters: [:])
  }
}
