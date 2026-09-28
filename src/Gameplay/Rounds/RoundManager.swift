import Foundation
import simd

struct RoundDefinition {
    let number:Int; let total:Int; let maxActive:Int; let healthMultiplier:Float
    let speedMultiplier:Float; let spawnInterval:Float; let damageMultiplier:Float; let bossRound:Bool
}
enum RoundCurve {
    static func definition(for round:Int) -> RoundDefinition {
        let r=max(1,round)
        return RoundDefinition(number:r,total:6+r*3,maxActive:min(24,5+r),healthMultiplier:1+Float(r-1)*0.12,speedMultiplier:min(1.65,1+Float(r-1)*0.025),spawnInterval:max(0.22,1.15-Float(r-1)*0.035),damageMultiplier:1+Float(r-1)*0.04,bossRound:r%10==0)
    }
}
enum RoundPhase:Equatable { case intermission, spawning, clearing }
final class RoundManager {
    private(set) var round=0; private(set) var phase:RoundPhase = .intermission
    private(set) var spawned=0; private var timer:Float=0; private var intermissionRemaining:Float=0
    var current:RoundDefinition { RoundCurve.definition(for:max(round,1)) }
    func reset(){ round=0; spawned=0; timer=0; intermissionRemaining=0; phase = .intermission }
    func startNext(){ round+=1; spawned=0; timer=0; intermissionRemaining=0; phase = .spawning }
    func update(deltaTime:Float,activeZombies:Int,spawn:()->Void) {
        guard round>0 else{return}; let dt=max(deltaTime,0); timer=max(0,timer-dt)
        if phase == .intermission { intermissionRemaining=max(0,intermissionRemaining-dt); if intermissionRemaining<=0 { startNext() }; return }
        if phase == .spawning {
            if spawned < current.total && activeZombies < current.maxActive && timer <= 0 { spawn(); spawned+=1; timer=current.spawnInterval }
            if spawned >= current.total { phase = .clearing }
        } else if phase == .clearing && activeZombies == 0 { phase = .intermission; intermissionRemaining=5 }
    }
}
