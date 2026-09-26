# Player FPS controller

Step 6 establishes the gameplay-side first-person locomotion model independently of any specific input device.

Implemented:
- walk, forward sprint and crouch speeds
- jump, gravity and grounding
- yaw/pitch look with vertical clamp
- standing/crouching eye heights
- normalized diagonal movement
- delta-time clamp to limit large simulation jumps
- camera forward-vector output
- temporary ground-plane collision

Map collision and step/slope resolution are intentionally deferred to the map/physics integration milestone. Step 7 maps touch and GameController input into the shared InputState.
