import AppKit
import XCTest
@testable import Canvas

final class MenuBarOwnershipTests: XCTestCase {
    func testTheCanvasInFrontOwnsTheMenuBarOnlyWithTheSettingOnAndSunlightOn() async {
        await MainActor.run {
            XCTAssertEqual(MenuBarOwnership.wanted(active: true, setupShown: false, owns: true, sunlightOn: true), .regular)
            XCTAssertEqual(MenuBarOwnership.wanted(active: true, setupShown: false, owns: false, sunlightOn: true), .accessory)
            XCTAssertEqual(MenuBarOwnership.wanted(active: true, setupShown: false, owns: true, sunlightOn: false), .accessory)
        }
    }

    /// In a window (another app in front), Sunlight stays out of the Dock and ⌘Tab as before.
    func testAnotherAppInFrontLeavesSunlightAnAccessory() async {
        await MainActor.run {
            XCTAssertEqual(MenuBarOwnership.wanted(active: false, setupShown: false, owns: true, sunlightOn: true), .accessory)
        }
    }

    /// Setup keeps its Dock icon whatever the canvas wants.
    func testSetupUpIsRegularEitherWay() async {
        await MainActor.run {
            for active in [true, false] {
                XCTAssertEqual(MenuBarOwnership.wanted(active: active, setupShown: true, owns: false, sunlightOn: false), .regular)
            }
        }
    }
}
