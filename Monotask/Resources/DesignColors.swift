import SwiftUI
import UIKit

/// Named asset-catalog colors with RGB fallbacks so the UI stays usable if `Assets.xcassets` is missing from the bundle.
enum DesignColors {

  static var gradientTop: Color {
    adaptiveNamedColor(
      "GradientTop",
      light: (0.98, 0.78, 0.92),
      dark: (0.12, 0.08, 0.42)
    )
  }

  static var gradientBottom: Color {
    adaptiveNamedColor(
      "GradientBottom",
      light: (0.99, 0.88, 0.82),
      dark: (0.08, 0.22, 0.28)
    )
  }

  // MARK: - Post-it palette

  /// Classic post-it pastels. Index wraps with modulo — callers never need to bounds-check.
  static func postItColor(at index: Int) -> Color {
    let palette: [(light: (Double, Double, Double), dark: (Double, Double, Double))] = [
      (light: (1.00, 0.94, 0.82), dark: (0.36, 0.32, 0.28)), // warm cream
      (light: (1.00, 0.84, 0.88), dark: (0.40, 0.24, 0.30)), // soft pink
      (light: (0.82, 0.90, 1.00), dark: (0.20, 0.28, 0.42)), // pale blue
      (light: (0.84, 0.95, 0.86), dark: (0.22, 0.36, 0.28)), // pale mint
      (light: (1.00, 0.84, 0.72), dark: (0.42, 0.28, 0.20)), // soft peach
      (light: (0.90, 0.84, 1.00), dark: (0.28, 0.24, 0.42)), // soft lavender
    ]
    let entry = palette[index % palette.count]
    return Color(UIColor { trait in
      let c = trait.userInterfaceStyle == .dark ? entry.dark : entry.light
      return UIColor(red: c.0, green: c.1, blue: c.2, alpha: 1)
    })
  }

  static let postItColorCount = 6

  // MARK: - Private

  private static func adaptiveNamedColor(
    _ name: String,
    light: (Double, Double, Double),
    dark: (Double, Double, Double)
  ) -> Color {
    Color(
      UIColor { trait in
        if let catalog = UIColor(named: name, in: .main, compatibleWith: trait) {
          return catalog
        }
        let rgb = trait.userInterfaceStyle == .dark ? dark : light
        return UIColor(red: rgb.0, green: rgb.1, blue: rgb.2, alpha: 1)
      }
    )
  }
}
