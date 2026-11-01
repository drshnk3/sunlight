import XCTest
@testable import Canvas

/// Entering a window: where it sits on screen at 1:1 and the camera that puts it there; and a
/// window's native place for any camera, the one answer the seam, kept windows and siblings share.
final class HandoffTests: XCTestCase {
    /// A 2000×1200 display with a 38 pt menu bar, view coordinates.
    private let visible = CGRect(x: 0, y: 38, width: 2000, height: 1162)
    private let scale: CGFloat = 2
    private let window = CGRect(x: 3000, y: 2000, width: 800, height: 600)

    private func plan(_ placement: Handoff.Placement, rect: CGRect? = nil, camera: Camera = Camera(origin: CGPoint(x: 2500, y: 1500), zoom: 0.5),
                      tiledArea: CGRect? = nil) -> Handoff.Plan {
        Handoff.plan(placement, rect: rect ?? window, camera: camera, visible: visible, scale: scale, tiledArea: tiledArea)
    }

    // MARK: Where the window goes

    func testCentredPutsTheWindowInTheMiddleOfTheVisibleArea() {
        let p = plan(.centered)
        XCTAssertEqual(p.origin, CGPoint(x: 600, y: 319))
        XCTAssertNil(p.inPlace)
        XCTAssertFalse(p.clicked)
    }

    func testAWindowBiggerThanTheScreenStartsAtTheTopLeft() {
        let p = plan(.centered, rect: CGRect(x: 0, y: 0, width: 2400, height: 1400))
        XCTAssertEqual(p.origin, CGPoint(x: 0, y: 38))
    }

    func testInPlaceKeepsTheTitleBarWhereItIsAndThePointUnderThePointer() {
        // At zoom 0.5 from (2500, 1500) the window's top-left is on screen at (250, 250).
        let point = CGPoint(x: 300, y: 400)   // on the proxy, 50 screen points in from its left edge
        let p = plan(.inPlace(around: point))
        // Grown to 1:1, the point's world x (3100) stays under the pointer: origin.x = 300 − 100.
        XCTAssertEqual(p.origin, CGPoint(x: 200, y: 250))
        XCTAssertNotNil(p.inPlace)
        XCTAssertFalse(p.clicked)
    }

    func testACentringClickGoesToTheMiddleAndStillFliesAsAClick() {
        let p = plan(.clickedCentred)
        XCTAssertEqual(p.origin, plan(.centered).origin)
        XCTAssertEqual(p.camera, plan(.centered).camera)
        XCTAssertNil(p.inPlace)
        XCTAssertTrue(p.clicked)
        // A screen-sized window comes whole onto the screen, top-left under the menu bar.
        let big = plan(.clickedCentred, rect: CGRect(x: 0, y: 0, width: 2000, height: 1162))
        XCTAssertEqual(big.origin, CGPoint(x: 0, y: 38))
    }

    func testAClickKeepsTheClickedSpotUnderThePointer() {
        let p = plan(.clicked(at: CGPoint(x: 1000, y: 400), offset: CGPoint(x: 100, y: 50)))
        XCTAssertEqual(p.origin, CGPoint(x: 900, y: 350))
        XCTAssertTrue(p.clicked)
        XCTAssertNotNil(p.inPlace)
    }

    // MARK: A click lands wholly on screen

    /// Clicked near its right side, its picture on the left of the screen: grown around the spot, the
    /// window would start 400 points off the left edge. It slides right to the edge, and the camera goes
    /// over to it, so the window keeps its place on the canvas.
    func testAClickNearTheFarSideKeepsTheLeftEdgeOnScreen() {
        let p = plan(.clicked(at: CGPoint(x: 300, y: 400), offset: CGPoint(x: 700, y: 50)))
        XCTAssertEqual(p.origin, CGPoint(x: 0, y: 350))
        XCTAssertEqual(p.inPlace, p.camera, "the camera moves, not the window")
        XCTAssertEqual(p.camera.toScreen(window.origin), p.origin)
    }

    func testAClickNearTheNearSideKeepsTheRightEdgeOnScreen() {
        let p = plan(.clicked(at: CGPoint(x: 1900, y: 400), offset: CGPoint(x: 100, y: 50)))
        XCTAssertEqual(p.origin.x + window.width, visible.maxX)
        XCTAssertEqual(p.origin, CGPoint(x: 1200, y: 350))
    }

    func testAClickLowDownKeepsTheBottomOnScreen() {
        let p = plan(.clicked(at: CGPoint(x: 1000, y: 1150), offset: CGPoint(x: 100, y: 50)))
        XCTAssertEqual(p.origin, CGPoint(x: 900, y: visible.maxY - window.height))
    }

    func testAClickedWindowWiderThanTheScreenStartsAtItsLeft() {
        let wide = CGRect(x: 3000, y: 2000, width: 2400, height: 600)
        let p = plan(.clicked(at: CGPoint(x: 1500, y: 400), offset: CGPoint(x: 2000, y: 50)), rect: wide)
        XCTAssertEqual(p.origin.x, visible.minX)
    }

    func testAClickedWindowTallerThanTheScreenStartsUnderTheMenuBar() {
        let tall = CGRect(x: 3000, y: 2000, width: 800, height: 1400)
        let p = plan(.clicked(at: CGPoint(x: 1000, y: 600), offset: CGPoint(x: 100, y: 900)), rect: tall)
        XCTAssertEqual(p.origin.y, visible.minY)
    }

