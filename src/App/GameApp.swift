import UIKit
import MetalKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = GameViewController()
        window.makeKeyAndVisible()
        self.window = window
        return true
    }
}

final class GameViewController: UIViewController {
    private var renderer: GameRenderer?
    private let controllerInput = ControllerInputManager()
    private let touchInput = TouchInputView()
    private let actionOverlay = TouchActionOverlay()
    private var actionState = InputState()
    private let player = PlayerController()
    private let zombies = ZombieManager(navigation: CachedZombieNavigation())
    private let rounds = RoundManager()
    private var playerHealth: Float = 100

    override func loadView() {
        guard let device = MTLCreateSystemDefaultDevice() else { fatalError("Metal is required") }
        let root = UIView()
        let metal = MTKView(frame: .zero, device: device)
        metal.preferredFramesPerSecond = 60
        metal.colorPixelFormat = .bgra8Unorm
        metal.depthStencilPixelFormat = .depth32Float
        renderer = GameRenderer(view: metal)
        renderer?.frameHandler = { [weak self] dt in self?.updateGame(deltaTime: dt) }
        metal.delegate = renderer

        for v in [metal, touchInput, actionOverlay] {
            v.translatesAutoresizingMaskIntoConstraints = false
            root.addSubview(v)
            NSLayoutConstraint.activate([v.leadingAnchor.constraint(equalTo: root.leadingAnchor), v.trailingAnchor.constraint(equalTo: root.trailingAnchor), v.topAnchor.constraint(equalTo: root.topAnchor), v.bottomAnchor.constraint(equalTo: root.bottomAnchor)])
        }
        actionOverlay.onStateChanged = { [weak self] in self?.actionState = $0 }
        self.view = root
    }

    private func updateGame(deltaTime: Float) {
        let input = currentInputState()
        player.update(input: input, deltaTime: deltaTime)
        let damage = zombies.update(deltaTime: deltaTime, target: player.state.position)
        playerHealth = max(0, playerHealth - damage)
        if rounds.round == 0 { rounds.startNext() }
        rounds.update(deltaTime: deltaTime, activeZombies: zombies.activeCount) { [weak self] in
            guard let self else { return }
            let n = Float(self.rounds.spawned)
            self.zombies.spawn(ZombieCatalog.walker, at: SIMD3<Float>((n.truncatingRemainder(dividingBy: 3)-1)*4, 0, -10-n))
        }
        zombies.removeDead()
    }

    func currentInputState() -> InputState {
        let touch = InputState.merged(touchInput.consumeFrameState(), actionState)
        return InputState.merged(touch, controllerInput.state)
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .landscape }
    override var prefersHomeIndicatorAutoHidden: Bool { true }
}
