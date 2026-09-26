import Foundation
import simd

struct PlayerTuning {
    var walkSpeed: Float = 4.6
    var sprintSpeed: Float = 7.2
    var crouchSpeed: Float = 2.5
    var jumpSpeed: Float = 5.2
    var gravity: Float = 16.0
    var lookSensitivity: Float = 0.0022
    var standingHeight: Float = 1.72
    var crouchingHeight: Float = 1.05
}

struct PlayerState {
    var position = SIMD3<Float>(0, 0, 0)
    var velocity = SIMD3<Float>(0, 0, 0)
    var yaw: Float = 0
    var pitch: Float = 0
    var grounded = true
    var crouched = false
    var eyeHeight: Float = 1.72
}

final class PlayerController {
    private(set) var state = PlayerState()
    var tuning = PlayerTuning()

    func reset(position: SIMD3<Float> = .zero) {
        state = PlayerState(position: position, eyeHeight: tuning.standingHeight)
    }

    func update(input: InputState, deltaTime rawDeltaTime: Float) {
        let dt = min(max(rawDeltaTime, 0), 1.0 / 15.0)

        state.yaw -= input.look.x * tuning.lookSensitivity
        state.pitch -= input.look.y * tuning.lookSensitivity
        state.pitch = min(max(state.pitch, -1.5533), 1.5533)

        state.crouched = input.crouch
        state.eyeHeight = state.crouched ? tuning.crouchingHeight : tuning.standingHeight

        let forward = SIMD3<Float>(-sin(state.yaw), 0, -cos(state.yaw))
        let right = SIMD3<Float>(cos(state.yaw), 0, -sin(state.yaw))
        var wish = right * input.movement.x + forward * input.movement.y
        let magnitude = simd_length(wish)
        if magnitude > 1 { wish /= magnitude }

        let speed: Float
        if state.crouched {
            speed = tuning.crouchSpeed
        } else if input.sprint && input.movement.y > 0.1 {
            speed = tuning.sprintSpeed
        } else {
            speed = tuning.walkSpeed
        }

        state.velocity.x = wish.x * speed
        state.velocity.z = wish.z * speed

        if input.jump && state.grounded && !state.crouched {
            state.velocity.y = tuning.jumpSpeed
            state.grounded = false
        }

        if !state.grounded {
            state.velocity.y -= tuning.gravity * dt
        }

        state.position += state.velocity * dt

        // Temporary ground plane. Step 12 replaces this with map collision queries.
        if state.position.y <= 0 {
            state.position.y = 0
            state.velocity.y = 0
            state.grounded = true
        }
    }

    var forward: SIMD3<Float> {
        let cp = cos(state.pitch)
        return simd_normalize(SIMD3<Float>(
            -sin(state.yaw) * cp,
            sin(state.pitch),
            -cos(state.yaw) * cp
        ))
    }
}
