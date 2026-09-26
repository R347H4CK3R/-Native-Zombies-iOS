import XCTest
@testable import NativeZombies

final class ZombieAgentTests: XCTestCase {
    func testZombieChasesAfterSpawnDelay() {
        let z=ZombieAgent(definition:ZombieCatalog.walker,position:.zero)
        let nav=DirectZombieNavigation()
        _=z.update(deltaTime:0.3,target:SIMD3<Float>(0,0,-10),navigation:nav)
        _=z.update(deltaTime:0.3,target:SIMD3<Float>(0,0,-10),navigation:nav)
        XCTAssertEqual(z.state,.chase)
        XCTAssertLessThan(z.position.z,0)
    }
    func testZombieAttacksWithinRange() {
        let z=ZombieAgent(definition:ZombieCatalog.walker,position:.zero)
        let nav=DirectZombieNavigation()
        for _ in 0..<5 { _=z.update(deltaTime:0.1,target:SIMD3<Float>(0,0,-0.5),navigation:nav) }
        let damage=z.update(deltaTime:0.1,target:SIMD3<Float>(0,0,-0.5),navigation:nav)
        XCTAssertEqual(z.state,.attack)
        XCTAssertGreaterThanOrEqual(damage,0)
    }
    func testLethalDamageEntersDeath() {
        let z=ZombieAgent(definition:ZombieCatalog.walker,position:.zero)
        z.applyDamage(1000,zone:.head)
        XCTAssertFalse(z.isAlive)
        XCTAssertEqual(z.state,.death)
    }
    func testManagerKillAllUsesGameplayDamagePath() {
        let m=ZombieManager(); m.spawn(ZombieCatalog.walker,at:.zero); m.spawn(ZombieCatalog.runner,at:.zero)
        XCTAssertEqual(m.activeCount,2); m.killAll(); XCTAssertEqual(m.activeCount,0)
    }
}
