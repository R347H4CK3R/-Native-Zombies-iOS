import simd

struct Vertex {
    var position: SIMD3<Float>
    var color: SIMD4<Float>
}

struct FrameUniforms {
    var viewProjectionMatrix: simd_float4x4
}
