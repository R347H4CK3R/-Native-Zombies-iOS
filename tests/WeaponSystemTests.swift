import XCTest
@testable import NativeZombies

final class WeaponSystemTests: XCTestCase {
    func testShotConsumesAmmoAndAppliesHeadshotMultiplier() {
        let weapon = WeaponInstance(definition: StarterWeapons.pistol)
        let shot = weapon.fire(ads: false, headshot: true)
        XCTAssertEqual(weapon.state.magazine, 11)
        XCTAssertEqual(shot?.damage, 64)
    }

    func testFireCadenceBlocksImmediateSecondShot() {
        let weapon = WeaponInstance(definition: StarterWeapons.rifle)
        XCTAssertNotNil(weapon.fire(ads: false))
        XCTAssertNil(weapon.fire(ads: false))
        weapon.update(deltaTime: 1)
        XCTAssertNotNil(weapon.fire(ads: false))
    }

    func testReloadMovesOnlyRequiredReserveAmmo() {
        let weapon = WeaponInstance(definition: StarterWeapons.pistol)
        _ = weapon.fire(ads: false)
        weapon.update(deltaTime: 1)
        weapon.beginReload()
        weapon.update(deltaTime: 2)
        XCTAssertEqual(weapon.state.magazine, 12)
        XCTAssertEqual(weapon.state.reserve, 95)
    }

    func testSwitchCancelsReload() {
        let loadout = WeaponLoadout(definitions: [StarterWeapons.pistol, StarterWeapons.rifle])
        _ = loadout.active.fire(ads: false)
        loadout.active.beginReload()
        loadout.switchWeapon()
        XCTAssertEqual(loadout.active.definition.id, StarterWeapons.rifle.id)
    }
}
