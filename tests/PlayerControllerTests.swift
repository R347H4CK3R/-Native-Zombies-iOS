import XCTest
@testable import NativeZombies

final class PlayerControllerTests: XCTestCase {
    func testForwardMovementUsesWalkSpeed() {
        let player = PlayerController()
        var input = InputState()
        input.movement = SIMD2<Float>(0, 1)
        player.update(input: input, deltaTime: 1)
        XCTAssertLessThan(player.state.position.z, 0)
        XCTAssertEqual(player.state.position.y, 0, accuracy: 0.001)
    }

    func testSprintIsFasterThanWalk() {
        let walk = PlayerController()
        let sprint = PlayerController()
        var input = InputState()
        input.movement = SIMD2<Float>(0, 1)
        walk.update(input: input, deltaTime: 1.0 / 60.0)
        input.sprint = true
        sprint.update(input: input, deltaTime: 1.0 / 60.0)
        XCTAssertGreaterThan(abs(sprint.state.position.z), abs(walk.state.position.z))
    }

    func testJumpReturnsToGround() {
        let player = PlayerController()
        var input = InputState()
        input.jump = true
        player.update(input: input, deltaTime: 1.0 / 60.0)
        XCTAssertFalse(player.state.grounded)
        input.jump = false
        for _ in 0..<180 {
            player.update(input: input, deltaTime: 1.0 / 60.0)
        }
        XCTAssertTrue(player.state.grounded)
        XCTAssertEqual(player.state.position.y, 0, accuracy: 0.001)
    }

    func testPitchIsClamped() {
        let player = PlayerController()
        var input = InputState()
        input.look = SIMD2<Float>(0, -100000)
        player.update(input: input, deltaTime: 1.0 / 60.0)
        XCTAssertLessThanOrEqual(player.state.pitch, 1.5533)
    }
}
