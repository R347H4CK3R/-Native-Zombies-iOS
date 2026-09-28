import Foundation
import simd

final class ZombieHitscanWorld: HitscanWorld {
    var zombies: [ZombieAgent] = []
    func trace(origin: SIMD3<Float>, direction: SIMD3<Float>, maxDistance: Float) -> (WeaponHit, Damageable)? {
        let d = simd_normalize(direction)
        var best: (Float, WeaponHit, ZombieAgent)?
        for z in zombies where z.isAlive {
            let center = z.position + SIMD3<Float>(0, 0.9, 0)
            let oc = origin - center
            let radius: Float = 0.55
            let b = simd_dot(oc, d)
            let c = simd_dot(oc, oc) - radius * radius
            let disc = b*b-c
            guard disc >= 0 else { continue }
            let t = -b - sqrt(disc)
            guard t >= 0, t <= maxDistance else { continue }
            let p = origin + d*t
            let head = p.y > z.position.y + 1.35
            let hit = WeaponHit(point:p, normal:simd_normalize(p-center), distance:t, zone:head ? .head : .body)
            if best == nil || t < best!.0 { best=(t,hit,z) }
        }
        guard let b=best else { return nil }
        return (b.1,b.2)
    }
}
