import Foundation
import simd

private struct NavCacheKey:Hashable {
    let fx:Int, fz:Int, tx:Int, tz:Int
}
final class CachedZombieNavigation: ZombieNavigation {
    private let base:ZombieNavigation; private let cellSize:Float; private let capacity:Int
    private var cache:[NavCacheKey:SIMD3<Float>]=[:]; private var order:[NavCacheKey]=[]
    private(set) var hits=0; private(set) var misses=0
    init(base:ZombieNavigation=DirectZombieNavigation(),cellSize:Float=2,capacity:Int=256){
        self.base=base; self.cellSize=max(0.5,cellSize); self.capacity=max(16,capacity)
    }
    func nextDirection(from:SIMD3<Float>,toward:SIMD3<Float>)->SIMD3<Float>{
        let k=NavCacheKey(fx:Int(floor(from.x/cellSize)),fz:Int(floor(from.z/cellSize)),tx:Int(floor(toward.x/cellSize)),tz:Int(floor(toward.z/cellSize)))
        if let d=cache[k]{hits+=1;return d}
        misses+=1; let d=base.nextDirection(from:from,toward:toward); cache[k]=d; order.append(k)
        if order.count>capacity { let old=order.removeFirst(); cache.removeValue(forKey:old) }
        return d
    }
    func reset(){cache.removeAll(keepingCapacity:true);order.removeAll(keepingCapacity:true);hits=0;misses=0}
}
struct PerformanceSnapshot {
    let frameMS:Double; let fps:Double; let activeZombies:Int; let navCacheHits:Int; let navCacheMisses:Int
}
final class PerformanceMonitor {
    private var smoothed:Double=16.67
    func sample(frameSeconds:Double,zombies:Int,navigation:CachedZombieNavigation?)->PerformanceSnapshot{
        let ms=max(0,frameSeconds*1000); smoothed=smoothed*0.9+ms*0.1
        return PerformanceSnapshot(frameMS:smoothed,fps:smoothed>0 ? 1000/smoothed:0,activeZombies:zombies,navCacheHits:navigation?.hits ?? 0,navCacheMisses:navigation?.misses ?? 0)
    }
}
