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
    private let loadout = WeaponLoadout(definitions: [StarterWeapons.rifle, StarterWeapons.pistol])
    private let combat = WeaponCombatSystem()
    private let hitscanWorld = ZombieHitscanWorld()
    private var previousFire = false
    private let economy = EconomyManager()
    private let hud = UILabel()
    private let crosshair = UILabel()

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
        hud.translatesAutoresizingMaskIntoConstraints=false
        hud.textColor = .white; hud.font = .monospacedDigitSystemFont(ofSize:16,weight:.semibold)
        hud.numberOfLines = 2; hud.isUserInteractionEnabled = false
        crosshair.translatesAutoresizingMaskIntoConstraints=false
        crosshair.text = "+"; crosshair.textColor = .white; crosshair.font = .systemFont(ofSize:28,weight:.medium); crosshair.isUserInteractionEnabled = false
        root.addSubview(hud); root.addSubview(crosshair)
        NSLayoutConstraint.activate([
            hud.leadingAnchor.constraint(equalTo:root.safeAreaLayoutGuide.leadingAnchor,constant:16),
            hud.topAnchor.constraint(equalTo:root.safeAreaLayoutGuide.topAnchor,constant:12),
            crosshair.centerXAnchor.constraint(equalTo:root.centerXAnchor),
            crosshair.centerYAnchor.constraint(equalTo:root.centerYAnchor)
        ])
        self.view = root
    }

    private func updateGame(deltaTime: Float) {
        let input = currentInputState()
        loadout.update(deltaTime: deltaTime)
        if input.reload { loadout.active.beginReload() }
        let shouldFire = loadout.active.definition.fireMode == .automatic ? input.fire : (input.fire && !previousFire)
        if shouldFire {
            hitscanWorld.zombies = zombies.zombies
            let aliveBefore=zombies.activeCount
            let hit = combat.fire(loadout.active, ads: input.ads,
                            origin: player.state.position + SIMD3<Float>(0, player.state.eyeHeight, 0),
                            direction: player.forward, world: hitscanWorld)
            if hit != nil { economy.award(hit!.zone == .head ? .headshot : .damage) }
            zombies.removeDead()
            if zombies.activeCount < aliveBefore { economy.award(.kill) }
        }
        previousFire = input.fire
        player.update(input: input, deltaTime: deltaTime)
        renderer?.cameraPosition = player.state.position + SIMD3<Float>(0, player.state.eyeHeight, 0)
        renderer?.cameraYaw = player.state.yaw
        renderer?.cameraPitch = player.state.pitch
        let damage = zombies.update(deltaTime: deltaTime, target: player.state.position)
        playerHealth = max(0, playerHealth - damage)
        if rounds.round == 0 { rounds.startNext() }
        rounds.update(deltaTime: deltaTime, activeZombies: zombies.activeCount) { [weak self] in
            guard let self else { return }
            let n = Float(self.rounds.spawned)
            self.zombies.spawn(ZombieCatalog.walker, at: SIMD3<Float>((n.truncatingRemainder(dividingBy: 3)-1)*4, 0, -10-n))
        }
        zombies.removeDead()
        renderer?.zombiePositions = zombies.zombies.filter { $0.isAlive }.map { $0.position }
        let w=loadout.active
        hud.text="HP \(Int(playerHealth))   PTS \(economy.points)   ROUND \(rounds.round)\n\(w.definition.displayName)   \(w.state.magazine)/\(w.state.reserve)   Z \(zombies.activeCount)"
    }

    func currentInputState() -> InputState {
        let touch = InputState.merged(touchInput.consumeFrameState(), actionState)
        return InputState.merged(touch, controllerInput.state)
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .landscape }
    override var prefersHomeIndicatorAutoHidden: Bool { true }
}
