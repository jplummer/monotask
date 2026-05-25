import XCTest

@MainActor
final class ScreenshotTests: XCTestCase {
  var app: XCUIApplication!

  override func setUp() {
    super.setUp()
    continueAfterFailure = false
    app = XCUIApplication()
    setupSnapshot(app)
    app.launchArguments = ["--screenshots"]
    app.launch()
  }

  func testScreenshots() throws {
    // Wait for bootstrap → focused (MockRemindersService resolves instantly)
    let taskCard = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Install'")).firstMatch
    XCTAssertTrue(taskCard.waitForExistence(timeout: 5))

    snapshot("01-TaskFocus")

    // Tap trash, wait for undo toast to appear, then let the slide animation finish
    app.buttons["Trash"].tap()
    let undoToast = app.buttons["Undo"]
    XCTAssertTrue(undoToast.waitForExistence(timeout: 3))
    Thread.sleep(forTimeInterval: 0.5)
    snapshot("02-UndoToast")

    // Open list picker
    app.navigationBars.buttons.firstMatch.tap()
    snapshot("03-ListPicker")

    // Dismiss picker
    app.tap()
  }
}
