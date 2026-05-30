import XCTest

@MainActor
final class ScreenshotTests: XCTestCase {
  var app: XCUIApplication!

  override func setUp() {
    super.setUp()
    continueAfterFailure = false
    app = XCUIApplication()
    setupSnapshot(app)
  }

  func testLightScreenshots() throws {
    app.launchArguments = ["--screenshots"]
    app.launch()
    try captureScreenshots(prefix: "Light")
  }

  func testDarkScreenshots() throws {
    app.launchArguments = ["--screenshots", "--dark-mode"]
    app.launch()
    try captureScreenshots(prefix: "Dark")
  }

  private func captureScreenshots(prefix: String) throws {
    let trashButton = app.buttons["Trash"]
    XCTAssertTrue(trashButton.waitForExistence(timeout: 5))
    snapshot("\(prefix)-01-TaskFocus")

    trashButton.tap()
    Thread.sleep(forTimeInterval: 1.0)
    snapshot("\(prefix)-02-UndoToast")

    app.navigationBars.buttons.firstMatch.tap()
    XCTAssertTrue(app.staticTexts["Weekend Projects"].waitForExistence(timeout: 3))
    snapshot("\(prefix)-03-ListPicker")

    app.tap()
  }
}
