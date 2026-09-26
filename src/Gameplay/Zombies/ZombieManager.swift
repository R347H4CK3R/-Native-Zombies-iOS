import Foundation
import simd

final class ZombieManager {
    private(set) var zombies:[ZombieAgent]=[]
    let navigation: ZombieNavigation
    init(navigation: ZombieNavigation = DirectZombieNavigation()){ self.navigation=navigation }
    func spawn(_ definition: ZombieDefinition, at position: SIMD3<Float>) { zombies.append(ZombieAgent(definition:definition,position:position)) }
    @discardableResult func update(deltaTime:Float,target:SIMD3<Float>?) -> Float {
        var damage:Float=0
        for zombie in zombies where zombie.isAlive { damage += zombie.update(deltaTime:deltaTime,target:target,navigation:navigation) }
        return damage
    }
    func killAll(){ for z in zombies where z.isAlive { z.applyDamage(Float.greatestFiniteMagnitude,zone:.body) } }
    func removeDead(){ zombies.removeAll{ !$0.isAlive } }
    var activeCount:Int { zombies.reduce(0){$0+($1.isAlive ? 1:0)} }
}
