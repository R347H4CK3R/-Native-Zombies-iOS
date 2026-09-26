import UIKit

final class TouchActionOverlay: UIView {
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

    private func add(_ title: String, action: Selector, x: CGFloat, y: CGFloat) {
        let b = UIButton(type: .system)
        b.setTitle(title, for: .normal)
        b.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        b.layer.cornerRadius = 24
        b.addTarget(self, action: action, for: .touchDown)
        b.addTarget(self, action: #selector(releaseMomentary), for: [.touchUpInside,.touchUpOutside,.touchCancel])
        addSubview(b)
        b.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            b.centerXAnchor.constraint(equalTo: leadingAnchor, constant: x * UIScreen.main.bounds.width),
            b.centerYAnchor.constraint(equalTo: topAnchor, constant: y * UIScreen.main.bounds.height),
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
    @objc private func releaseMomentary(){ state.fire=false; state.ads=false; state.jump=false; state.reload=false; state.interact=false; state.melee=false; emit() }
    private func emit(){ onStateChanged?(state) }
}
