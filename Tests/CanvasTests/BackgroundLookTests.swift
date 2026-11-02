import XCTest
@testable import Canvas

/// With an app in front, the canvas background is the desktop behind it and the see-through menu bar:
/// it looks as at 1:1 whatever zoom the canvas was left at.
final class BackgroundLookTests: XCTestCase {
    @MainActor func testZoomedOutOnTheCanvasTheBackgroundBlurs() {
        let spec = BackgroundSpec()   // blur follows the zoom by default
        let zoom = BackgroundRenderer.lookZoom(camera: 0.15, appInFront: false)
        XCTAssertGreaterThan(spec.blurPosition(forZoom: zoom), 0)
    }

    @MainActor func testWithAnAppInFrontItIsSharpAndUndimmedAtAnyZoom() {
        let spec = BackgroundSpec()
        for camera: CGFloat in [0.05, 0.15, 0.5, 1, 2] {
            let zoom = BackgroundRenderer.lookZoom(camera: camera, appInFront: true)
            XCTAssertEqual(spec.blurPosition(forZoom: zoom), spec.blurPosition(forZoom: 1), "\(camera)")
            XCTAssertEqual(spec.dimAmount(forZoom: zoom), spec.dimAmount(forZoom: 1), "\(camera)")
        }
    }
}
