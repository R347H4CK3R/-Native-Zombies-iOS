#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    packed_float3 position;
    packed_float4 color;
};

struct FrameUniforms {
    float4x4 viewProjectionMatrix;
};

struct VertexOut {
    float4 position [[position]];
    float4 color;
};

vertex VertexOut basic_vertex(uint vid [[vertex_id]],
                              const device VertexIn *vertices [[buffer(0)]],
                              constant FrameUniforms &frame [[buffer(1)]]) {
    VertexOut out;
    out.position = frame.viewProjectionMatrix * float4(vertices[vid].position, 1.0);
    out.color = vertices[vid].color;
    return out;
}

fragment float4 basic_fragment(VertexOut in [[stage_in]]) {
    return in.color;
}
