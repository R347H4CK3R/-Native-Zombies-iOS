import Foundation

enum WeaponCatalog {
    static func makeRegistry() -> Registry<WeaponDefinition> {
        var registry = Registry<WeaponDefinition>()
        try? registry.register(StarterWeapons.pistol)
        try? registry.register(StarterWeapons.rifle)
        try? registry.register(StarterWeapons.shotgun)
        return registry
    }
}
