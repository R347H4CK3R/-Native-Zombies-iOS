import XCTest
@testable import NativeZombies

final class InputMergeTests: XCTestCase {
    func testButtonsMergeWithoutDroppingEitherSource() {
        var touch = InputState(); touch.fire = true
        var controller = InputState(); controller.jump = true
        let merged = InputState.merged(touch, controller)
        XCTAssertTrue(merged.fire)
        XCTAssertTrue(merged.jump)
    }

    func testStrongestMovementSourceWins() {
        var a = InputState(); a.movement = SIMD2<Float>(0.2, 0)
        var b = InputState(); b.movement = SIMD2<Float>(0, 0.8)
        XCTAssertEqual(InputState.merged(a, b).movement, b.movement)
    }
}
