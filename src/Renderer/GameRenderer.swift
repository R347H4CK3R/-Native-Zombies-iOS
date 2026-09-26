import MetalKit
import QuartzCore
import simd

final class GameRenderer: NSObject, MTKViewDelegate {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let pipeline: MTLRenderPipelineState
    private let depthState: MTLDepthStencilState
    private let vertexBuffer: MTLBuffer
    private var projection = matrix_identity_float4x4
    private(set) var cpuFrameTimeMS: Double = 0
    private var previousFrameTime = CACurrentMediaTime()

    private static let vertices: [Vertex] = [
        Vertex(position: [-1, -1, 0], color: [1, 0.15, 0.1, 1]),
        Vertex(position: [ 1, -1, 0], color: [0.1, 1, 0.2, 1]),
        Vertex(position: [ 0,  1, 0], color: [0.15, 0.35, 1, 1])
    ]

    init(view: MTKView) {
        guard let device = view.device,
              let queue = device.makeCommandQueue(),
              let library = device.makeDefaultLibrary(),
              let vertex = library.makeFunction(name: "basic_vertex"),
              let fragment = library.makeFunction(name: "basic_fragment") else {
            fatalError("Metal renderer initialization failed")
        }
        self.device = device
        self.commandQueue = queue

        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertex
        descriptor.fragmentFunction = fragment
        descriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
        descriptor.depthAttachmentPixelFormat = view.depthStencilPixelFormat
        do {
            pipeline = try device.makeRenderPipelineState(descriptor: descriptor)
        } catch {
            fatalError("Pipeline creation failed: \(error)")
        }

        let depth = MTLDepthStencilDescriptor()
        depth.depthCompareFunction = .less
        depth.isDepthWriteEnabled = true
        guard let depthState = device.makeDepthStencilState(descriptor: depth),
              let vb = device.makeBuffer(bytes: Self.vertices,
                                         length: MemoryLayout<Vertex>.stride * Self.vertices.count) else {
            fatalError("GPU resource allocation failed")
        }
        self.depthState = depthState
        self.vertexBuffer = vb
        super.init()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        guard size.height > 0 else { return }
        projection = .perspective(fovY: 70 * .pi / 180,
                                  aspect: Float(size.width / size.height),
                                  nearZ: 0.05,
                                  farZ: 500)
    }

    func draw(in view: MTKView) {
        let now = CACurrentMediaTime()
        cpuFrameTimeMS = (now - previousFrameTime) * 1000
        previousFrameTime = now

        guard let pass = view.currentRenderPassDescriptor,
              let drawable = view.currentDrawable,
              let commandBuffer = commandQueue.makeCommandBuffer() else { return }

        pass.colorAttachments[0].clearColor = MTLClearColor(red: 0.02, green: 0.02, blue: 0.025, alpha: 1)
        pass.colorAttachments[0].loadAction = .clear
        pass.colorAttachments[0].storeAction = .store
        pass.depthAttachment.clearDepth = 1
        pass.depthAttachment.loadAction = .clear
        pass.depthAttachment.storeAction = .dontCare

        var frame = FrameUniforms(viewProjectionMatrix: projection * .translation([0, 0, -3]))

        if let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: pass) {
            encoder.setRenderPipelineState(pipeline)
            encoder.setDepthStencilState(depthState)
            encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            encoder.setVertexBytes(&frame, length: MemoryLayout<FrameUniforms>.stride, index: 1)
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: Self.vertices.count)
            encoder.endEncoding()
        }

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
