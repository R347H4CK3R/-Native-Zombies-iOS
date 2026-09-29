import Foundation
import simd

final class WorldInteractionManager {
    private(set) var unlockedDoors:Set<String> = []
    private(set) var powerOn = false
    private(set) var upgradeLevel = 0
    let perks = PerkInventory()
    private var boxIndex = 0
    func unlockAll(in map:MapDefinition){ unlockedDoors.formUnion(map.doors.map{$0.id}) }
    func resetWorld(){ unlockedDoors.removeAll(); powerOn=false; upgradeLevel=0; perks.reset(); boxIndex=0 }
    func setPower(_ enabled:Bool){ powerOn=enabled }
    private let boxWeapons = [StarterWeapons.pistol.id,StarterWeapons.rifle.id,StarterWeapons.shotgun.id]

    func nearest(in map:MapDefinition, to p:SIMD3<Float>, maxDistance:Float=2.5) -> MapInteraction? {
        map.interactions.min { simd_distance($0.position.simd,p) < simd_distance($1.position.simd,p) }
            .flatMap { simd_distance($0.position.simd,p) <= maxDistance ? $0 : nil }
    }
    func nearestDoor(in map:MapDefinition,to p:SIMD3<Float>,maxDistance:Float=2.5)->MapDoor? {
        map.doors.filter{!unlockedDoors.contains($0.id)}
            .min{simd_distance($0.position.simd,p)<simd_distance($1.position.simd,p)}
            .flatMap{simd_distance($0.position.simd,p)<=maxDistance ? $0:nil}
    }
    @discardableResult
    func useDoor(_ door:MapDoor,economy:EconomyManager)->Bool {
        guard economy.spend(door.cost) else{return false}; unlockedDoors.insert(door.id); return true
    }
    @discardableResult
    func use(_ item:MapInteraction,economy:EconomyManager,loadout:WeaponLoadout)->Bool {
        switch item.kind {
        case .perk:
            guard item.contentID == PerkCatalog.vitality.id else{return false}
            return perks.purchase(PerkCatalog.vitality,economy:economy)
        case .upgrade:
            guard economy.spend(item.cost) else{return false}; upgradeLevel=min(3,upgradeLevel+1); return true
        case .ammo:
            return economy.spend(item.cost)
        case .power:
            powerOn=true; return true
        case .wallBuy:
            return economy.spend(item.cost)
        case .randomBox:
            guard economy.spend(item.cost) else{return false}; let id=boxWeapons[boxIndex % boxWeapons.count]; boxIndex += 1; return loadout.selectWeapon(id:id)
        }
    }
}
