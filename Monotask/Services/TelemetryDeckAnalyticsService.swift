import Foundation
import CryptoKit
import TelemetryDeck

/// Sends events to TelemetryDeck. The stable per-install UUID is SHA-256 hashed before
/// being passed to the SDK so TelemetryDeck never receives the raw identifier.
final class TelemetryDeckAnalyticsService: AnalyticsService, @unchecked Sendable {
  private static let installIdKey = "monotask.installId"

  init(appID: String) {
    let config = TelemetryDeck.Config(appID: appID)
    config.defaultUser = hashedInstallId()
    TelemetryDeck.initialize(config: config)
  }

  func record(_ event: String, parameters: [String: String] = [:]) {
    TelemetryDeck.signal(event, parameters: parameters)
  }

  // MARK: - Private

  private func hashedInstallId() -> String {
    let raw = installId()
    let digest = SHA256.hash(data: Data(raw.utf8))
    return digest.map { String(format: "%02x", $0) }.joined()
  }

  private func installId() -> String {
    if let existing = UserDefaults.standard.string(forKey: Self.installIdKey) {
      return existing
    }
    let new = UUID().uuidString
    UserDefaults.standard.set(new, forKey: Self.installIdKey)
    return new
  }
}
