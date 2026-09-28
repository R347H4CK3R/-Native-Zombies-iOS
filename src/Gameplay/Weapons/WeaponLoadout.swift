import Foundation

final class WeaponLoadout {
    private(set) var slots: [WeaponInstance]
    private(set) var activeIndex = 0
    var active: WeaponInstance { slots[activeIndex] }

    init(definitions: [WeaponDefinition]) {
        precondition(!definitions.isEmpty)
        slots = definitions.map(WeaponInstance.init)
    }

    func selectWeapon(id:String) -> Bool { guard let i=slots.firstIndex(where:{$0.definition.id==id}) else{return false}; active.cancelReload(); activeIndex=i; return true }

    func switchWeapon() {
        guard slots.count > 1 else { return }
        active.cancelReload()
        activeIndex = (activeIndex + 1) % slots.count
    }

    func update(deltaTime: Float) {
        for weapon in slots { weapon.update(deltaTime: deltaTime) }
    }
}
