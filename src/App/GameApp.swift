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

    override func loadView() {
        guard let device = MTLCreateSystemDefaultDevice() else { fatalError("Metal is required") }
        let root = UIView()
        let metal = MTKView(frame: .zero, device: device)
        metal.preferredFramesPerSecond = 60
        metal.colorPixelFormat = .bgra8Unorm
        metal.depthStencilPixelFormat = .depth32Float
        renderer = GameRenderer(view: metal)
        metal.delegate = renderer

        for v in [metal, touchInput, actionOverlay] {
            v.translatesAutoresizingMaskIntoConstraints = false
            root.addSubview(v)
            NSLayoutConstraint.activate([v.leadingAnchor.constraint(equalTo: root.leadingAnchor), v.trailingAnchor.constraint(equalTo: root.trailingAnchor), v.topAnchor.constraint(equalTo: root.topAnchor), v.bottomAnchor.constraint(equalTo: root.bottomAnchor)])
        }
        actionOverlay.onStateChanged = { [weak self] in self?.actionState = $0 }
        self.view = root
    }

    func currentInputState() -> InputState {
        let touch = InputState.merged(touchInput.consumeFrameState(), actionState)
        return InputState.merged(touch, controllerInput.state)
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .landscape }
    override var prefersHomeIndicatorAutoHidden: Bool { true }
}
