import MetalKit

final class GameRenderer: NSObject, MTKViewDelegate {
    private let commandQueue: MTLCommandQueue

    init(view: MTKView) {
        guard let queue = view.device?.makeCommandQueue() else {
            fatalError("Unable to create Metal command queue")
        }
        commandQueue = queue
        super.init()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        guard let descriptor = view.currentRenderPassDescriptor,
              let drawable = view.currentDrawable,
              let buffer = commandQueue.makeCommandBuffer() else { return }

        descriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0.02, green: 0.02, blue: 0.025, alpha: 1)
        descriptor.colorAttachments[0].loadAction = .clear
        descriptor.colorAttachments[0].storeAction = .store

        if let encoder = buffer.makeRenderCommandEncoder(descriptor: descriptor) {
            encoder.endEncoding()
        }
        buffer.present(drawable)
        buffer.commit()
    }
}
