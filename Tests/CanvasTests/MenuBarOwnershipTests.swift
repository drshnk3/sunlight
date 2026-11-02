import AppKit
import XCTest
@testable import Canvas

final class MenuBarOwnershipTests: XCTestCase {
    /// Regular for as long as the setting and Sunlight are on: macOS gives an app the menu bar only as
    /// it activates, so Sunlight can't wait for the canvas to come forward to turn regular.
    func testSunlightIsRegularWhileTheSettingAndSunlightAreOn() async {
        await MainActor.run {
            XCTAssertEqual(MenuBarOwnership.wanted(setupShown: false, owns: true, sunlightOn: true), .regular)
            XCTAssertEqual(MenuBarOwnership.wanted(setupShown: false, owns: false, sunlightOn: true), .accessory)
            XCTAssertEqual(MenuBarOwnership.wanted(setupShown: false, owns: true, sunlightOn: false), .accessory)
        }
    }

    /// Setup keeps its Dock icon whatever the setting says.
    func testSetupUpIsRegularEitherWay() async {
        await MainActor.run {
            XCTAssertEqual(MenuBarOwnership.wanted(setupShown: true, owns: false, sunlightOn: false), .regular)
        }
    }
}
