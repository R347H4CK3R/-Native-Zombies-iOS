import Foundation
import simd

struct MapPoint: Codable, Equatable {
    let x: Float; let y: Float; let z: Float
    var simd: SIMD3<Float> { SIMD3<Float>(x,y,z) }
}
struct MapRoom: Codable, Equatable { let id:String; let displayName:String }
struct MapDoor: Codable, Equatable { let id:String; let from:String; let to:String; let cost:Int; let position:MapPoint }
struct ZombieSpawnPoint: Codable, Equatable { let id:String; let room:String; let position:MapPoint }
enum InteractionKind:String,Codable { case wallBuy, perk, upgrade, ammo, randomBox, power }
struct MapInteraction: Codable, Equatable { let id:String; let kind:InteractionKind; let position:MapPoint; let cost:Int; let contentID:String? }
struct MapDefinition: Codable, Equatable {
    let id:String; let displayName:String; let playerSpawn:MapPoint
    let rooms:[MapRoom]; let doors:[MapDoor]; let zombieSpawns:[ZombieSpawnPoint]
    let interactions:[MapInteraction]; let navigation:[MapPoint]
}
enum MapLoader {
    static func decode(_ data:Data) throws -> MapDefinition { try JSONDecoder().decode(MapDefinition.self,from:data) }
}
