import Foundation

enum PointEvent { case damage, kill, headshot, melee, repair, objective }
struct EconomyConfig { var damage=10, kill=90, headshot=40, melee=60, repair=10, objective=250 }
final class EconomyManager {
    private(set) var points:Int; var config=EconomyConfig(); var infinitePoints=false; var freePurchases=false
    init(points:Int=500){self.points=points}
    func award(_ event:PointEvent){ points += reward(event) }
    func canAfford(_ cost:Int)->Bool { infinitePoints || freePurchases || points>=cost }
    @discardableResult func spend(_ cost:Int)->Bool { guard canAfford(cost) else{return false}; if !infinitePoints && !freePurchases {points-=cost}; return true }
    func setPoints(_ value:Int){points=max(0,value)}
    func addPoints(_ value:Int){points=max(0,points+value)}
    private func reward(_ e:PointEvent)->Int { switch e {case .damage:return config.damage;case .kill:return config.kill;case .headshot:return config.headshot;case .melee:return config.melee;case .repair:return config.repair;case .objective:return config.objective} }
}
struct PerkDefinition:RegistryItem { let id:String; let displayName:String; let cost:Int; let maxLevel:Int }
final class PerkInventory {
    private(set) var levels:[String:Int]=[:]
    func level(_ id:String)->Int { levels[id] ?? 0 }
    func purchase(_ perk:PerkDefinition,economy:EconomyManager)->Bool {
        let next=level(perk.id)+1; guard next<=perk.maxLevel,economy.spend(perk.cost) else{return false}; levels[perk.id]=next; return true
    }
    func reset(){levels.removeAll()}
}
enum PerkCatalog {
    static let vitality=PerkDefinition(id:"vitality",displayName:"Vitality",cost:2500,maxLevel:3)
    static let quickHands=PerkDefinition(id:"quick_hands",displayName:"Quick Hands",cost:2000,maxLevel:3)
}
