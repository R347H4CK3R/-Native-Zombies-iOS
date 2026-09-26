import Foundation

protocol RegistryItem: Codable, Identifiable where ID == String {
    var id: String { get }
    var displayName: String { get }
}

struct Registry<Item: RegistryItem> {
    private(set) var items: [String: Item] = [:]

    mutating func register(_ item: Item) throws {
        guard items[item.id] == nil else {
            throw RegistryError.duplicateID(item.id)
        }
        items[item.id] = item
    }

    func item(id: String) -> Item? { items[id] }
    var all: [Item] { items.values.sorted { $0.displayName < $1.displayName } }
}

enum RegistryError: Error {
    case duplicateID(String)
}
