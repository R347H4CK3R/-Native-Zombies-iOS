import Foundation
import simd

enum WeaponCategory: String, Codable { case assaultRifle, smg, shotgun, lmg, sniper, pistol, launcher, melee, special }
enum FireMode: String, Codable { case semiAutomatic, automatic }

struct WeaponDefinition: RegistryItem, Equatable {
    let id: String
    let displayName: String
    let category: WeaponCategory
    let damage: Float
    let headshotMultiplier: Float
    let roundsPerMinute: Float
    let magazineSize: Int
    let reserveCapacity: Int
    let reloadSeconds: Float
    let adsSeconds: Float
    let recoil: Float
    let hipSpread: Float
    let adsSpread: Float
    let range: Float
    let movementModifier: Float
    let fireMode: FireMode
}

struct WeaponRuntimeState: Equatable {
    var magazine: Int
    var reserve: Int
    var cooldown: Float = 0
    var reloadRemaining: Float = 0
    var isReloading: Bool { reloadRemaining > 0 }
}

struct ShotResult: Equatable {
    let damage: Float
    let spread: Float
    let recoil: Float
}

final class WeaponInstance {
    let definition: WeaponDefinition
    private(set) var state: WeaponRuntimeState

    init(definition: WeaponDefinition) {
        self.definition = definition
        self.state = WeaponRuntimeState(magazine: definition.magazineSize, reserve: definition.reserveCapacity)
    }

    func update(deltaTime: Float) {
        let dt = max(deltaTime, 0)
        state.cooldown = max(0, state.cooldown - dt)
        guard state.reloadRemaining > 0 else { return }
        state.reloadRemaining -= dt
        if state.reloadRemaining <= 0 {
            state.reloadRemaining = 0
            let needed = definition.magazineSize - state.magazine
            let moved = min(needed, state.reserve)
            state.magazine += moved
            state.reserve -= moved
        }
    }

    @discardableResult
    func fire(ads: Bool, headshot: Bool = false) -> ShotResult? {
        guard state.magazine > 0, state.cooldown <= 0, !state.isReloading else { return nil }
        state.magazine -= 1
        state.cooldown = 60.0 / max(definition.roundsPerMinute, 1)
        let damage = definition.damage * (headshot ? definition.headshotMultiplier : 1)
        return ShotResult(damage: damage, spread: ads ? definition.adsSpread : definition.hipSpread, recoil: definition.recoil)
    }

    func beginReload() {
        guard !state.isReloading, state.magazine < definition.magazineSize, state.reserve > 0 else { return }
        state.reloadRemaining = definition.reloadSeconds
    }

    func cancelReload() { state.reloadRemaining = 0 }
}

enum StarterWeapons {
    static let pistol = WeaponDefinition(id:"starter_pistol", displayName:"Service Pistol", category:.pistol, damage:32, headshotMultiplier:2, roundsPerMinute:420, magazineSize:12, reserveCapacity:96, reloadSeconds:1.45, adsSeconds:0.16, recoil:0.7, hipSpread:1.7, adsSpread:0.35, range:45, movementModifier:1, fireMode:.semiAutomatic)
    static let rifle = WeaponDefinition(id:"test_rifle", displayName:"Test Rifle", category:.assaultRifle, damage:38, headshotMultiplier:1.75, roundsPerMinute:690, magazineSize:30, reserveCapacity:180, reloadSeconds:1.9, adsSeconds:0.22, recoil:0.9, hipSpread:2.1, adsSpread:0.3, range:80, movementModifier:0.95, fireMode:.automatic)
    static let shotgun = WeaponDefinition(id:"test_shotgun", displayName:"Test Shotgun", category:.shotgun, damage:110, headshotMultiplier:1.25, roundsPerMinute:75, magazineSize:8, reserveCapacity:48, reloadSeconds:2.4, adsSeconds:0.25, recoil:2.4, hipSpread:5.0, adsSpread:3.0, range:22, movementModifier:0.92, fireMode:.semiAutomatic)
}
