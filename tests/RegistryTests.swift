import XCTest

final class RegistryTests: XCTestCase {
    struct TestItem: RegistryItem {
        let id: String
        let displayName: String
    }

    func testRegistryRejectsDuplicateIDs() throws {
        var registry = Registry<TestItem>()
        try registry.register(TestItem(id: "test", displayName: "Test"))
        XCTAssertThrowsError(try registry.register(TestItem(id: "test", displayName: "Duplicate")))
    }
}
