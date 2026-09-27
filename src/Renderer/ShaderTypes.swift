import simd

struct SceneVertex {
    var position: SIMD3<Float>
    var normal: SIMD3<Float>
    var uv: SIMD2<Float>
}
struct FrameUniforms { var viewProjectionMatrix: simd_float4x4 }
