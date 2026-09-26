import Foundation
import simd

enum HitZone { case body, head }

struct WeaponHit {
    let point: SIMD3<Float>
    let normal: SIMD3<Float>
    let distance: Float
    let zone: HitZone
}

protocol Damageable: AnyObject {
    var isAlive: Bool { get }
    func applyDamage(_ amount: Float, zone: HitZone)
}

protocol HitscanWorld {
    func trace(origin: SIMD3<Float>, direction: SIMD3<Float>, maxDistance: Float) -> (WeaponHit, Damageable)?
}

struct WeaponCombatSystem {
    @discardableResult
    func fire(_ weapon: WeaponInstance, ads: Bool, origin: SIMD3<Float>, direction: SIMD3<Float>, world: HitscanWorld) -> WeaponHit? {
        guard let shot = weapon.fire(ads: ads) else { return nil }
        guard let (hit, target) = world.trace(origin: origin, direction: simd_normalize(direction), maxDistance: weapon.definition.range) else { return nil }
        let multiplier = hit.zone == .head ? weapon.definition.headshotMultiplier : 1
        target.applyDamage(shot.damage * multiplier, zone: hit.zone)
        return hit
    }
}
