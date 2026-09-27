import XCTest
@testable import NativeZombies

final class MapDefinitionTests:XCTestCase {
    func testVerticalSliceMapDecodes() throws {
        let json=#"""
        {"id":"test","displayName":"Test","playerSpawn":{"x":0,"y":0,"z":0},"rooms":[{"id":"spawn","displayName":"Spawn"}],"doors":[],"zombieSpawns":[{"id":"z","room":"spawn","position":{"x":1,"y":0,"z":1}}],"interactions":[{"id":"buy","kind":"wallBuy","position":{"x":0,"y":0,"z":1},"cost":500,"contentID":"starter_pistol"}],"navigation":[{"x":0,"y":0,"z":0}]}
        """#.data(using:.utf8)!
        let map=try MapLoader.decode(json)
        XCTAssertEqual(map.id,"test")
        XCTAssertEqual(map.rooms.count,1)
        XCTAssertEqual(map.zombieSpawns.count,1)
        XCTAssertEqual(map.interactions.first?.kind,.wallBuy)
    }
}
