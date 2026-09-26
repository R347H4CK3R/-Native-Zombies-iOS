import Foundation
import simd

enum ZombieAIState: Equatable { case spawn, search, chase, navigate, attack, stagger, death }
struct ZombieDefinition: RegistryItem {
    let id:String; let displayName:String; let maxHealth:Float; let moveSpeed:Float
    let attackDamage:Float; let attackRange:Float; let attackCooldown:Float
}
protocol ZombieNavigation {
    func nextDirection(from: SIMD3<Float>, toward: SIMD3<Float>) -> SIMD3<Float>
}
struct DirectZombieNavigation: ZombieNavigation {
    func nextDirection(from: SIMD3<Float>, toward: SIMD3<Float>) -> SIMD3<Float> {
        let d = SIMD3<Float>(toward.x-from.x,0,toward.z-from.z)
        return simd_length_squared(d) > 0.0001 ? simd_normalize(d) : .zero
    }
}
final class ZombieAgent: Damageable {
    let definition: ZombieDefinition
    private(set) var position: SIMD3<Float>
    private(set) var health: Float
    private(set) var state: ZombieAIState = .spawn
    private var attackTimer: Float = 0
    private var staggerTimer: Float = 0
    private var spawnTimer: Float = 0.25
    var isAlive: Bool { health > 0 }

    init(definition: ZombieDefinition, position: SIMD3<Float>) {
        self.definition=definition; self.position=position; self.health=definition.maxHealth
    }
    func applyDamage(_ amount: Float, zone: HitZone) {
        guard isAlive else { return }
        health=max(0,health-amount)
        if health == 0 { state = .death }
        else { staggerTimer=0.12; state = .stagger }
    }
    @discardableResult
    func update(deltaTime rawDT: Float, target: SIMD3<Float>?, navigation: ZombieNavigation) -> Float {
        let dt=min(max(rawDT,0),1.0/15.0)
        attackTimer=max(0,attackTimer-dt)
        if !isAlive { state = .death; return 0 }
        if spawnTimer > 0 { spawnTimer-=dt; state = .spawn; return 0 }
        if staggerTimer > 0 { staggerTimer-=dt; state = .stagger; return 0 }
        guard let target else { state = .search; return 0 }
        let delta=target-position
        let distance=simd_length(SIMD2<Float>(delta.x,delta.z))
        if distance <= definition.attackRange {
            state = .attack
            if attackTimer <= 0 { attackTimer=definition.attackCooldown; return definition.attackDamage }
            return 0
        }
        state = .chase
        let direction=navigation.nextDirection(from: position,toward: target)
        position += direction * definition.moveSpeed * dt
        return 0
    }
}
enum ZombieCatalog {
    static let walker = ZombieDefinition(id:"walker",displayName:"Walker",maxHealth:100,moveSpeed:1.7,attackDamage:25,attackRange:1.25,attackCooldown:1.0)
    static let runner = ZombieDefinition(id:"runner",displayName:"Runner",maxHealth:110,moveSpeed:3.4,attackDamage:22,attackRange:1.2,attackCooldown:0.8)
    static let brute = ZombieDefinition(id:"brute",displayName:"Brute",maxHealth:450,moveSpeed:1.35,attackDamage:45,attackRange:1.5,attackCooldown:1.4)
}
