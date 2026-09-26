import Foundation
import GameController
import simd

@MainActor
final class ControllerInputManager {
    private(set) var state = InputState()
    private(set) var controllerConnected = false

    init() {
        NotificationCenter.default.addObserver(forName: .GCControllerDidConnect, object: nil, queue: .main) { [weak self] note in
            guard let controller = note.object as? GCController else { return }
            Task { @MainActor in self?.attach(controller) }
        }
        NotificationCenter.default.addObserver(forName: .GCControllerDidDisconnect, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                self?.controllerConnected = !GCController.controllers().isEmpty
                self?.state = InputState()
            }
        }
        GCController.startWirelessControllerDiscovery(completionHandler: nil)
        if let controller = GCController.controllers().first { attach(controller) }
    }

    private func attach(_ controller: GCController) {
        guard let pad = controller.extendedGamepad else { return }
        controllerConnected = true
        pad.valueChangedHandler = { [weak self] gamepad, _ in
            Task { @MainActor in self?.read(gamepad) }
        }
        read(pad)
    }

    private func read(_ pad: GCExtendedGamepad) {
        state.movement = SIMD2<Float>(pad.leftThumbstick.xAxis.value, pad.leftThumbstick.yAxis.value)
        state.look = SIMD2<Float>(pad.rightThumbstick.xAxis.value, -pad.rightThumbstick.yAxis.value)
        state.ads = pad.leftTrigger.isPressed
        state.fire = pad.rightTrigger.isPressed
        state.jump = pad.buttonA.isPressed
        state.crouch = pad.buttonB.isPressed
        state.reload = pad.buttonX.isPressed
        state.interact = pad.buttonX.isPressed
        state.sprint = pad.leftThumbstickButton?.isPressed ?? false
        state.melee = pad.rightThumbstickButton?.isPressed ?? false
    }
}
