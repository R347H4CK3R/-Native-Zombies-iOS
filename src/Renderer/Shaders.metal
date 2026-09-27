#include <metal_stdlib>
using namespace metal;

struct SceneVertex { float3 position; float3 normal; float2 uv; };
struct FrameUniforms { float4x4 viewProjectionMatrix; };
struct VertexOut { float4 position [[position]]; float3 normal; float2 uv; };

vertex VertexOut scene_vertex(uint vid [[vertex_id]],
                              const device SceneVertex *vertices [[buffer(0)]],
                              constant FrameUniforms &frame [[buffer(1)]]) {
    VertexOut out;
    SceneVertex v=vertices[vid];
    out.position=frame.viewProjectionMatrix*float4(v.position,1.0);
    out.normal=v.normal; out.uv=v.uv; return out;
}
fragment float4 scene_fragment(VertexOut in [[stage_in]]) {
    float light=0.30+0.70*abs(normalize(in.normal).y);
    float checker=fmod(floor(in.uv.x*8.0)+floor(in.uv.y*8.0),2.0);
    float3 base=mix(float3(0.20,0.23,0.25),float3(0.42,0.45,0.47),checker);
    return float4(base*light,1.0);
}
