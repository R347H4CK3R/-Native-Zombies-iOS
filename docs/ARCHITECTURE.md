# Architecture

## Runtime layers
1. Platform: lifecycle, display, filesystem, audio session.
2. Input: touch, controller, gyro, normalized InputState.
3. Engine: clock, scene lifecycle, resources, jobs, telemetry.
4. Renderer: Metal command submission, camera, materials, culling.
5. Gameplay: player, weapons, zombies, rounds, economy, perks, interactions.
6. Navigation/AI: nav data, path cache, staggered AI scheduling.
7. UI: HUD, menus, touch layout, developer menu.
8. Data: registries loaded from validated external definitions.
9. Save: settings, controls, progression/test profiles.

## Frame target
60 Hz = 16.67 ms total frame budget. Expensive AI/navigation work must be scheduled and amortized rather than executed for every zombie every frame.

## Registries
WeaponRegistry, ZombieRegistry, PerkRegistry and MapRegistry are authoritative enumerations. UI and developer tools consume registry data rather than hardcoded item lists.

## Developer API
DEV_MOD_MENU gates compilation. Mod actions call controlled subsystem interfaces such as PlayerSystem.setGodMode, WeaponSystem.setInfiniteAmmo, RoundManager.setRound and ZombieManager.killAll.

## Content boundary
No proprietary Activision assets or source are permitted in tracked distributable content.
