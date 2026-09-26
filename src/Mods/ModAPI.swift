import Foundation

#if DEV_MOD_MENU
enum ModCategory: String, CaseIterable {
    case player, weapons, zombies, rounds, world, game, debug, settings
}

protocol ModAction {
    var id: String { get }
    var title: String { get }
    var category: ModCategory { get }
    func execute()
}

protocol ModToggle: ModAction {
    var isEnabled: Bool { get }
    func setEnabled(_ enabled: Bool)
}

final class ModRegistry {
    private(set) var actions: [String: any ModAction] = [:]

    func register(_ action: any ModAction) {
        precondition(actions[action.id] == nil, "Duplicate mod action id: \(action.id)")
        actions[action.id] = action
    }
}
#endif
