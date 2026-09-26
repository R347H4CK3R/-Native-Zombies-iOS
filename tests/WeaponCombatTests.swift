import XCTest
@testable import NativeZombies

final class WeaponCombatTests: XCTestCase {
    final class Target: Damageable {
        var health: Float = 200
        var isAlive: Bool { health > 0 }
        func applyDamage(_ amount: Float, zone: HitZone) { health -= amount }
    }
    struct World: HitscanWorld {
        let target: Target
        let zone: HitZone
        func trace(origin: SIMD3<Float>, direction: SIMD3<Float>, maxDistance: Float) -> (WeaponHit, Damageable)? {
            (WeaponHit(point: .zero, normal: SIMD3<Float>(0,1,0), distance: 5, zone: zone), target)
        }
    }
    func testHeadshotUsesDefinitionMultiplier() {
        let target = Target()
        let weapon = WeaponInstance(definition: StarterWeapons.pistol)
        let world = World(target: target, zone: .head)
        _ = WeaponCombatSystem().fire(weapon, ads: true, origin: .zero, direction: SIMD3<Float>(0,0,-1), world: world)
        XCTAssertEqual(target.health, 136)
    }
    func testCatalogContainsStarterWeapons() {
        let registry = WeaponCatalog.makeRegistry()
        XCTAssertNotNil(registry.item(id: StarterWeapons.pistol.id))
        XCTAssertNotNil(registry.item(id: StarterWeapons.rifle.id))
        XCTAssertNotNil(registry.item(id: StarterWeapons.shotgun.id))
    }
}
