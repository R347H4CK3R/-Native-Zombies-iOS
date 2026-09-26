# Rendering milestone

The first rendering milestone establishes:
- MetalKit 60 Hz presentation target.
- Metal render pipeline compiled from project shaders.
- Depth testing.
- Perspective projection with a 70 degree baseline vertical FOV.
- GPU vertex resources and per-frame camera uniforms.
- A visible 3D-space validation primitive.
- CPU frame interval telemetry.

This is intentionally minimal. Lighting, materials, meshes, animation, culling and gameplay rendering are layered on after the base frame path is validated.
