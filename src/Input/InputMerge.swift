import simd

extension InputState {
    static func merged(_ a: InputState, _ b: InputState) -> InputState {
        var r = InputState()
        r.movement = simd_length_squared(b.movement) > simd_length_squared(a.movement) ? b.movement : a.movement
        r.look = a.look + b.look
        r.fire = a.fire || b.fire; r.ads = a.ads || b.ads
        r.reload = a.reload || b.reload; r.jump = a.jump || b.jump
        r.crouch = a.crouch || b.crouch; r.sprint = a.sprint || b.sprint
        r.melee = a.melee || b.melee; r.interact = a.interact || b.interact
        return r
    }
}
