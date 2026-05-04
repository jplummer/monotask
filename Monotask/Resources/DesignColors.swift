import SwiftUI
import UIKit

/// Named asset-catalog colors with RGB fallbacks so the UI stays usable if `Assets.xcassets` is missing from the bundle.
enum DesignColors {
  static var postItPaper: Color {
    adaptiveNamedColor(
      "PostItPaper",
      light: (1.0, 0.94, 0.82),
      dark: (0.36, 0.32, 0.28)
    )
  }

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
