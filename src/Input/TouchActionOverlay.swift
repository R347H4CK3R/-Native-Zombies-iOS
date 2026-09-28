import UIKit

final class TouchActionOverlay: UIView {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        for subview in subviews where !subview.isHidden && subview.alpha > 0.01 && subview.isUserInteractionEnabled {
            let p = subview.convert(point, from: self)
            if subview.point(inside: p, with: event) { return true }
        }
        return false
    }
    var onStateChanged: ((InputState) -> Void)?
    private var state = InputState()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = true
        add("FIRE", action: #selector(fireDown), x: 0.88, y: 0.62)
        add("ADS", action: #selector(adsDown), x: 0.76, y: 0.48)
        add("JUMP", action: #selector(jumpDown), x: 0.88, y: 0.32)
        add("RLD", action: #selector(reloadDown), x: 0.75, y: 0.72)
        add("USE", action: #selector(interactDown), x: 0.62, y: 0.64)
        add("C", action: #selector(crouchDown), x: 0.64, y: 0.82)
        add("MELEE", action: #selector(meleeDown), x: 0.76, y: 0.30)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        let positions:[String:CGPoint] = ["FIRE":[0.88,0.62],"ADS":[0.76,0.48],"JUMP":[0.88,0.32],"RLD":[0.75,0.72],"USE":[0.62,0.64],"C":[0.64,0.82],"MELEE":[0.76,0.30]]
        for case let b as UIButton in subviews {
            guard let key=b.accessibilityIdentifier, let p=positions[key] else { continue }
            b.center=CGPoint(x:bounds.width*p.x,y:bounds.height*p.y)
        }
    }

    private func add(_ title: String, action: Selector, x: CGFloat, y: CGFloat) {
        let b = UIButton(type: .system)
        b.setTitle(title, for: .normal)
        b.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        b.layer.cornerRadius = 24
        b.addTarget(self, action: action, for: .touchDown)
        b.accessibilityIdentifier = title
        b.addTarget(self, action: #selector(buttonReleased(_:)), for: [.touchUpInside,.touchUpOutside,.touchCancel])
        addSubview(b)
        b.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            b.widthAnchor.constraint(equalToConstant: 64), b.heightAnchor.constraint(equalToConstant: 48)
        ])
    }

    @objc private func fireDown(){ state.fire=true; emit() }
    @objc private func adsDown(){ state.ads=true; emit() }
    @objc private func jumpDown(){ state.jump=true; emit() }
    @objc private func reloadDown(){ state.reload=true; emit() }
    @objc private func interactDown(){ state.interact=true; emit() }
    @objc private func crouchDown(){ state.crouch.toggle(); emit() }
    @objc private func meleeDown(){ state.melee=true; emit() }
    @objc private func buttonReleased(_ sender:UIButton){
        switch sender.accessibilityIdentifier {
        case "FIRE": state.fire=false
        case "ADS": state.ads=false
        case "JUMP": state.jump=false
        case "RLD": state.reload=false
        case "USE": state.interact=false
        case "MELEE": state.melee=false
        default: break
        }
        emit()
    }
    private func emit(){ onStateChanged?(state) }
}
