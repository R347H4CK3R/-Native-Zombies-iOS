import XCTest
@testable import NativeZombies
final class PerformanceTests:XCTestCase {
    func testNavigationSharesQuantizedRouteQueries(){
        let nav=CachedZombieNavigation()
        _=nav.nextDirection(from:.init(0,0,0),toward:.init(10,0,0))
        _=nav.nextDirection(from:.init(0.2,0,0.2),toward:.init(10.2,0,0.1))
        XCTAssertEqual(nav.misses,1); XCTAssertEqual(nav.hits,1)
    }
    func testPerformanceSnapshotReportsFiniteFPS(){
        let s=PerformanceMonitor().sample(frameSeconds:1.0/60.0,zombies:20,navigation:nil)
        XCTAssertTrue(s.fps.isFinite); XCTAssertGreaterThan(s.fps,0); XCTAssertEqual(s.activeZombies,20)
    }
}
