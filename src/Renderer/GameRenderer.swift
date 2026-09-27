import MetalKit
import QuartzCore
import simd

final class GameRenderer: NSObject, MTKViewDelegate {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let pipeline: MTLRenderPipelineState
    private let depthState: MTLDepthStencilState
    private let vertexBuffer: MTLBuffer
    private let vertexCount: Int
    private var projection = matrix_identity_float4x4
    private(set) var cpuFrameTimeMS: Double = 0
    private var previousFrameTime = CACurrentMediaTime()
    var frameHandler: ((Float) -> Void)?

    private static func makeTestFacility() -> [SceneVertex] {
        var v:[SceneVertex]=[]
        func quad(_ a:SIMD3<Float>,_ b:SIMD3<Float>,_ c:SIMD3<Float>,_ d:SIMD3<Float>,_ n:SIMD3<Float>) {
            v += [SceneVertex(position:a,normal:n,uv:[0,0]),SceneVertex(position:b,normal:n,uv:[1,0]),SceneVertex(position:c,normal:n,uv:[1,1]),
                  SceneVertex(position:a,normal:n,uv:[0,0]),SceneVertex(position:c,normal:n,uv:[1,1]),SceneVertex(position:d,normal:n,uv:[0,1])]
        }
        // Original placeholder facility: spawn room, service hall, arena.
        quad([-8,0,5],[8,0,5],[8,0,-8],[-8,0,-8],[0,1,0])
        quad([-4,0,-8],[4,0,-8],[4,0,-21],[-4,0,-21],[0,1,0])
        quad([-10,0,-21],[10,0,-21],[10,0,-36],[-10,0,-36],[0,1,0])
        func wall(_ x0:Float,_ z0:Float,_ x1:Float,_ z1:Float) {
            let a=SIMD3<Float>(x0,0,z0), b=SIMD3<Float>(x1,0,z1), c=SIMD3<Float>(x1,3,z1), d=SIMD3<Float>(x0,3,z0)
            let dx=x1-x0,dz=z1-z0; let n=simd_normalize(SIMD3<Float>(-dz,0,dx)); quad(a,b,c,d,n)
        }
        wall(-8,5,8,5); wall(-8,-8,-8,5); wall(8,5,8,-8)
        wall(-8,-8,-1,-8); wall(1,-8,8,-8)
        wall(-4,-8,-4,-21); wall(4,-21,4,-8)
        wall(-4,-21,-1,-21); wall(1,-21,4,-21)
        wall(-10,-21,-10,-36); wall(10,-36,10,-21); wall(-10,-36,10,-36)
        return v
    }

    init(view: MTKView) {
        guard let device = view.device,
              let queue = device.makeCommandQueue(),
              let library = device.makeDefaultLibrary(),
              let vertex = library.makeFunction(name: "scene_vertex"),
              let fragment = library.makeFunction(name: "scene_fragment") else {
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
        let sceneVertices = Self.makeTestFacility()
        guard let depthState = device.makeDepthStencilState(descriptor: depth),
              let vb = device.makeBuffer(bytes: sceneVertices,
                                         length: MemoryLayout<SceneVertex>.stride * sceneVertices.count) else {
            fatalError("GPU resource allocation failed")
        }
        self.depthState = depthState
        self.vertexBuffer = vb
        self.vertexCount = sceneVertices.count
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
        let dt = Float(now - previousFrameTime)
        previousFrameTime = now
        frameHandler?(min(max(dt, 0), 1.0 / 15.0))

        guard let pass = view.currentRenderPassDescriptor,
              let drawable = view.currentDrawable,
              let commandBuffer = commandQueue.makeCommandBuffer() else { return }

        pass.colorAttachments[0].clearColor = MTLClearColor(red: 0.02, green: 0.02, blue: 0.025, alpha: 1)
        pass.colorAttachments[0].loadAction = .clear
        pass.colorAttachments[0].storeAction = .store
        pass.depthAttachment.clearDepth = 1
        pass.depthAttachment.loadAction = .clear
        pass.depthAttachment.storeAction = .dontCare

        var frame = FrameUniforms(viewProjectionMatrix: projection * .translation([0, -1.65, -3]))

        if let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: pass) {
            encoder.setRenderPipelineState(pipeline)
            encoder.setDepthStencilState(depthState)
            encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            encoder.setVertexBytes(&frame, length: MemoryLayout<FrameUniforms>.stride, index: 1)
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount)
            encoder.endEncoding()
        }

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
