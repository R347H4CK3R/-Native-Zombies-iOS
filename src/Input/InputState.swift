import Foundation
import simd

struct InputState {
    var movement = SIMD2<Float>.zero
    var look = SIMD2<Float>.zero
    var fire = false
    var ads = false
    var reload = false
    var jump = false
    var crouch = false
    var sprint = false
    var melee = false
    var interact = false
}
