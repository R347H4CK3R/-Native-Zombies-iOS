import UIKit
import simd

final class TouchInputView: UIView {
    private(set) var state = InputState()
    var lookSensitivity: Float = 1.0
    private var moveTouch: UITouch?
    private var lookTouch: UITouch?
    private var moveOrigin = CGPoint.zero
    private var lookLast = CGPoint.zero

    override init(frame: CGRect) {
        super.init(frame: frame)
        isMultipleTouchEnabled = true
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let p = touch.location(in: self)
            if p.x < bounds.midX, moveTouch == nil {
                moveTouch = touch; moveOrigin = p
            } else if lookTouch == nil {
                lookTouch = touch; lookLast = p
            }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let p = touch.location(in: self)
            if touch === moveTouch {
                let dx = Float(p.x - moveOrigin.x) / 70
                let dy = Float(moveOrigin.y - p.y) / 70
                var v = SIMD2<Float>(dx, dy)
                let length = simd_length(v)
                if length > 1 { v /= length }
                state.movement = v
                state.sprint = v.y > 0.92
            } else if touch === lookTouch {
                state.look = SIMD2<Float>(Float(p.x - lookLast.x), Float(p.y - lookLast.y)) * lookSensitivity
                lookLast = p
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) { end(touches) }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) { end(touches) }

    private func end(_ touches: Set<UITouch>) {
        for touch in touches {
            if touch === moveTouch { moveTouch = nil; state.movement = .zero; state.sprint = false }
            if touch === lookTouch { lookTouch = nil; state.look = .zero }
        }
    }

    func consumeFrameState() -> InputState {
        let output = state
        state.look = .zero
        return output
    }
}
