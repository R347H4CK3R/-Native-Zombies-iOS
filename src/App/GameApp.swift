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
    private let interactions = WorldInteractionManager()
    private var mapDefinition: MapDefinition?
    private var previousInteract = false
    private let session = GameSession()
    private let prompt = UILabel()
    private let gameOverLabel = UILabel()
    private let pauseButton = UIButton(type:.system)
    private let pausePanel = UIView()

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
        hud.translatesAutoresizingMaskIntoConstraints = false
        hud.textColor = .white; hud.font = .monospacedDigitSystemFont(ofSize:16,weight:.semibold)
        hud.numberOfLines = 2; hud.isUserInteractionEnabled = false
        crosshair.translatesAutoresizingMaskIntoConstraints = false
        crosshair.text = "+"; crosshair.textColor = .white; crosshair.font = .systemFont(ofSize:28,weight:.medium); crosshair.isUserInteractionEnabled = false
        prompt.translatesAutoresizingMaskIntoConstraints = false
        prompt.textColor = .white; prompt.font = .systemFont(ofSize:16,weight:.semibold); prompt.textAlignment = .center; prompt.isUserInteractionEnabled = false
        gameOverLabel.translatesAutoresizingMaskIntoConstraints = false
        gameOverLabel.textColor = .white; gameOverLabel.font = .systemFont(ofSize:32,weight:.bold); gameOverLabel.textAlignment = .center; gameOverLabel.numberOfLines = 0; gameOverLabel.isHidden = true; gameOverLabel.isUserInteractionEnabled = false
        pauseButton.translatesAutoresizingMaskIntoConstraints = false
        pauseButton.setTitle("II",for:.normal); pauseButton.titleLabel?.font = .systemFont(ofSize:22,weight:.bold)
        pauseButton.addTarget(self,action:#selector(togglePause),for:.touchUpInside)
        pausePanel.translatesAutoresizingMaskIntoConstraints = false; pausePanel.backgroundColor = UIColor.black.withAlphaComponent(0.65); pausePanel.isHidden = true; pausePanel.isUserInteractionEnabled = false
        let pauseLabel = UILabel(); pauseLabel.translatesAutoresizingMaskIntoConstraints = false; pauseLabel.text = "PAUSED"; pauseLabel.textColor = .white; pauseLabel.font = .systemFont(ofSize:32,weight:.bold)
        pausePanel.addSubview(pauseLabel)
        NSLayoutConstraint.activate([pauseLabel.centerXAnchor.constraint(equalTo:pausePanel.centerXAnchor),pauseLabel.centerYAnchor.constraint(equalTo:pausePanel.centerYAnchor)])
        root.addSubview(hud); root.addSubview(crosshair); root.addSubview(prompt); root.addSubview(gameOverLabel); root.addSubview(pausePanel); root.addSubview(pauseButton)
        NSLayoutConstraint.activate([
            hud.leadingAnchor.constraint(equalTo:root.safeAreaLayoutGuide.leadingAnchor,constant:16),
            hud.topAnchor.constraint(equalTo:root.safeAreaLayoutGuide.topAnchor,constant:12),
            crosshair.centerXAnchor.constraint(equalTo:root.centerXAnchor),
            crosshair.centerYAnchor.constraint(equalTo:root.centerYAnchor),
            prompt.centerXAnchor.constraint(equalTo:root.centerXAnchor), prompt.bottomAnchor.constraint(equalTo:root.safeAreaLayoutGuide.bottomAnchor,constant:-30),
            gameOverLabel.centerXAnchor.constraint(equalTo:root.centerXAnchor), gameOverLabel.centerYAnchor.constraint(equalTo:root.centerYAnchor),
            pausePanel.leadingAnchor.constraint(equalTo:root.leadingAnchor),pausePanel.trailingAnchor.constraint(equalTo:root.trailingAnchor),pausePanel.topAnchor.constraint(equalTo:root.topAnchor),pausePanel.bottomAnchor.constraint(equalTo:root.bottomAnchor),
            pauseButton.trailingAnchor.constraint(equalTo:root.safeAreaLayoutGuide.trailingAnchor,constant:-16),pauseButton.topAnchor.constraint(equalTo:root.safeAreaLayoutGuide.topAnchor,constant:8),pauseButton.widthAnchor.constraint(equalToConstant:50),pauseButton.heightAnchor.constraint(equalToConstant:44)
        ])
        if let url=Bundle.main.url(forResource:"map",withExtension:"json",subdirectory:"test_map"), let data=try? Data(contentsOf:url) { mapDefinition=try? MapLoader.decode(data) }
        self.view = root
    }

    private func updateGame(deltaTime: Float) {
        let input = currentInputState()
        if session.state == .gameOver { if input.interact && !previousInteract { restartGame() }; previousInteract=input.interact; return }
        if session.state == .paused { return }
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
        if input.interact && !previousInteract, let map=mapDefinition {
            if let door=interactions.nearestDoor(in:map,to:player.state.position) { _=interactions.useDoor(door,economy:economy) }
            else if let item=interactions.nearest(in:map,to:player.state.position) { _=interactions.use(item,economy:economy,loadout:loadout) }
        }
        previousInteract=input.interact
        player.update(input: input, deltaTime: deltaTime)
        renderer?.cameraPosition = player.state.position + SIMD3<Float>(0, player.state.eyeHeight, 0)
        renderer?.cameraYaw = player.state.yaw
        renderer?.cameraPitch = player.state.pitch
        let damage = zombies.update(deltaTime: deltaTime, target: player.state.position)
        playerHealth = max(0, playerHealth - damage)
        if playerHealth <= 0 { session.gameOver(); gameOverLabel.text = "GAME OVER\nTap USE to restart"; gameOverLabel.isHidden = false; return }
        if rounds.round == 0 { rounds.startNext() }
        rounds.update(deltaTime: deltaTime, activeZombies: zombies.activeCount) { [weak self] in
            guard let self else { return }
            let n = Float(self.rounds.spawned)
            self.zombies.spawn(ZombieCatalog.walker, at: SIMD3<Float>((n.truncatingRemainder(dividingBy: 3)-1)*4, 0, -10-n))
        }
        zombies.removeDead()
        renderer?.zombiePositions = zombies.zombies.filter { $0.isAlive }.map { $0.position }
        if let map=mapDefinition {
            if let d=interactions.nearestDoor(in:map,to:player.state.position) { prompt.text="USE  Open door  \(d.cost)" }
            else if let i=interactions.nearest(in:map,to:player.state.position) { prompt.text="USE  \(i.kind.rawValue)  \(i.cost)" }
            else { prompt.text="" }
        }
        let w=loadout.active
        hud.text="HP \(Int(playerHealth))   PTS \(economy.points)   ROUND \(rounds.round)\n\(w.definition.displayName)   \(w.state.magazine)/\(w.state.reserve)   Z \(zombies.activeCount)"
    }

    @objc private func togglePause() {
        if session.state == .playing { session.pause(); pausePanel.isHidden=false }
        else if session.state == .paused { session.resume(); pausePanel.isHidden = true }
    }

    private func restartGame() {
        playerHealth = 100
        economy.setPoints(500)
        zombies.clear()
        rounds.reset()
        rounds.startNext()
        gameOverLabel.isHidden = true
        session.restart()
    }

    func currentInputState() -> InputState {
        let touch = InputState.merged(touchInput.consumeFrameState(), actionState)
        return InputState.merged(touch, controllerInput.state)
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .landscape }
    override var prefersHomeIndicatorAutoHidden: Bool { true }
}