    func testFittingMovesNothingAlreadyOnScreen() {
        let o = CGPoint(x: 100, y: 200)
        XCTAssertEqual(Handoff.fittedOrigin(o, size: CGSize(width: 800, height: 600), in: visible), o)
    }

    func testATiledWindowLinesUpWithItsArea() {
        // Tiled to the right half of an area that starts at (2800, 1900): the window's offset in it is (200, 100).
        let p = plan(.centered, tiledArea: CGRect(x: 2800, y: 1900, width: 1600, height: 1100))
        XCTAssertEqual(p.origin, CGPoint(x: 200, y: 138))
        XCTAssertNotNil(p.inPlace, "a tiled window keeps its place in its area")
    }

    // MARK: The camera

    func testTheCameraShowsTheWindowAtItsOrigin() {
        for placement: Handoff.Placement in [.centered, .inPlace(around: CGPoint(x: 300, y: 400)), .clicked(at: CGPoint(x: 1000, y: 700), offset: CGPoint(x: 100, y: 50))] {
            let p = plan(placement)
            XCTAssertEqual(p.camera.zoom, 1)
            let shown = p.camera.toScreen(window.origin)
            XCTAssertEqual(shown.x, p.origin.x, accuracy: 1e-9)
            XCTAssertEqual(shown.y, p.origin.y, accuracy: 1e-9)
        }
    }

    func testTheOriginIsOnThePixelGrid() {
        let p = plan(.inPlace(around: CGPoint(x: 300.3, y: 400.7)), camera: Camera(origin: CGPoint(x: 2500.37, y: 1500.11), zoom: 0.5))
        XCTAssertEqual((p.origin.x * scale).rounded(), p.origin.x * scale)
        XCTAssertEqual((p.origin.y * scale).rounded(), p.origin.y * scale)
    }

    func testNoWindowGoesAboveTheMenuBar() {
        // Pinched in with its top on screen 40 points above the screen's top: above the menu bar.
        let p = plan(.inPlace(around: CGPoint(x: 300, y: 10)), camera: Camera(origin: CGPoint(x: 2500, y: 2080), zoom: 0.5))
        XCTAssertEqual(p.origin.y, 38)
        // In place, the camera it would have ended at, before the menu bar had its say.
        XCTAssertEqual(p.inPlace?.toScreen(window.origin).y, -40)
        XCTAssertEqual(p.camera.toScreen(window.origin).y, 38)
    }

    /// Clicked near the top, the window is fitted under the menu bar before the in-place camera is worked
    /// out: the camera goes down to it, and the window keeps its place on the canvas.
    func testAClickNearTheTopLandsUnderTheMenuBarWithoutMovingTheWindow() {
        let p = plan(.clicked(at: CGPoint(x: 1000, y: 10), offset: CGPoint(x: 100, y: 50)))
        XCTAssertEqual(p.origin.y, 38)
        XCTAssertEqual(p.inPlace, p.camera)
    }

    // MARK: A window's native place

    func testTheNativePlaceIsTheCanvasPlaceThroughTheCameraToThePixel() {
        let camera = Camera(origin: CGPoint(x: 2500.3, y: 1500), zoom: 1)
        let origin = Handoff.nativeOrigin(of: CGPoint(x: 3000, y: 2000), at: camera, scale: 2, top: 38)
        XCTAssertEqual(origin, CGPoint(x: 499.5, y: 500))
    }

    func testTheNativePlaceStaysBelowTheMenuBar() {
        let camera = Camera(origin: CGPoint(x: 0, y: 2000), zoom: 1)
        XCTAssertEqual(Handoff.nativeOrigin(of: CGPoint(x: 100, y: 1990), at: camera, scale: 2, top: 38), CGPoint(x: 100, y: 38))
    }

    func testTheSeamAndTheNativePlaceAgree() {
        // What the seam commits (`plan.origin`) is where `nativeOrigin` says the window sits at the plan's camera.
        for placement: Handoff.Placement in [.centered, .inPlace(around: CGPoint(x: 300, y: 400)), .clicked(at: CGPoint(x: 1000, y: 10), offset: CGPoint(x: 100, y: 50))] {
            let p = plan(placement)
            XCTAssertEqual(Handoff.nativeOrigin(of: window.origin, at: p.camera, scale: scale, top: visible.minY), p.origin)
        }
    }

    func testTheAligningCameraPutsTheProxyOverTheRealWindow() {
        let camera = Handoff.cameraAligning(window, with: CGRect(x: 600, y: 319, width: 800, height: 600))
        XCTAssertEqual(camera.toScreen(window.origin), CGPoint(x: 600, y: 319))
        XCTAssertEqual(camera.zoom, 1)
    }

    func testACameraSeenFromGlobalAndBack() {
        let view = Camera(origin: CGPoint(x: 100, y: 200), zoom: 0.5)
        let display = CGPoint(x: -2000, y: 300)
        let global = view.global(viewOrigin: display)
        XCTAssertEqual(global.inView(viewOrigin: display), view)
        XCTAssertEqual(global.toScreen(CGPoint(x: 100, y: 200)), display, "the view's top-left is the display's origin")
    }
}
