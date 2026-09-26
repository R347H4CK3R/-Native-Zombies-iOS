# Native Zombies iOS

Native ARM64 iOS round-based Zombies FPS built independently for iPhone.

## Targets
- iPhone 16 Plus
- ARM64 iOS
- Landscape
- 60 FPS target
- Multitouch + Apple GameController
- Offline single-player first
- Unsigned IPA for personal testing

## Architecture
Swift UI/application shell with Metal/MetalKit rendering and performance-critical C++/Objective-C++ modules where justified. Gameplay content is data-driven through weapon, zombie, perk, round and map registries.

## Legal
This repository must not contain proprietary Call of Duty/Activision code or assets. Reference gameplay may be studied for behavior; implementation and distributable assets must be original, public-domain, or appropriately licensed.

## Development
Development builds use DEV_MOD_MENU=1. Normal builds may compile the developer interface out with DEV_MOD_MENU=0.
